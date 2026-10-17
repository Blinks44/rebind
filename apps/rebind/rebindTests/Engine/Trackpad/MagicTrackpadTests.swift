import Foundation
import Synchronization
import Testing
@testable import rebind

struct MagicTrackpadTests {
    private func binding(_ scope: DeviceScope, _ trigger: InputTrigger, key: UInt16) -> rebind.Binding {
        rebind.Binding(scope: scope, trigger: trigger, modifiers: [], action: .shortcut(.init(keyCode: key, modifiers: .command)))
    }

    @Test func sameGestureOnBothSurfacesKeepsSeparateRules() throws {
        let configuration = Configuration(isEnabled: true, bindings: [
            binding(.builtInTrackpad, .threeFingerTap, key: 1), binding(.magicTrackpad, .threeFingerTap, key: 2),
            binding(.magicTrackpad, .trackpadClick(fingers: 3), key: 3),
        ])
        try configuration.validate()
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
        let builtIn = try #require(mailbox.trackpadRuntime())
        let magic = try #require(mailbox.trackpadRuntime(magicTrackpad: true))
        #expect(builtIn.actions[.single(.threeFinger)]?.shortcut?.keyCode == 1 && !builtIn.hasClickRules)
        #expect(magic.actions[.single(.threeFinger)]?.shortcut?.keyCode == 2 && magic.hasClickRules && magic.isMagicTrackpad)
        var spoofed = builtIn
        spoofed.isMagicTrackpad = true
        #expect(mailbox.submitTrackpad(spoofed, gesture: .single(.threeFinger), pid: 100, at: 1_000) == false)
        #expect(mailbox.submitTrackpad(magic, gesture: .single(.threeFinger), pid: 100, at: 1_000))
        #expect(mailbox.nextAction()?.action.shortcut?.keyCode == 2)
    }

    @Test func clickIsResolvedByTheSurfaceThatHoldsTheFingers() {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [
            binding(.builtInTrackpad, .trackpadClick(fingers: 3), key: 1), binding(.magicTrackpad, .trackpadClick(fingers: 3), key: 2),
        ]))
        mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
        var frame = NativeTrackpadFrame(receipt: 4_000_000_000, revision: 0, activity: 0, frame: 1, time: 4, count: 3)
        frame.first = .init(id: 0, x: 0.3, y: 0.5, pressure: 100)
        frame.second = .init(id: 1, x: 0.4, y: 0.5, pressure: 100)
        frame.third = .init(id: 2, x: 0.5, y: 0.5, pressure: 100)
        mailbox.state.withLock { $0.magicTrackpadClicks.observe(frame, reportsForce: true) }
        let down = InputEvent(trigger: .mouseButton(0), phase: .down, receivedAt: 4_005_000_000)
        #expect(mailbox.handle(down, secureInput: false))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: .up, receivedAt: 4_020_000_000), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.compactMap(\.shortcut?.keyCode) } == [2])
    }

    @Test func scopeAcceptsOnlyTrackpadGesturesAndOlderFilesCannotCarryIt() throws {
        #expect(binding(.magicTrackpad, .cornerTap(.topLeft), key: 1).isValid)
        #expect(binding(.magicTrackpad, .key(13), key: 1).isValid == false)
        #expect(binding(.magicTrackpad, .mouseButton(3), key: 1).isValid == false)
        var old = Configuration(isEnabled: true, bindings: [binding(.magicTrackpad, .fourFingerTap, key: 1)])
        try old.validate()
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(decoded.bindings.first?.scope == .magicTrackpad)
        old.schemaVersion = 31
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }
}
