import ApplicationServices
import Foundation
import Synchronization
import Testing
@testable import rebind

struct WindowActionTests {
    @Test(arguments: WindowAction.allCases)
    func nativeOperationsUseOnlyTheirSpecificTarget(_ action: WindowAction) {
        let client = FakeWindowAccessibility()
        #expect(WindowActionExecutor.perform(action, client: client, ownPID: 99, canPerform: { true }) == .performed)
        let expected: String
        switch action {
        case .close: expected = "press close"
        case .minimize: expected = "set AXMinimized window"
        case .toggleFullScreen: expected = "press fullscreen"
        case .hideApplication: expected = "set AXHidden app"
        }
        #expect(client.mutations == [expected])
    }

    @Test(arguments: 0...8)
    func missingPermissionSelfAppAndUnsupportedTargetsNeverMutate(_ scenario: Int) {
        let client = FakeWindowAccessibility()
        switch scenario {
        case 0: client.trusted = false
        case 1: client.application = nil
        case 2: client.pid = 99
        case 3: client.pid = 0
        case 4: client.window = nil
        case 5: client.windowRole = false
        case 6: client.button = nil
        case 7: client.enabled = false
        default: client.childPID = 2
        }
        #expect(WindowActionExecutor.perform(.close, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.mutations.isEmpty)
    }

    @Test(arguments: [WindowAction.minimize, .hideApplication])
    func readOnlyPropertiesAreNeverWritten(_ action: WindowAction) {
        let client = FakeWindowAccessibility()
        client.settable = false
        #expect(WindowActionExecutor.perform(action, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.mutations.isEmpty)
    }

    @Test(arguments: [true, false])
    func focusChangesDuringReadsNeverRetargetTheAction(_ appChanged: Bool) {
        let client = FakeWindowAccessibility()
        client.beforeFinalFocus = {
            if appChanged { client.application = "otherApp" }
            else { client.window = "otherWindow" }
        }
        #expect(WindowActionExecutor.perform(.close, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.mutations.isEmpty)
    }

    @Test(arguments: [true, false])
    func cancellationAndRevokedTrustAfterReadsPreventMutation(_ cancel: Bool) {
        let client = FakeWindowAccessibility()
        var checks = 0
        let result = WindowActionExecutor.perform(.close, client: client, ownPID: 99) {
            checks += 1
            if checks == 2 {
                if cancel { return false }
                client.trusted = false
            }
            return true
        }
        #expect(result == (cancel ? .cancelled : .unavailable))
        #expect(client.mutations.isEmpty)
    }

    @Test(arguments: WindowAction.allCases)
    func rejectedAXMutationIsReportedOnceWithoutFallback(_ action: WindowAction) {
        let client = FakeWindowAccessibility()
        client.success = false
        #expect(WindowActionExecutor.perform(action, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.mutations.count == 1)
    }

    @Test func hidingAnAppDoesNotRequireOrReadAWindow() {
        let client = FakeWindowAccessibility()
        client.window = nil
        #expect(WindowActionExecutor.perform(.hideApplication, client: client, ownPID: 99, canPerform: { true }) == .performed)
        #expect(client.windowReads == 0)
    }

