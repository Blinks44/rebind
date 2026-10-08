import AppKit
// The SDK imports the immutable AX prompt-option constant as a mutable global.
// All AX permission UI calls below are confined to MainActor.
@preconcurrency import ApplicationServices
import Observation
import Synchronization
import Dispatch

@MainActor @Observable final class AppModel: NSObject {
    private(set) var configuration = Configuration()
    private(set) var status: EngineStatus = .paused
    private(set) var permissions = InputPermissions()
    private(set) var storageLocked = false
    var error: LocalizedStringResource?
    var recording: RecordingRequest?
    var lastRecording: RecordedInput?
    private(set) var diagnostics = DiagnosticSnapshot()
    private(set) var audioCapabilities = AudioOutputCapabilities()
    private(set) var workspaceActionInProgress = false

    @ObservationIgnored let mailbox = EngineMailbox()
    @ObservationIgnored private let store: ConfigurationStore
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var workspaceTask: Task<Void, Never>?
    @ObservationIgnored private var lastPermissionCheck = Date.distantPast
    @ObservationIgnored private var workspaceSleeping = false
    @ObservationIgnored private var workspaceSessionInactive = false

    init(store: ConfigurationStore = .applicationStore, loadConfiguration: Bool = true) {
        self.store = store
        super.init()
        guard loadConfiguration else { return }
        do { configuration = try store.load() }
        catch { storageLocked = true; self.error = .storageUnreadable }
    }

