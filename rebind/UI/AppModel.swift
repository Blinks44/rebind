import AppKit
// The SDK imports the immutable AX prompt-option constant as a mutable global.
// All AX permission UI calls below are confined to MainActor.
@preconcurrency import ApplicationServices
import Observation
import Synchronization

@MainActor @Observable final class AppModel: NSObject {
    private(set) var configuration = Configuration()
    private(set) var status: EngineStatus = .paused
    private(set) var accessibilityGranted = false
    private(set) var inputMonitoringGranted = false
    private(set) var postingGranted = false
    private(set) var storageLocked = false
    var error: LocalizedStringResource?
    var recording: RecordingRequest?
    var lastRecording: RecordedInput?

    @ObservationIgnored let mailbox = EngineMailbox()
    @ObservationIgnored private let store: ConfigurationStore
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastPermissionCheck = Date.distantPast

    init(store: ConfigurationStore = .applicationStore, loadConfiguration: Bool = true) {
        self.store = store
        super.init()
        guard loadConfiguration else { return }
        do { configuration = try store.load() }
        catch { storageLocked = true; self.error = .storageUnreadable }
    }

    func start() {
        guard timer == nil else { return }
        mailbox.configure(configuration)
        EventTapWorker.start(mailbox: mailbox)
        refresh()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelRecording), name: NSApplication.didResignActiveNotification, object: nil)
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleep), name: name, object: nil)
        }
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wake), name: name, object: nil)
        }
    }

    func stop() {
        mailbox.state.withLock { $0.stopped = true; $0.pending.removeAll(keepingCapacity: true) }
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc func refresh() {
        if Date().timeIntervalSince(lastPermissionCheck) >= 0.5 {
            accessibilityGranted = AXIsProcessTrusted()
            inputMonitoringGranted = CGPreflightListenEventAccess()
            postingGranted = CGPreflightPostEventAccess()
            lastPermissionCheck = Date()
        }
        let update = mailbox.state.withLock { state in
            let result = (state.status, state.recorded, state.emergencyPause)
            state.recorded = nil
            state.emergencyPause = false
            return result
        }
        status = update.0
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
    }

    @objc func sleep() { cancelRecording(); mailbox.suspend(true) }
    @objc func wake() { mailbox.suspend(false); refresh() }

    func setEnabled(_ enabled: Bool) {
        var updated = configuration
        updated.isEnabled = enabled
        if !enabled { mailbox.configure(updated); configuration.isEnabled = false }
        trySave(updated)
    }

    func beginEditing() {
        mailbox.state.withLock { $0.editing = true; $0.pending.removeAll(keepingCapacity: true) }
    }
    func endEditing() { cancelRecording(); mailbox.state.withLock { $0.editing = false } }

    func beginRecording(_ target: RecordingTarget) {
        guard canRecord, NSApp.isActive else { return }
        let request = RecordingRequest(target: target)
        recording = request
        lastRecording = nil
        mailbox.record(request)
    }

    @objc func cancelRecording() { recording = nil; mailbox.record(nil) }
    var canRecord: Bool { accessibilityGranted && inputMonitoringGranted && postingGranted }

    func saveBinding(_ binding: Binding) -> Bool {
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

    @discardableResult private func trySave(_ updated: Configuration) -> Bool {
        guard !storageLocked else { error = .storageUnreadable; return false }
        do {
            try store.save(updated)
            error = nil
            configuration = updated
            mailbox.configure(updated)
            return true
        } catch ConfigurationError.conflict { self.error = .bindingConflict }
        catch ConfigurationError.invalid { self.error = .bindingInvalid }
        catch { self.error = .storageWriteFailed }
        return false
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refreshPermissions()
    }
    func requestInputMonitoring() { _ = CGRequestListenEventAccess(); refreshPermissions() }
    func refreshPermissions() { lastPermissionCheck = .distantPast; refresh() }

    func openPrivacyPane(_ pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }
}