    @Test(arguments: WindowAction.allCases, [InputTrigger.key(0), .mouseButton(99), .scroll(.left)])
    func catalogAndMatchingWorkWithoutAnAudioDevice(_ action: WindowAction, _ trigger: InputTrigger) {
        let configured = RebindAction.window(action)
        let kind = ActionKind(action: configured)
        #expect(kind.category == .windows && kind.windowAction == action && kind.systemAction == nil)
        #expect(kind.configuredAction(shortcut: nil) == configured)
        #expect(kind.isAvailable(with: AudioOutputCapabilities()))
        #expect(AudioOutputCapabilities().supports(configured))
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: [], action: configured)
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.handle(InputEvent(trigger: trigger, phase: trigger.isScroll ? .scroll : .down), secureInput: false))
        #expect(mailbox.nextAction()?.action == configured)
    }

    @Test(arguments: [WindowActionResult.performed, .cancelled, .unavailable])
    func serialWorkerNeverPostsWindowActionsAsKeysAndReportsOnlyFailures(_ result: WindowActionResult) {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .window(.close))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active }
        let calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performAudio: { _, _ in Issue.record("Window action reached audio backend"); return false },
            sendShortcut: { _ in Issue.record("Window action reached keyboard backend"); return false },
            performWindow: { action, canPerform in
                #expect(action == .close && canPerform())
                calls.withLock { $0 += 1 }
                return result
            }, secureInput: { false }, postingAllowed: { true })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 1)
        #expect(mailbox.state.withLock { $0.actionFailed } == (result == .unavailable ? .window(.close) : nil))
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func workerCancellationDuringWindowReadsReachesFinalGate() {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true))
        mailbox.state.withLock { $0.status = .active; $0.pending = [.window(.minimize)] }
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performWindow: { _, canPerform in
                #expect(canPerform())
                mailbox.setEditing(true)
                #expect(canPerform() == false)
                return .cancelled
            }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.actionFailed == nil && $0.editing })
    }

    @Test func schemaSevenProfilesAndAudioMigrateWithoutRewritingTheirFile() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindWindowActions-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: folder.appending(path: "configuration.json"))
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .system(.volumeDown))
        var original = Configuration(isEnabled: true, bindings: [binding])
        try original.createProfile(name: "Second", copying: RuleProfile.defaultID)
        original.schemaVersion = 7
        let bytes = try JSONEncoder().encode(original)
        try bytes.write(to: store.url)
        var migrated = try store.load()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion)
        #expect(migrated.profiles == original.profiles && migrated.selectedProfileID == original.selectedProfileID && migrated.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        migrated.bindings[0].action = .window(.toggleFullScreen)
        try store.save(migrated)
        #expect(try store.load() == migrated)
    }

    @Test(arguments: 1...7)
    func windowActionsCannotMasqueradeAsOlderSchemas(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .window(.close))
        let data = try JSONEncoder().encode(Configuration(schemaVersion: version, bindings: [binding]))
        let decoded = try JSONDecoder().decode(Configuration.self, from: data)
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @MainActor @Test func windowFailureReachesLocalizedUIWithoutPausingOtherRules() {
        let model = AppModel(loadConfiguration: false)
        model.mailbox.state.withLock { $0.actionFailed = .window(.minimize) }
        model.refresh()
        #expect(model.error == .windowActionFailed)
        #expect(model.mailbox.state.withLock { $0.actionFailed == nil })
    }
}

nonisolated private final class FakeWindowAccessibility: WindowAccessibility {
    var trusted = true
    var application: String? = "app"
    var pid: pid_t = 1
    var childPID: pid_t = 1
    var window: String? = "window"
    var windowRole = true
    var button: String? = "close"
    var enabled = true
    var settable = true
    var success = true
    var windowReads = 0
    var mutations: [String] = []
    var beforeFinalFocus: (() -> Void)?

    func processID(of element: String) -> pid_t? { element == "app" ? pid : childPID }
    func element(_ attribute: String, of element: String) -> String? {
        if attribute == kAXFocusedWindowAttribute { windowReads += 1; return window }
        if attribute == kAXFullScreenButtonAttribute { beforeFinalFocus?(); return button == nil ? nil : "fullscreen" }
        if attribute == kAXCloseButtonAttribute { beforeFinalFocus?(); return button }
        return nil
    }
    func isWindow(_ element: String) -> Bool { windowRole }
    func isSettable(_ attribute: String, of element: String) -> Bool { settable }
    func isEnabled(_ element: String) -> Bool { enabled }
    func setTrue(_ attribute: String, of element: String) -> Bool {
        mutations.append("set \(attribute) \(element)")
        return success
    }
    func press(_ element: String) -> Bool { mutations.append("press \(element)"); return success }
}
