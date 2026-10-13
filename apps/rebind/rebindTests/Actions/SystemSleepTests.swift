import Foundation
import IOKit
import Synchronization
import Testing
@testable import rebind

struct SystemSleepTests {
    @Test(arguments: [kIOReturnSuccess, kIOReturnNotPrivileged, kIOReturnError])
    func nativeConnectionIsClosedForAcceptedAndRejectedRequests(_ status: IOReturn) {
        var calls: [String] = []
        let result = SystemSleepExecutor.perform(canPerform: { true }, sleepEnabled: { true }, openConnection: {
            calls.append("open"); return 42
        }, requestSleep: { port in
            #expect(port == 42); calls.append("request"); return status
        }, closeConnection: { port in #expect(port == 42); calls.append("close") })
        #expect(result == (status == kIOReturnSuccess ? .performed : .unavailable))
        #expect(calls == ["open", "request", "close"])
    }

    @Test(arguments: 0...2) func cancellationUnsupportedSleepAndInvalidPortNeverRequestSleep(_ scenario: Int) {
        var opened = 0, closed = 0
        let result = SystemSleepExecutor.perform(canPerform: { scenario != 0 }, sleepEnabled: { scenario != 1 },
            openConnection: { opened += 1; return 0 }, requestSleep: { _ in Issue.record("Unexpected sleep request"); return kIOReturnSuccess },
            closeConnection: { _ in closed += 1 })
        #expect(result == (scenario == 0 ? .cancelled : .unavailable))
        #expect(opened == (scenario == 2 ? 1 : 0) && closed == 0)
    }

    @Test func cancellationDuringConnectionOpenClosesWithoutRequest() {
        var allowed = true, closed: UInt32?
        #expect(SystemSleepExecutor.perform(canPerform: { allowed }, sleepEnabled: { true }, openConnection: {
            allowed = false; return 42
        }, requestSleep: { _ in Issue.record("Stale sleep requested"); return kIOReturnSuccess },
           closeConnection: { closed = $0 }) == .cancelled)
        #expect(closed == 42)
    }

    @Test @MainActor func catalogAndPayloadRequireNoRecordedShortcutOrAudioDevice() throws {
        let action = RebindAction.sleepSystem, kind = ActionKind(action: action)
        #expect(kind == .sleepSystem && kind.category == .system && kind.configuredAction(shortcut: nil) == action)
        #expect(action.isSupported && AudioOutputCapabilities().supports(action))
        #expect(action.label == String(localized: .sleepSystemAction))
        #expect(try JSONDecoder().decode(RebindAction.self, from: JSONEncoder().encode(action)) == action)
    }

    @Test(arguments: [InputTrigger.key(0), .mouseButton(99), .scroll(.up), .mouseGesture(button: 99, direction: .left)])
    func supportedSourceFamiliesMatchExactModifiersAndIgnoreSyntheticInput(_ trigger: InputTrigger) {
        var matcher = InputMatcher()
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: .sleepSystem)
        let rules = InputMatcher.compile([binding])
        let source = trigger.pressSource, phase: InputEvent.Phase = trigger.isScroll ? .scroll : .down
        #expect(!matcher.handle(InputEvent(trigger: source, phase: phase), rules: rules, enabled: true).suppress)
        var result = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase), rules: rules, enabled: true)
        if trigger.isPointerGesture {
            result = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: .drag,
                motion: .init(deltaX: -50, deltaY: 0)), rules: rules, enabled: true)
        }
        #expect(result.suppress && result.action == .sleepSystem)
        if !trigger.isScroll { #expect(matcher.handle(InputEvent(trigger: source, phase: .up), rules: rules, enabled: true).suppress) }
        #expect(!matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase, isSynthetic: true), rules: rules, enabled: true).suppress)
    }

    @Test(arguments: [WindowActionResult.performed, .cancelled, .unavailable])
    func workerRoutesPowerSeparatelyAndClearsOnlyAcceptedRequestQueue(_ result: WindowActionResult) {
        let mailbox = ready()
        let calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init() },
            sendShortcut: { _ in Issue.record("Power action posted keys"); return false }, requestSleep: { canPerform in
                #expect(canPerform()); calls.withLock { $0 += 1 }; return result
            }, secureInput: { false }, postingAllowed: { true })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        mailbox.state.withLock { $0.pending.append(.media(.playPause)) }
        let revision = mailbox.state.withLock { $0.actionRevision }
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 1)
        #expect(mailbox.state.withLock { $0.actionFailed } == (result == .unavailable ? .sleepSystem : nil))
        #expect(mailbox.state.withLock { $0.pending } == (result == .performed ? [] : [.media(.playPause)]))
        #expect(mailbox.state.withLock { $0.actionRevision } == revision + (result == .performed ? 1 : 0))
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.status == .active })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test(arguments: 0...7) func finalGateCancelsOnLifecycleOrProtectedChanges(_ change: Int) {
        let mailbox = ready(), secure = Mutex(false), allowed = Mutex(true)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init() }, requestSleep: { canPerform in
            #expect(canPerform())
            switch change {
            case 0: mailbox.configure(Configuration(isEnabled: false))
            case 1: mailbox.configure(Configuration(isEnabled: true))
            case 2: mailbox.setEditing(true)
            case 3: mailbox.record(.init(target: .mouseTrigger))
            case 4: mailbox.suspend(true)
            case 5: mailbox.stop()
            case 6: secure.withLock { $0 = true }
            default: allowed.withLock { $0 = false }
            }
            #expect(!canPerform()); return .cancelled
        }, secureInput: { secure.withLock { $0 } }, postingAllowed: { allowed.withLock { $0 } })
        mailbox.state.withLock { $0.pending = [.sleepSystem] }
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.actionFailed == nil })
    }

    @Test func acceptedOldRequestDoesNotClearNewProfileQueue() throws {
        let mailbox = ready()
        mailbox.state.withLock { $0.pending = [.sleepSystem] }
        let dispatch = try #require(mailbox.nextAction())
        mailbox.configure(Configuration(isEnabled: true))
        mailbox.state.withLock { $0.pending = [.media(.nextTrack)] }
        let revision = mailbox.state.withLock { $0.actionRevision }
        mailbox.systemTransitionRequested(dispatch)
        #expect(mailbox.state.withLock { $0.actionRevision == revision && $0.pending == [.media(.nextTrack)] })
    }

    @Test func acceptedSleepCancelsDelayedHoldAndKeepsItsReleaseOwnership() throws {
        let mailbox = ready()
        let hold = rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: [], action: .media(.playPause),
                                 activation: .hold, holdDurationMilliseconds: 1000)
        let sleep = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .sleepSystem)
        mailbox.configure(Configuration(isEnabled: true, bindings: [hold, sleep]))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(4), phase: .down), secureInput: false))
        let dispatch = try #require(mailbox.nextAction())
        #expect(mailbox.state.withLock { $0.matcher.holdKey != nil })
        mailbox.systemTransitionRequested(dispatch)
        #expect(mailbox.state.withLock { $0.matcher.holdKey == nil && $0.matcher.hasSuppressedInput })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(4), phase: .up), secureInput: false))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty && !$0.matcher.hasSuppressedInput })
    }

    @Test(arguments: 1...17) func olderSchemasRejectSleepInInactiveProfilesToo(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .sleepSystem)
        var old = Configuration(bindings: version < 6 ? [binding] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding])) }
        old.schemaVersion = version
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func schema17RetainsAllProfilesAndFileBytesUntilSave() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindSleepStore-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: directory.appending(path: "config.json"))
        var old = Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
            action: .workspace(.openSystemSettings), activation: .hold, holdDurationMilliseconds: 1000)])
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 17
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var loaded = try store.load()
        #expect(loaded.profiles == old.profiles && loaded.selectedProfileID == old.selectedProfileID && loaded.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        loaded.bindings[0].action = .sleepSystem
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }

    @Test @MainActor func rejectedSleepHasItsOwnLocalizedError() {
        let model = AppModel(loadConfiguration: false)
        model.mailbox.state.withLock { $0.actionFailed = .sleepSystem }
        model.refresh()
        #expect(model.error == .sleepSystemFailed)
    }

    private func ready() -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .sleepSystem)]))
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }
}
