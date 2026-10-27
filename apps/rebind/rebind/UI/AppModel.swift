import AppKit
import ApplicationServices
import Observation
import Synchronization
import Dispatch
import Carbon

@MainActor @Observable final class AppModel: NSObject {
    private(set) var configuration = Configuration()
    private(set) var status: EngineStatus = .paused
    private(set) var permissions = InputPermissions()
    private(set) var storageLocked = false
    private(set) var configurationReplacementRevision: UInt64 = 0
    var error: LocalizedStringResource? {
        didSet { actionErrorDeadline = nil }
    }
    @ObservationIgnored private var actionErrorDeadline: ContinuousClock.Instant?
    var recording: RecordingRequest?
    /// The remembered Settings section and a pending route from menu/command actions.
    var settingsSection: SettingsSection = .general
    var requestedSettingsSection: SettingsSection?
    var lastRecording: RecordedInput?
    private(set) var diagnostics = DiagnosticSnapshot()
    private(set) var audioCapabilities = AudioOutputCapabilities()
    private(set) var workspaceActionInProgress = false
    private(set) var appleShortcutInProgress = false
    let loginItem: LoginItemModel
    /// Mouse makers' apps running now, and the connected mice with their hardware settings.
    let companionApps: CompanionAppMonitor
    let mouseHardware: MouseHardware
    let activeLanguage: AppLanguage
    @ObservationIgnored private let systemLanguages: [String]
    @ObservationIgnored private let languagePreferenceSaved: (AppLanguagePreference) -> Void

