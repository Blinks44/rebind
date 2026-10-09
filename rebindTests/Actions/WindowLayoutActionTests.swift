import Foundation
import Synchronization
import Testing
@testable import rebind

struct WindowLayoutActionTests {
    private let displays = [WindowDisplay(frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
                                         visibleFrame: CGRect(x: 0, y: 25, width: 1000, height: 725))]

    @Test(arguments: WindowLayoutAction.allCases, [InputTrigger.key(0), .mouseButton(99), .scroll(.right)])
    @MainActor func catalogAndExistingInputsUseTypedAction(_ layout: WindowLayoutAction, _ trigger: InputTrigger) throws {
        let action = RebindAction.windowLayout(layout)
        let kind = ActionKind(action: action)
        #expect(kind.windowLayoutAction == layout && kind.category == .windows && kind.configuredAction(shortcut: nil) == action)
        #expect(AudioOutputCapabilities().supports(action) && kind.isAvailable(with: AudioOutputCapabilities()))
        #expect(action.label == String(localized: kind.title))
        #expect(try JSONDecoder().decode(RebindAction.self, from: JSONEncoder().encode(action)) == action)
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: action)]))
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.handle(InputEvent(trigger: trigger, modifiers: .control, phase: trigger.isScroll ? .scroll : .down), secureInput: false))
        #expect(mailbox.nextAction()?.action == action)
        if !trigger.isScroll { #expect(mailbox.handle(InputEvent(trigger: trigger, phase: .up), secureInput: false)) }
    }

    @Test func schema15MigratesAllProfilesWithoutWritingUntilExplicitSave() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: folder.appending(path: "configuration.json"))
        var old = Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
            action: .media(.playPause), activation: .hold, holdDurationMilliseconds: 1000)])
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 15
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var loaded = try store.load()
        #expect(loaded.profiles == old.profiles && loaded.selectedProfileID == old.selectedProfileID && loaded.isEnabled)
        #expect(loaded.schemaVersion == Configuration.currentSchemaVersion)
        #expect(try Data(contentsOf: store.url) == bytes)
        loaded.bindings[0].action = .windowLayout(.center)
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }

    @Test(arguments: 1...15) func oldSchemasRejectLayoutEvenInInactiveProfile(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .windowLayout(.fill))
        var old = Configuration(bindings: version < 6 ? [binding] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding])) }
        old.schemaVersion = version
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func unknownLayoutFailsDecoding() throws {
        let encoded = try JSONEncoder().encode(RebindAction.windowLayout(.fill))
        let bytes = Data(String(decoding: encoded, as: UTF8.self).replacingOccurrences(of: "fill", with: "unknownLayout").utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(RebindAction.self, from: bytes) }
    }

    @Test(arguments: [WindowActionResult.performed, .cancelled, .unavailable])
    func workerRoutesFreshGeometryAndOnlyReportsUnavailable(_ result: WindowActionResult) {
        let mailbox = readyMailbox()
        let calls = Mutex(0)
        let expected = displays
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init() },
            sendShortcut: { _ in Issue.record("Layout reached keyboard sender"); return false },
            performWindowLayout: { action, displays, canPerform in
                #expect(action == .leftHalf && displays == expected && canPerform())
                calls.withLock { $0 += 1 }
                return result
            }, layoutClock: { 100 }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 100)
        #expect(calls.withLock { $0 } == 1)
        #expect(mailbox.state.withLock { $0.actionFailed } == (result == .unavailable ? .windowLayout(.leftHalf) : nil))
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause })
    }

    @Test(arguments: [UInt64(0), 2_000_000_101])
    func staleOrFutureSnapshotFailsWithoutAXCalls(_ now: UInt64) {
        let mailbox = readyMailbox()
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init() },
            performWindowLayout: { _, _, _ in Issue.record("Stale geometry reached AX"); return .performed },
            layoutClock: { now }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: now)
        #expect(mailbox.state.withLock { $0.actionFailed == .windowLayout(.leftHalf) && !$0.emergencyPause })
    }

    @Test(arguments: 0...8) func finalGateCancelsForGeometryOrLifecycleChange(_ change: Int) {
        let mailbox = readyMailbox()
        let clock = Mutex<UInt64>(100)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init() },
            performWindowLayout: { _, _, canPerform in
                #expect(canPerform())
                switch change {
                case 0: mailbox.updateWindowDisplays(.init())
                case 1: clock.withLock { $0 = 2_000_000_101 }
                case 2: mailbox.setEditing(true)
                case 3: mailbox.record(.init(target: .mouseTrigger))
                case 4: mailbox.suspend(true)
                case 5: mailbox.stop()
                case 6: mailbox.configure(Configuration(isEnabled: false))
                case 7: mailbox.configure(Configuration(isEnabled: true))
                default:
                    mailbox.state.withLock { $0.windowDisplays.displays[0].visibleFrame.origin.y += 10 }
                }
                #expect(!canPerform())
                return .cancelled
            }, layoutClock: { clock.withLock { $0 } }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 100)
        #expect(mailbox.state.withLock { $0.actionFailed == nil })
    }

    @Test func screenRefreshDoesNotCancelUnrelatedQueuedActions() {
        let mailbox = readyMailbox()
        let revision = mailbox.state.withLock { $0.actionRevision }
        mailbox.state.withLock { $0.pending = [.media(.playPause), .window(.minimize)] }
        mailbox.updateWindowDisplays(.init(displays: displays, capturedAt: 200))
        #expect(mailbox.state.withLock { $0.actionRevision == revision && $0.pending == [.media(.playPause), .window(.minimize)] })
    }

    @Test @MainActor func failureHasLocalizedLayoutError() {
        let model = AppModel(loadConfiguration: false)
        model.mailbox.state.withLock { $0.actionFailed = .windowLayout(.center) }
        model.refresh()
        #expect(model.error == .windowLayoutFailed)
    }

    private func readyMailbox() -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true))
        mailbox.updateWindowDisplays(.init(displays: displays, capturedAt: 100))
        mailbox.state.withLock { $0.status = .active; $0.pending = [.windowLayout(.leftHalf)] }
        return mailbox
    }
}