    func start() {
        guard timer == nil else { return }
        configureEngine(configuration)
        EventTapWorker.start(mailbox: mailbox)
        ActionWorker.start(mailbox: mailbox)
        refresh()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelRecording), name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeDiagnostics), name: NSWindow.willCloseNotification, object: nil)
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification,
                     NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleWorkspaceNotification(_:)),
                                                            name: name, object: nil)
        }
    }

    func stop() {
        cancelRecording()
        mailbox.stop()
        workspaceTask?.cancel()
        workspaceTask = nil
        workspaceActionInProgress = false
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc func refresh() {
        if Date().timeIntervalSince(lastPermissionCheck) >= 0.5 {
            permissions = .current()
            lastPermissionCheck = Date()
        }
        let update = mailbox.state.withLock { state in
            let result = (state.status, state.recorded, state.emergencyPause, state.audioCapabilities, state.actionFailed, state.workspaceRequest != nil)
            state.actionFailed = nil
            state.recorded = nil
            state.emergencyPause = false
            return result
        }
        status = update.0
        audioCapabilities = update.3
        workspaceActionInProgress = update.5
        refreshDiagnostics()
        if let captured = update.1, captured.request == recording {
            lastRecording = captured
            recording = nil
        }
        if update.2 {
            recording = nil
            var paused = configuration
            paused.isEnabled = false
            configuration.isEnabled = false
            trySave(paused)
        }
        if let failed = update.4 {
            switch failed {
            case .shortcut: error = .outputFailed
            case .system: error = .audioActionFailed
            case .window: error = .windowActionFailed
            case .workspace: error = .workspaceActionFailed
            }
        }
        if workspaceTask == nil, mailbox.hasWorkspaceRequest {
            let mailbox = mailbox
            // The timer bridges sync AppKit lifecycle to one async native call.
            // At most one task/slot exists; the event tap never creates tasks.
            workspaceTask = Task { [weak self] in
                defer { self?.workspaceTask = nil }
                await WorkspaceActionExecutor(mailbox: mailbox).service()
            }
        }
    }

    @objc func handleWorkspaceNotification(_ notification: Notification) {
        switch notification.name {
        case NSWorkspace.willSleepNotification: workspaceSleeping = true
        case NSWorkspace.didWakeNotification: workspaceSleeping = false
        case NSWorkspace.sessionDidResignActiveNotification: workspaceSessionInactive = true
        case NSWorkspace.sessionDidBecomeActiveNotification: workspaceSessionInactive = false
        default: return
        }
        // Waking the machine does not necessarily reactivate this user's session.
        let suspended = workspaceSleeping || workspaceSessionInactive
        if suspended { cancelRecording() }
        mailbox.suspend(suspended)
        lastPermissionCheck = .distantPast
    }

    func setEnabled(_ enabled: Bool) {
        var updated = configuration
        updated.isEnabled = enabled
        if !enabled { configureEngine(updated); configuration.isEnabled = false }
        trySave(updated)
    }

    func beginEditing() {
        mailbox.setEditing(true)
    }
    func endEditing() { cancelRecording(); mailbox.setEditing(false) }

    func beginRecording(_ target: RecordingTarget) {
        guard canRecord, NSApp.isActive else { return }
        let request = RecordingRequest(target: target)
        recording = request
        lastRecording = nil
        mailbox.record(request)
    }

    @objc func cancelRecording() {
        // Losing UI focus ends explicit recording, not background recognition.
        guard recording != nil else { return }
        recording = nil
        mailbox.record(nil)
    }
    var canRecord: Bool { permissions.allowsRemapping }

    var canStartDiagnostics: Bool {
        guard canRecord else { return false }
        if case .secureInput = status { return false }
        return mailbox.state.withLock { !$0.suspended && !$0.stopped }
    }

    func startDiagnostics() {
        guard canStartDiagnostics else { return }
        mailbox.startDiagnostics(at: DispatchTime.now().uptimeNanoseconds)
        refreshDiagnostics()
    }

    func stopDiagnostics() { mailbox.stopDiagnostics(); refreshDiagnostics() }
    func clearDiagnostics() { mailbox.clearDiagnostics(); refreshDiagnostics() }
    @objc func closeDiagnostics() { mailbox.stopDiagnostics(clear: true); refreshDiagnostics() }

    private func refreshDiagnostics() {
        if let snapshot = mailbox.diagnosticSnapshot(since: diagnostics.revision, at: DispatchTime.now().uptimeNanoseconds) {
            diagnostics = snapshot
        }
    }

    var permissionHint: LocalizedStringResource {
        switch permissions.requirement {
        case .eventPosting: .eventPostingRequired
        case .accessibility: .permissionsRequired
        case nil: .enginePaused
        }
    }

    var statusText: LocalizedStringResource {
        if case .permissionRequired = status {
            if permissions.requirement == .eventPosting { return .eventPostingStatus }
            return permissionHint
        }
        return status.text
    }

    func saveBinding(_ binding: Binding, profileID: UUID? = nil) -> Bool {
        guard profileID == nil || profileID == configuration.selectedProfileID else {
            error = .profileChanged
            return false
        }
        var updated = configuration
        if let index = updated.bindings.firstIndex(where: { $0.id == binding.id }) {
            updated.bindings[index] = binding
        } else { updated.bindings.append(binding) }
        return trySave(updated)
    }

    func delete(_ id: UUID) {
        var updated = configuration
        updated.bindings.removeAll { $0.id == id }
        trySave(updated)
    }

    func toggle(_ binding: Binding) {
        var updated = binding
        updated.isEnabled.toggle()
        _ = saveBinding(updated)
    }

    @discardableResult func selectProfile(_ id: UUID) -> Bool {
        guard id != configuration.selectedProfileID else { return true }
        return updateProfiles { try $0.selectProfile(id) }
    }

    @discardableResult func createProfile(name: String, copying sourceID: UUID? = nil) -> Bool {
        guard profileNameIsAvailable(name) else { error = .profileInvalid; return false }
        return updateProfiles { try $0.createProfile(name: name, copying: sourceID) }
    }

    @discardableResult func renameProfile(_ id: UUID, name: String) -> Bool {
        guard profileNameIsAvailable(name, excluding: id) else { error = .profileInvalid; return false }
        return updateProfiles { try $0.renameProfile(id, name: name) }
    }

    private func profileNameIsAvailable(_ name: String, excluding id: UUID? = nil) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Include the localized built-in label, whose stored name is nil.
        return !configuration.profiles.contains {
            $0.id != id && $0.title.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive],
                                           locale: Locale(identifier: "en_US_POSIX")) == .orderedSame
        }
    }

    @discardableResult func deleteProfile(_ id: UUID) -> Bool {
        updateProfiles { try $0.deleteProfile(id) }
    }

    private func updateProfiles(_ mutation: (inout Configuration) throws -> Void) -> Bool {
        var updated = configuration
        do { try mutation(&updated); return trySave(updated) }
        catch { showConfigurationError(error); return false }
    }

    private func showConfigurationError(_ error: any Error) {
        switch error {
        case ConfigurationError.conflict: self.error = .bindingConflict
        case ConfigurationError.profileInvalid: self.error = .profileInvalid
        case ConfigurationError.profileLimit: self.error = .profileLimit
        case ConfigurationError.lastProfile: self.error = .lastProfileRequired
        case ConfigurationError.invalid: self.error = .bindingInvalid
        default: self.error = .storageWriteFailed
        }
    }

    @discardableResult private func trySave(_ updated: Configuration) -> Bool {
        guard !storageLocked else { error = .storageUnreadable; return false }
        do {
            try store.save(updated)
            error = nil
            if configuration.selectedProfileID != updated.selectedProfileID {
                recording = nil
                lastRecording = nil
            }
            configuration = updated
            configureEngine(updated)
            return true
        } catch { showConfigurationError(error) }
        return false
    }

    private func configureEngine(_ configuration: Configuration) {
        // Read AppKit's system preference on MainActor, never in the event callback.
        let interval = NSEvent.doubleClickInterval
        let nanoseconds: UInt64 = interval.isFinite && interval > 0 && interval <= 60
            ? UInt64(interval * 1_000_000_000) : 500_000_000
        mailbox.configure(configuration, doublePressIntervalNanoseconds: nanoseconds)
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refreshPermissions()
        // macOS may not repeat a prompt after an earlier denial. Always provide
        // a useful route to the actual setting when access is still missing.
        if !permissions.accessibility { openPrivacyPane("Privacy_Accessibility") }
    }

    func requestEventPosting() {
        // AX trust and Quartz synthesis can disagree. Request the specific
        // capability only after an explicit user action, never from polling.
        guard AXIsProcessTrusted() else { refreshPermissions(); return }
        _ = CGRequestPostEventAccess()
        refreshPermissions()
        if !permissions.posting { openPrivacyPane("Privacy_Accessibility") }
    }
    func refreshPermissions() { lastPermissionCheck = .distantPast; refresh() }

    func showApplicationInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    func openPrivacyPane(_ pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }
}
