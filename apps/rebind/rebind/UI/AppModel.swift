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
    private(set) var configurationReplacementRevision: UInt64 = 0
    var error: LocalizedStringResource?
    var recording: RecordingRequest?
    var lastRecording: RecordedInput?
    private(set) var diagnostics = DiagnosticSnapshot()
    private(set) var audioCapabilities = AudioOutputCapabilities()
    private(set) var workspaceActionInProgress = false
    private(set) var appleShortcutInProgress = false
    let loginItem: LoginItemModel
    let activeLanguage: AppLanguage
    @ObservationIgnored private let systemLanguages: [String]
    @ObservationIgnored private let languagePreferenceSaved: (AppLanguagePreference) -> Void

    @ObservationIgnored let mailbox = EngineMailbox()
    @ObservationIgnored private let store: ConfigurationStore
    private(set) var trackpadStatus: TrackpadCaptureStatus = .idle
    @ObservationIgnored private var trackpadCapture: TrackpadCapture?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var workspaceTask: Task<Void, Never>?
    @ObservationIgnored private var lastPermissionCheck = Date.distantPast
    @ObservationIgnored private var workspaceSleeping = false
    @ObservationIgnored private var workspaceSessionInactive = false
    @ObservationIgnored private var workspaceScreenLocked = false
    @ObservationIgnored private let previousApplication = PreviousApplicationTracker()
    @ObservationIgnored private let sessionAllowsInput: () -> Bool
    @ObservationIgnored private let readPermissions: () -> InputPermissions

    init(store: ConfigurationStore = .applicationStore, loadConfiguration: Bool = true,
         sessionAllowsInput: @escaping () -> Bool = { ScreenLockSession.allowsInput() },
         readPermissions: @escaping () -> InputPermissions = { .current() },
         loginItem: LoginItemModel = LoginItemModel(),
         preferredLanguages: [String] = AppLanguageDefaults.systemPreferredLanguages,
         languagePreferenceSaved: @escaping (AppLanguagePreference) -> Void = { _ in }) {
        self.loginItem = loginItem
        self.sessionAllowsInput = sessionAllowsInput
        self.readPermissions = readPermissions
        self.store = store
        systemLanguages = preferredLanguages
        self.languagePreferenceSaved = languagePreferenceSaved
        var loaded = Configuration()
        var loadFailed = false
        if loadConfiguration {
            do { loaded = try store.load() }
            catch { loadFailed = true }
        }
        activeLanguage = loaded.languagePreference.resolved(preferredLanguages: preferredLanguages)
        super.init()
        permissions = readPermissions()
        configuration = loaded
        if loadFailed { storageLocked = true; self.error = .storageUnreadable }
    }

    var requiresLanguageReopen: Bool {
        configuration.languagePreference.resolved(preferredLanguages: systemLanguages) != activeLanguage
    }

    var configurationFileURL: URL { store.url }

    /// A confirmed whole-document transaction. Persist before changing any runtime state.
    func replaceConfiguration(with replacement: Configuration, expected: Configuration,
                              revision: UInt64) throws {
        guard !storageLocked else { throw ConfigurationReplacementError.protectedOriginal }
        guard configuration == expected, configurationReplacementRevision == revision else {
            throw ConfigurationReplacementError.staleReview
        }
        // A file changed outside this process must be reviewed again, never overwritten.
        guard try store.load() == expected else { throw ConfigurationReplacementError.staleReview }
        var updated = replacement
        updated.isEnabled = false
        // Setup acknowledgement is local lifecycle state, not a backup preference.
        updated.hasCompletedSetup = configuration.hasCompletedSetup
        try persistConfiguration(updated)
        let languageChanged = updated.languagePreference != configuration.languagePreference
        recording = nil
        lastRecording = nil
        mailbox.record(nil)
        closeDiagnostics()
        workspaceTask?.cancel()
        configuration = updated
        configureEngine(updated)
        status = .paused
        error = nil
        configurationReplacementRevision &+= 1
        if languageChanged { languagePreferenceSaved(updated.languagePreference) }
    }

    /// A UI-only transaction: do not reconfigure/cancel/restart the input engine.
    func saveLanguagePreference(_ preference: AppLanguagePreference) throws {
        guard !storageLocked else { throw ConfigurationError.incompatible }
        guard preference != configuration.languagePreference else { return }
        var updated = configuration
        updated.languagePreference = preference
        try persistConfiguration(updated)
        configuration = updated
        languagePreferenceSaved(preference)
    }

    /// Dock, Menu Bar and launch-window preferences: a UI-only save, like the language.
    func setPresencePreference(_ keyPath: WritableKeyPath<Configuration, Bool>, to value: Bool) {
        guard !storageLocked, configuration[keyPath: keyPath] != value else { return }
        var updated = configuration
        updated[keyPath: keyPath] = value
        do {
            try persistConfiguration(updated)
            configuration = updated
            error = nil
        } catch { self.error = .storageWriteFailed }
    }

    func start() {
        guard timer == nil else { return }
        previousApplication.start()
        configureEngine(configuration)
        refreshSessionProtection()
        refreshWindowDisplays()
        EventTapWorker.start(mailbox: mailbox)
        ActionWorker.start(mailbox: mailbox)
        trackpadCapture = TrackpadCapture(mailbox: mailbox)
        trackpadCapture?.start()
        refresh()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshWindowDisplays), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelRecording), name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPermissions), name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeDiagnostics), name: NSWindow.willCloseNotification, object: nil)
        for name in [ScreenLockSession.lockedNotification, ScreenLockSession.unlockedNotification] {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleScreenLockNotification(_:)),
                                                               name: name, object: nil, suspensionBehavior: .deliverImmediately)
        }
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification,
                     NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleWorkspaceNotification(_:)),
                                                            name: name, object: nil)
        }
    }

    func stop() {
        previousApplication.stop()
        cancelRecording()
        mailbox.stop()
        trackpadCapture?.stop()
        trackpadCapture = nil
        workspaceTask?.cancel()
        workspaceTask = nil
        workspaceActionInProgress = false
        appleShortcutInProgress = false
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func refreshWindowDisplays() { mailbox.updateWindowDisplays(.current()) }

    @objc func refresh() {
        if Date().timeIntervalSince(lastPermissionCheck) >= 0.5 {
            refreshSessionProtection()
            permissions = readPermissions()
            refreshWindowDisplays()
            lastPermissionCheck = Date()
        }
        let update = mailbox.state.withLock { state in
            let result = (state.status, state.recorded, state.emergencyPause, state.audioCapabilities, state.actionFailed, state.workspaceRequest != nil, state.appleShortcutInProgress)
            state.actionFailed = nil
            state.recorded = nil
            state.emergencyPause = false
            return result
        }
        trackpadStatus = mailbox.state.withLock { $0.trackpadStatus }
        status = update.0
        audioCapabilities = update.3
        workspaceActionInProgress = update.5
        appleShortcutInProgress = update.6
        refreshDiagnostics()
        if let captured = update.1, captured.request == recording {
            lastRecording = captured
            recording = nil
        }
        // Consume the worker's cancellation result before clearing any remaining recorder.
        if !permissions.allowsRemapping { cancelRecording() }
        if update.2 {
            recording = nil
            var paused = configuration
            paused.isEnabled = false
            configuration.isEnabled = false
            trySave(paused)
        }
        if let failed = update.4 {
            switch failed {
            case .shortcut, .desktop: error = .outputFailed
            case .mouse: error = .mouseActionFailed
            case .media: error = .mediaActionFailed
            case .dock(let action): error = action.isSpaceNavigation ? .spaceActionFailed : .dockActionFailed
            case .lockScreen: error = .lockScreenFailed
            case .sleepSystem: error = .sleepSystemFailed
            case .system: error = .audioActionFailed
            case .windowCycle: error = .windowCycleFailed
            case .windowLayout: error = .windowLayoutFailed
            case .window: error = .windowActionFailed
            case .workspace(.previousApplication): error = .previousApplicationFailed
            case .workspace(.quitApplication): error = .quitApplicationFailed
            case .workspace(.openSystemSettings): error = .openSystemSettingsFailed
            case .workspace: error = .workspaceActionFailed
            case .appleShortcut: error = .appleShortcutFailed
            }
        }
        if workspaceTask == nil, mailbox.hasWorkspaceRequest {
            let mailbox = mailbox
            let previousApplication = previousApplication
            // The timer bridges sync AppKit lifecycle to one async native call.
            // At most one task/slot exists; the event tap never creates tasks.
            workspaceTask = Task { [weak self] in
                defer { self?.workspaceTask = nil }
                await WorkspaceActionExecutor(mailbox: mailbox, previousApplication: {
                    await previousApplication.perform(canPerform: $0)
                }).service()
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
        applySessionProtection()
        lastPermissionCheck = .distantPast
    }

    @objc func handleScreenLockNotification(_ notification: Notification) {
        guard notification.name == ScreenLockSession.lockedNotification
            || notification.name == ScreenLockSession.unlockedNotification else { return }
        // A lock hint suspends immediately. An unlock hint alone never grants input:
        // reread native session state, then retain sleep/inactive-session guards.
        workspaceScreenLocked = notification.name == ScreenLockSession.lockedNotification || !sessionAllowsInput()
        applySessionProtection()
        lastPermissionCheck = .distantPast
    }

    private func refreshSessionProtection() {
        workspaceScreenLocked = !sessionAllowsInput()
        applySessionProtection()
    }

    private func applySessionProtection() {
        // Wake, screen unlock and active-user changes are independent conditions.
        let suspended = workspaceSleeping || workspaceSessionInactive || workspaceScreenLocked
        if suspended { cancelRecording() }
        mailbox.suspend(suspended)
    }

    func setEnabled(_ enabled: Bool) {
        var updated = configuration
        updated.isEnabled = enabled
        if !enabled { configureEngine(updated); configuration.isEnabled = false }
        trySave(updated)
    }

    var generalRuntime: GeneralRuntimePresentation {
        GeneralRuntimePresentation(isEnabled: configuration.isEnabled, permissions: permissions,
            status: status, isSuspended: mailbox.state.withLock { $0.suspended }, storageLocked: storageLocked)
    }

    /// Retries failed capture without changing rules, persisted intent or pause.
    func retryRemapping() {
        guard configuration.isEnabled, !storageLocked, permissions.allowsRemapping else { return }
        mailbox.retryCapture()
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
    var canRecord: Bool {
        permissions.allowsRemapping && mailbox.state.withLock {
            !$0.suspended && !$0.stopped && $0.status != .secureInput
        }
    }

    var recordingUnavailableHint: LocalizedStringResource {
        if !permissions.allowsRemapping { return permissionHint }
        return mailbox.state.withLock {
            if $0.suspended { return .remappingSessionSuspended }
            if $0.stopped { return .engineInterrupted }
            return $0.status.text
        }
    }

    var canStartDiagnostics: Bool {
        guard !storageLocked, canRecord else { return false }
        switch status {
        case .permissionRequired, .secureInput, .tapFailed, .interrupted: return false
        case .paused, .active, .outputFailed: break
        }
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
        if !permissions.allowsRemapping { return .recoveryEngineStatus }
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
        case ConfigurationStoreError.protectedOriginal: self.error = .storageUnreadable
        case ConfigurationError.conflict: self.error = .bindingConflict
        case ConfigurationError.profileInvalid: self.error = .profileInvalid
        case ConfigurationError.profileLimit: self.error = .profileLimit
        case ConfigurationError.lastProfile: self.error = .lastProfileRequired
        case ConfigurationError.invalid: self.error = .bindingInvalid
        default: self.error = .storageWriteFailed
        }
    }

    /// Locks editing when an existing file becomes unreadable after launch.
    private func persistConfiguration(_ updated: Configuration) throws {
        do { try store.save(updated) }
        catch ConfigurationStoreError.protectedOriginal {
            storageLocked = true
            error = .storageUnreadable
            throw ConfigurationStoreError.protectedOriginal
        }
    }

    @discardableResult private func trySave(_ updated: Configuration) -> Bool {
        guard !storageLocked else { error = .storageUnreadable; return false }
        do {
            try persistConfiguration(updated)
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
    @objc func refreshPermissions() { lastPermissionCheck = .distantPast; refresh() }

    /// First-run guidance is needed only before acknowledgement and when access is missing.
    var needsPermissionSetup: Bool {
        !configuration.hasCompletedSetup && !permissions.allowsRemapping && !storageLocked
    }

    /// Atomically acknowledges setup without enabling, reconfiguring or replacing rules.
    @discardableResult func completePermissionSetup() -> Bool {
        guard !storageLocked else { error = .storageUnreadable; return false }
        var updated = configuration
        updated.hasCompletedSetup = true
        do {
            try persistConfiguration(updated)
            configuration = updated
            error = nil
            return true
        } catch { showConfigurationError(error); return false }
    }

    func showApplicationInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    func openPrivacyPane(_ pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }
}
