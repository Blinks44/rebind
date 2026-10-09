import Foundation
import Synchronization
import Testing
@testable import rebind

struct MouseActionTests {
    @Test(arguments: MouseAction.allCases) @MainActor
    func catalogPersistsRealMouseActionsWithoutRecordedShortcut(_ mouse: MouseAction) throws {
        let action = RebindAction.mouse(mouse), kind = ActionKind(action: .mouse(mouse))
        #expect(kind.category == .mouse && kind.mouseAction == mouse)
        #expect(kind.configuredAction(shortcut: nil) == action && action.shortcut == nil && action.isSupported)
        #expect(kind.isAvailable(with: AudioOutputCapabilities()) && AudioOutputCapabilities().supports(action))
        #expect(action.label == String(localized: kind.title))
        #expect(try JSONDecoder().decode(RebindAction.self, from: JSONEncoder().encode(action)) == action)
    }

    @Test(arguments: MouseAction.allCases, [InputTrigger.key(0), .mouseButton(99), .scroll(.right), .mouseGesture(button: 99, direction: .left)])
    func matchesAllSupportedInputCategoriesWithExactSourceModifiers(_ mouse: MouseAction, _ trigger: InputTrigger) {
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: .mouse(mouse))
        let rules = InputMatcher.compile([binding])
        var matcher = InputMatcher()
        let source = trigger.pressSource
        let phase: InputEvent.Phase = trigger.isScroll ? .scroll : .down
        #expect(!matcher.handle(InputEvent(trigger: source, phase: phase), rules: rules, enabled: true).suppress)
        var decision = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase), rules: rules, enabled: true)
        if trigger.isPointerGesture {
            decision = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: .drag,
                motion: PointerMotion(deltaX: -50, deltaY: 0)), rules: rules, enabled: true)
        }
        #expect(decision.suppress && decision.action == .mouse(mouse) && decision.shortcut == nil)
        if !trigger.isScroll {
            #expect(matcher.handle(InputEvent(trigger: source, phase: .up), rules: rules, enabled: false).suppress)
            #expect(!matcher.hasSuppressedInput)
        }
        #expect(!matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase, isSynthetic: true),
            rules: rules, enabled: true).suppress)
    }

    @Test func schema13MigratesAllProfilesAndEarlierActionsWithoutRewritingUntilSave() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindMouse-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: folder.appending(path: "configuration.json"))
        let oldActions: [RebindAction] = [.shortcut(.init(keyCode: 0, modifiers: .command)), .system(.toggleMute),
            .window(.minimize), .workspace(.openURL(try #require(URL(string: "https://example.com")))),
            .appleShortcut(.init(id: UUID(), name: "Test")), .dock(.missionControl), .dock(.previousSpace), .dock(.nextSpace)]
        var old = Configuration(isEnabled: true, bindings: oldActions.enumerated().map { i, action in
            rebind.Binding(scope: .allMice, trigger: .mouseButton(UInt32(i + 3)), modifiers: .control, action: action,
                activation: .hold, holdDurationMilliseconds: 1000)
        })
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 13
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var loaded = try store.load()
        #expect(loaded.schemaVersion == Configuration.currentSchemaVersion && loaded.profiles == old.profiles)
        #expect(loaded.selectedProfileID == old.selectedProfileID && loaded.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        loaded.bindings[0].action = .mouse(.doubleLeftClick)
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }

    @Test(arguments: 1...13) func mouseOutputCannotMasqueradeInAnyOldSchemaOrInactiveProfile(_ version: Int) throws {
        let rule = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .mouse(.leftClick))
        var old = Configuration(bindings: version < 6 ? [rule] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [rule])) }
        old.schemaVersion = version
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func unknownMousePayloadFailsDecoding() throws {
        let bytes = try JSONEncoder().encode(RebindAction.mouse(.leftClick))
        let unknown = Data(String(decoding: bytes, as: UTF8.self).replacingOccurrences(of: "leftClick", with: "unknownClick").utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(RebindAction.self, from: unknown) }
    }

    @Test func serialWorkerRoutesClicksWithoutKeyboardFallbackAndReportsFailureWithoutPausing() {
        let mailbox = readyMailbox()
        let calls = Mutex<[RebindAction]>([])
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendShortcut: { value in calls.withLock { $0.append(.shortcut(value)) }; return true },
            performMouse: { action, allowed in
                #expect(allowed())
                calls.withLock { $0.append(.mouse(action)) }
                return action == .rightClick ? .unavailable : .performed
            }, performDock: { action, allowed in
                #expect(allowed()); calls.withLock { $0.append(.dock(action)) }; return .performed
            }, secureInput: { false }, postingAllowed: { true })
        let sequence: [RebindAction] = [.mouse(.leftClick), .dock(.nextSpace), .mouse(.rightClick),
            .shortcut(.init(keyCode: 0, modifiers: .command))]
        mailbox.state.withLock { $0.pending = sequence }
        for time in UInt64(0)...3 { worker.service(at: time) }
        #expect(calls.withLock { $0 } == sequence)
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == .mouse(.rightClick) })
    }

    @Test(arguments: 0...5) func cancellationAtMouseBackendFinalGateNeverProducesClickOrStaleError(_ change: Int) {
        let mailbox = readyMailbox()
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performMouse: { _, allowed in
                switch change {
                case 0: mailbox.configure(Configuration(isEnabled: false))
                case 1: mailbox.setEditing(true)
                case 2: mailbox.record(RecordingRequest(target: .keyboardTrigger))
                case 3: mailbox.suspend(true)
                case 4: mailbox.stop()
                default: mailbox.configure(Configuration(isEnabled: true))
                }
                #expect(!allowed()); return .cancelled
            }, secureInput: { false }, postingAllowed: { true })
        mailbox.state.withLock { $0.pending = [.mouse(.leftClick)] }
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.actionFailed == nil && $0.pending.isEmpty })
    }

    @Test(arguments: [true, false]) func protectedContextsNeverInvokeClickBackend(_ secure: Bool) {
        let mailbox = readyMailbox()
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performMouse: { _, _ in Issue.record("Mouse output in protected context"); return .performed },
            secureInput: { secure }, postingAllowed: { secure })
        mailbox.state.withLock { $0.pending = [.mouse(.leftClick)] }
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.status == (secure ? .secureInput : .permissionRequired) })
    }

    @Test @MainActor func mouseFailureUsesLocalizedError() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindMouseUI-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        let model = AppModel(store: ConfigurationStore(url: folder.appending(path: "configuration.json")))
        model.mailbox.state.withLock { $0.actionFailed = .mouse(.leftClick) }
        model.refresh()
        #expect(model.error == .mouseActionFailed)
    }

    private func readyMailbox() -> EngineMailbox {
        let mailbox = EngineMailbox()
        let rule = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .mouse(.leftClick))
        mailbox.configure(Configuration(isEnabled: true, bindings: [rule]))
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }
}