    @ObservationIgnored let mailbox = EngineMailbox()
    @ObservationIgnored private lazy var pointerApplication: PointerApplicationTracker = {
        let tracker = PointerApplicationTracker(mailbox: mailbox)
        mailbox.setScrollObserver { [tracker] in tracker.noteScroll() }
        return tracker
    }()
    @ObservationIgnored private let store: ConfigurationStore
    private(set) var trackpadStatus: TrackpadCaptureStatus = .idle
    @ObservationIgnored private var trackpadCapture: TrackpadCapture?
    @ObservationIgnored private var magicMouseCapture: MagicMouseCapture?
    private(set) var magicMouseStatus: TrackpadCaptureStatus = .idle
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
         companionApps: CompanionAppMonitor = CompanionAppMonitor(),
         mouseHardware: MouseHardware = MouseHardware(),
         preferredLanguages: [String] = AppLanguageDefaults.systemPreferredLanguages,
         languagePreferenceSaved: @escaping (AppLanguagePreference) -> Void = { _ in }) {
        self.loginItem = loginItem
        self.companionApps = companionApps
        self.mouseHardware = mouseHardware
        self.sessionAllowsInput = sessionAllowsInput
        self.readPermissions = readPermissions
        self.store = store
        systemLanguages = preferredLanguages
        self.languagePreferenceSaved = languagePreferenceSaved
        var loaded = Configuration()
        var loadFailed = false
        if loadConfiguration {
            do {
                loaded = try store.load()
                store.backUpLoadedFile()
            } catch { loadFailed = true }
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

    /// Name of the saved language choice, shown where a reopen is still pending.
    var savedLanguageName: String {
        configuration.languagePreference.language?.autonym
            ?? AppLocalization.string(.systemDefault, language: activeLanguage)
    }

    var configurationFileURL: URL { store.url }
    var configurationBackupDirectory: URL { store.backupDirectory }

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
        mouseHardware.refresh()
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
            // Saving a UI preference does not resolve an unrelated action or validation error.
            if error == .storageWriteFailed { error = nil }
        } catch { self.error = .storageWriteFailed }
    }

    func start() {
        guard timer == nil else { return }
        previousApplication.start()
        // Once a companion app quits, write the stored settings it may have replaced.
        companionApps.changed = { [weak self] in self?.mouseHardware.refresh() }
        companionApps.start()
        mouseHardware.connectedVendorsChanged = { [weak self] in self?.companionApps.setConnectedVendors($0) }
        mouseHardware.storedSettings = { [weak self] in self?.configuration.mouseHardware ?? [] }
        mouseHardware.storedLighting = { [weak self] in self?.configuration.keyboardLighting ?? [] }
        mouseHardware.canWrite = { [weak self] in self?.companionApps.controller(ofVendor: $0, gaming: $1) == nil }
        let mailbox = mailbox
        mouseHardware.gestureButtonChanged = { down in
            mailbox.handleOffTapButton(InputTrigger.gestureButton, down: down,
                                       modifiers: ModifierSet(flags: CGEventSource.flagsState(.combinedSessionState)),
                                       secureInput: IsSecureEventInputEnabled())
        }
        mouseHardware.smoothScrollingChanged = { mailbox.setSmoothScrolling(bySender: $0) }
        mouseHardware.start()
        configureEngine(configuration)
        refreshSessionProtection()
        refreshWindowDisplays()
        refreshForegroundApplication()
        EventTapWorker.start(mailbox: mailbox)
        ActionWorker.start(mailbox: mailbox)
        trackpadCapture = TrackpadCapture(mailbox: mailbox)
        trackpadCapture?.start()
        magicMouseCapture = MagicMouseCapture(mailbox: mailbox)
        magicMouseCapture?.start()
        refresh()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        timer?.tolerance = 0.05
        updatePointerTracking(configuration)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshWindowDisplays), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelRecording), name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPermissions), name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeDiagnostics), name: NSWindow.willCloseNotification, object: nil)
        for name in [ScreenLockSession.lockedNotification, ScreenLockSession.unlockedNotification] {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleScreenLockNotification(_:)),
                                                               name: name, object: nil, suspensionBehavior: .deliverImmediately)
        }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshForegroundApplication),
                                                          name: NSWorkspace.didActivateApplicationNotification, object: nil)
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification,
                     NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleWorkspaceNotification(_:)),
                                                            name: name, object: nil)
        }
    }

    func stop() {
        cancelRecording()
        mailbox.stop()
        // Serialize with the action worker before any device shutdown can wait for I/O.
        while mailbox.deliverNextHeldKey(at: DispatchTime.now().uptimeNanoseconds, send: ShortcutSender.postHeldKey) { }
        previousApplication.stop()
        companionApps.stop()
        mouseHardware.stop()
        trackpadCapture?.stop()
        trackpadCapture = nil
        magicMouseCapture?.stop()
        magicMouseCapture = nil
        pointerApplication.setRunning(false)
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
            // Observation notifies on every assignment; unchanged values must not redraw the UI.
            let current = readPermissions()
            if permissions != current { permissions = current }
            refreshWindowDisplays()
            lastPermissionCheck = Date()
        }
        // Copy the engine's state and clear its one-shot results in one short lock.
        let update = mailbox.state.withLock { state in
            let result = (status: state.status, trackpadStatus: state.trackpadStatus, magicMouseStatus: state.magicMouseStatus,
                          audioCapabilities: state.audioCapabilities,
                          workspaceActionInProgress: state.workspaceRequest != nil && !state.appleShortcutInProgress,
                          appleShortcutInProgress: state.appleShortcutInProgress,
                          recorded: state.recorded, paused: state.emergencyPause, failed: state.actionFailed,
                          profileStep: state.profileStep)
            state.profileStep = 0
            state.actionFailed = nil
            state.recorded = nil
            state.emergencyPause = false
            return result
        }
        if status != update.status { status = update.status }
        magicMouseCapture?.refreshControl()
        if trackpadStatus != update.trackpadStatus { trackpadStatus = update.trackpadStatus }
        if magicMouseStatus != update.magicMouseStatus { magicMouseStatus = update.magicMouseStatus }
        if audioCapabilities != update.audioCapabilities { audioCapabilities = update.audioCapabilities }
        if workspaceActionInProgress != update.workspaceActionInProgress { workspaceActionInProgress = update.workspaceActionInProgress }
        if appleShortcutInProgress != update.appleShortcutInProgress { appleShortcutInProgress = update.appleShortcutInProgress }
        refreshDiagnostics()
        if let captured = update.recorded, captured.request == recording {
            lastRecording = captured
            recording = nil
        }
        // Consume the worker's cancellation result before clearing any remaining recorder.
        if !permissions.allowsRemapping { cancelRecording() }
        if update.paused {
            recording = nil
            var paused = configuration
            paused.isEnabled = false
            configuration.isEnabled = false
            trySave(paused)
        }
        refreshActionError(update.failed?.failureMessage)
        if update.profileStep != 0 { stepProfile(by: update.profileStep) }
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
        case NSWorkspace.didWakeNotification:
            workspaceSleeping = false
            mouseHardware.refresh()
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

    /// Action failures describe one attempt, not a lasting engine fault. Reuse the UI refresh
    /// timer and a monotonic deadline; saving/dismissing another error cancels this expiry.
    func refreshActionError(_ message: LocalizedStringResource? = nil, now: ContinuousClock.Instant = .now) {
        if let deadline = actionErrorDeadline, now >= deadline { error = nil }
        guard let message, error == nil || actionErrorDeadline != nil else { return }
        error = message
        actionErrorDeadline = now.advanced(by: .seconds(30))
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

    /// Drives the Menu Bar icon: the paused glyph whenever rules cannot run.
    var rulesAreRunning: Bool { generalRuntime == .active }

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

    /// Adds an app in which Rebind stays out of the way. False when it is already listed or rejected.
    @discardableResult func excludeApplication(_ target: ApplicationTarget) -> Bool {
        var updated = configuration
        updated.excludedApplications.append(ExcludedApplication(target: target))
        do { try updated.validate() } catch { self.error = .excludedAppRejected; return false }
        return trySave(updated)
    }

    /// What keeps working in an excluded app: bindings and/or smooth scrolling.
    func setExclusion(_ bundleIdentifier: String, allowsBindings: Bool? = nil, allowsSmoothScrolling: Bool? = nil) {
        var updated = configuration
        guard let index = updated.excludedApplications.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) else { return }
        if let allowsBindings { updated.excludedApplications[index].allowsBindings = allowsBindings }
        if let allowsSmoothScrolling { updated.excludedApplications[index].allowsSmoothScrolling = allowsSmoothScrolling }
        guard updated != configuration else { return }
        trySave(updated)
    }

    /// Companion apps whose Mouse page warning is still shown: a newly seen app shows it again.
    var visibleMouseCompanionApps: [CompanionApp] {
        mouseCompanionApps.filter { !configuration.dismissedCompanionApps.contains($0.name) }
    }

    func dismissCompanionWarning(for apps: [CompanionApp]) {
        var updated = configuration
        for app in apps where !updated.dismissedCompanionApps.contains(app.name) { updated.dismissedCompanionApps.append(app.name) }
        guard updated != configuration else { return }
        trySave(updated)
    }

    func includeApplication(_ bundleIdentifier: String) {
        var updated = configuration
        updated.excludedApplications.removeAll { $0.bundleIdentifier == bundleIdentifier }
        trySave(updated)
    }

    func setMouseWheel(reverses: Bool? = nil, reversesHorizontally: Bool? = nil, speed: MouseWheelSpeed? = nil) {
        var updated = configuration
        if let reverses { updated.reversesMouseWheel = reverses }
        if let reversesHorizontally { updated.reversesHorizontalScrolling = reversesHorizontally }
        if let speed { updated.mouseWheelSpeed = speed }
        guard updated != configuration else { return }
        trySave(updated)
    }

    /// Running vendor apps that may take buttons or settings of a connected mouse.
    var mouseCompanionApps: [CompanionApp] {
        companionApps.running.filter { app in mouseHardware.mice.contains { $0.vendorID == app.vendorID } }
    }

    /// A display-only save: never reconfigure the engine or write mouse hardware settings.
    func renameDevice(key: String, original: String, name: String) -> Bool {
        guard !storageLocked else { return false }
        do {
            var updated = configuration
            try updated.renameDevice(key: key, original: original, name: name)
            if updated != configuration {
                try persistConfiguration(updated)
                configuration = updated
            }
            error = nil
            return true
        } catch { self.error = .storageWriteFailed; return false }
    }

    /// Saves wheel and pointer settings for one mouse model and writes them to it.
    func setMouseHardware(_ settings: MouseHardwareSettings) {
        var updated = configuration
        if let index = updated.mouseHardware.firstIndex(where: { $0.deviceKey == settings.deviceKey }) {
            updated.mouseHardware[index] = settings
        } else {
            updated.mouseHardware.append(settings)
        }
        guard updated != configuration else { return }
        do { try updated.validate() } catch { self.error = .storageWriteFailed; return }
        let previous = configuration.mouseHardware.first { $0.deviceKey == settings.deviceKey }
        guard trySave(updated) else { return }
        mouseHardware.publishSmoothScrolling()
        // Turning the gesture button on or off also changes which reports Rebind listens to.
        if previous?.usesGestureButton != settings.usesGestureButton { mouseHardware.refresh() } else { mouseHardware.apply(settings) }
    }

    /// Hardware confirmation precedes persistence; failed writes leave the last saved choice intact.
    func setKeyboardLighting(_ settings: KeyboardLightingSettings) {
        guard !storageLocked, settings.isValid else { return }
        mouseHardware.applyLighting(settings) { [weak self] success in
            guard let self, success, !self.storageLocked else { return }
            var updated = self.configuration
            if let index = updated.keyboardLighting.firstIndex(where: { $0.deviceKey == settings.deviceKey }) {
                updated.keyboardLighting[index] = settings
            } else { updated.keyboardLighting.append(settings) }
            guard updated != self.configuration else { return }
            do {
                try updated.validate()
                try self.persistConfiguration(updated)
                self.configuration = updated
                self.error = nil
            } catch { self.error = .storageWriteFailed }
        }
    }

    /// Plain-text facts for a bug report. Counts and states only: no triggers, shortcuts,
    /// typed text, user-chosen app names or paths ever appear in it. Mouse models and
    /// running companion apps (a fixed list of vendor apps) help explain device issues.
    func supportReport(information: AboutInformation = AboutInformation(),
                       system: String = ProcessInfo.processInfo.operatingSystemVersionString) -> String {
        let scopes: [(String, DeviceScope)] = [("keyboard", .allKeyboards), ("mouse", .allMice),
                                               ("trackpad", .builtInTrackpad), ("magic trackpad", .magicTrackpad), ("magic mouse", .magicMouse)]
        let rules = configuration.bindings
        var lines = [
            "Rebind \(information.version ?? "?") (\(information.build ?? "?"))",
            "macOS: \(system)",
            "Language: \(activeLanguage.rawValue) (preference: \(configuration.languagePreference.rawValue))",
            "Bindings on: \(configuration.isEnabled); engine: \(status); trackpad: \(trackpadStatus); magic mouse: \(magicMouseStatus)",
            "Accessibility: \(permissions.accessibility); event sending: \(permissions.posting); input monitoring: \(permissions.listening)",
            "Configuration: schema \(configuration.schemaVersion), locked: \(storageLocked)",
            "Profiles: \(configuration.profiles.count); bindings in all profiles: \(configuration.profiles.reduce(0) { $0 + $1.bindings.count })",
            "Excluded apps: \(configuration.excludedApplications.count); gesture distance: \(configuration.pointerGestureDistance.rawValue); wheel: reversed \(configuration.reversesMouseWheel), horizontal reversed \(configuration.reversesHorizontalScrolling), speed \(configuration.mouseWheelSpeed.rawValue); smooth scrolling on \(configuration.mouseHardware.filter { $0.smoothScrolling == true }.count) mice; app-specific bindings: \(configuration.bindings.filter { $0.application != nil }.count)"
        ]
        for (name, scope) in scopes {
            let scoped = rules.filter { $0.scope == scope }
            lines.append("Selected profile, \(name): \(scoped.count) bindings, \(scoped.filter(\.isEnabled).count) enabled")
        }
        lines.append("Companion apps running: " + (companionApps.running.isEmpty ? "none"
            : companionApps.running.map(\.name).joined(separator: ", ")))
        lines.append("Mice: " + (mouseHardware.mice.isEmpty ? "none" : mouseHardware.mice.map {
            "\($0.name) (\(String(format: "%04x", $0.vendorID)), \($0.transport), \($0.hardware == nil ? "no extra settings" : "HID++")"
        }.joined(separator: "; ")) + "; stored mouse settings: \(configuration.mouseHardware.count)")
        let kinds = Dictionary(grouping: rules, by: { ActionKind(action: $0.action).rawValue }).mapValues(\.count)
        lines.append("Actions: " + kinds.sorted { $0.key < $1.key }.map { "\($0.key) ×\($0.value)" }.joined(separator: ", "))
        return lines.joined(separator: "\n")
    }

    func setPointerGestureDistance(_ distance: PointerGestureDistance) {
        guard distance != configuration.pointerGestureDistance else { return }
        var updated = configuration
        updated.pointerGestureDistance = distance
        trySave(updated)
    }

    @objc private func refreshForegroundApplication() {
        mailbox.setForegroundApplication(NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
    }

    /// Copies a rule into another profile. If its trigger is already used there, the copy arrives switched off.
    @discardableResult func copyBinding(_ binding: Binding, toProfile id: UUID) -> Bool {
        guard let index = configuration.profiles.firstIndex(where: { $0.id == id }) else { return false }
        var updated = configuration
        updated.profiles[index].bindings.append(binding.duplicated())
        do { try updated.validate() } catch ConfigurationError.conflict {
            updated.profiles[index].bindings[updated.profiles[index].bindings.count - 1].isEnabled = false
        } catch { showConfigurationError(error); return false }
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

    /// Moves the selection through the profile list, wrapping at either end.
    private func stepProfile(by step: Int) {
        let profiles = configuration.profiles
        guard profiles.count > 1, !storageLocked,
              let index = profiles.firstIndex(where: { $0.id == configuration.selectedProfileID }) else { return }
        let count = profiles.count
        selectProfile(profiles[((index + step) % count + count) % count].id)
    }

    @discardableResult func createProfile(name: String, copying sourceID: UUID? = nil) -> Bool {
        guard profileNameIsAvailable(name) else { error = .profileInvalid; return false }
        return updateProfiles { try $0.createProfile(name: name, copying: sourceID) }
    }

    @discardableResult func renameProfile(_ id: UUID, name: String) -> Bool {
        guard profileNameIsAvailable(name, excluding: id) else { error = .profileInvalid; return false }
        return updateProfiles { try $0.renameProfile(id, name: name) }
    }

    /// A file holding only this profile, or nil when it no longer exists.
    func profileBackup(_ id: UUID) -> ConfigurationBackup? {
        guard !storageLocked else { return nil }
        return try? ConfigurationBackup(configuration: configuration.exportingProfile(id))
    }

    /// Adds every profile of a file next to the existing ones, with fresh identifiers and unused
    /// names. Nothing is replaced and the selection stays. Returns how many were added.
    func importProfiles(from backup: ConfigurationBackup, expectedRevision: UInt64? = nil) -> Int? {
        guard expectedRevision == nil || expectedRevision == configurationReplacementRevision else { return nil }
        var updated = configuration
        for source in backup.configuration.profiles {
            let base = String(source.title.prefix(76))
            var name = base
            var suffix = 2
            while updated.profiles.contains(where: { Self.sameName($0.title, name) }) {
                name = "\(base) \(suffix)"
                suffix += 1
            }
            updated.profiles.append(RuleProfile(name: name, bindings: source.bindings.map { $0.duplicated() }))
        }
        do { try updated.validate() } catch { return nil }
        return trySave(updated) ? backup.configuration.profiles.count : nil
    }

    private static func sameName(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: [.caseInsensitive, .diacriticInsensitive],
                    locale: Locale(identifier: "en_US_POSIX")) == .orderedSame
    }

    private func profileNameIsAvailable(_ name: String, excluding id: UUID? = nil) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Include the localized built-in label, whose stored name is nil.
        return !configuration.profiles.contains { $0.id != id && Self.sameName($0.title, trimmed) }
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
        magicMouseCapture?.configurationChanged()
        // Read AppKit's system preference on MainActor, never in the event callback.
        let interval = NSEvent.doubleClickInterval
        let nanoseconds: UInt64 = interval.isFinite && interval > 0 && interval <= 60
            ? UInt64(interval * 1_000_000_000) : 500_000_000
        mailbox.configure(configuration, doublePressIntervalNanoseconds: nanoseconds,
                          keyRepeat: Self.keyRepeat(delay: NSEvent.keyRepeatDelay, interval: NSEvent.keyRepeatInterval))
        if timer != nil { updatePointerTracking(configuration) }
    }

    /// Only a per-app smooth scrolling exclusion needs to know which app is under the pointer.
    private func updatePointerTracking(_ configuration: Configuration) {
        pointerApplication.setRunning(configuration.mouseHardware.contains { $0.smoothScrolling == true }
            && configuration.excludedApplications.contains { !$0.allowsSmoothScrolling })
    }

    /// The system key-repeat preference, bounded so a broken value cannot storm or stall.
    nonisolated static func keyRepeat(delay: TimeInterval, interval: TimeInterval) -> KeyRepeatTiming {
        func nanoseconds(_ seconds: TimeInterval, in range: ClosedRange<TimeInterval>, default value: TimeInterval) -> UInt64 {
            UInt64((seconds.isFinite ? min(max(seconds, range.lowerBound), range.upperBound) : value) * 1_000_000_000)
        }
        return KeyRepeatTiming(delayNanoseconds: nanoseconds(delay, in: 0.2...2, default: 0.5),
                               intervalNanoseconds: nanoseconds(interval, in: 0.03...2, default: 0.08))
    }

    func requestAccessibility() {
        refreshPermissions()
        // Open the pane directly; the asynchronous AX prompt would also show
        // an alert offering to open the same settings.
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

    /// First-run guidance is shown once, until it is finished or deferred.
    var needsFirstRunSetup: Bool {
        !configuration.hasCompletedSetup && !storageLocked
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
