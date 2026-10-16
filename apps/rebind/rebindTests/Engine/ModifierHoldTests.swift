import CoreGraphics
import Foundation
import Testing
@testable import rebind

struct ModifierHoldTests {
    private let escape = KeyboardShortcut(keyCode: 53, modifiers: [])
    private let timing = KeyRepeatTiming(delayNanoseconds: 500, intervalNanoseconds: 100)

    private func modifierRule(_ activation: PressActivation = .press, tap: KeyboardShortcut? = nil) -> rebind.Binding {
        var binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .modifier(.command),
                                     activation: activation, holdDurationMilliseconds: 200)
        binding.holdsOutput = true
        binding.tapShortcut = tap
        return binding
    }

    private func mailbox(_ binding: rebind.Binding) -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]), keyRepeat: timing)
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }

    private func event(_ phase: InputEvent.Phase, at time: UInt64 = 0) -> InputEvent {
        InputEvent(trigger: .mouseButton(3), phase: phase, timestamp: time, receivedAt: time)
    }

    private func modifiers(_ phase: HeldKeyCommand.Phase) -> HeldKeyCommand {
        HeldKeyCommand(target: .modifiers(.command), phase: phase)
    }

    @Test func aModifierIsDownOnceWhileHeldNeverRepeatsAndIsAddedOnlyBetweenPressAndRelease() {
        let mailbox = mailbox(modifierRule())
        #expect(mailbox.virtualModifiers.isEmpty)
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.virtualModifiers.isEmpty)
        #expect(mailbox.nextHeldKey(at: 0) == modifiers(.press))
        #expect(mailbox.virtualModifiers == .command)
        #expect(mailbox.nextHeldKey(at: 1_000_000) == nil)
        #expect(mailbox.handle(event(.up), secureInput: false))
        #expect(mailbox.virtualModifiers.isEmpty)
        #expect(mailbox.nextHeldKey(at: 1_000_001) == modifiers(.release))
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.held.isEmpty })
    }

    @Test func aQuickTapOrAnInterruptionNeverLeavesAModifierDown() {
        var mailbox = mailbox(modifierRule())
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.handle(event(.up), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 0) == nil)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        mailbox = self.mailbox(modifierRule())
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 0) == modifiers(.press))
        mailbox.captureLost(status: .secureInput)
        #expect(mailbox.virtualModifiers.isEmpty)
        #expect(mailbox.nextHeldKey(at: 1) == modifiers(.release))
    }

    @Test func modifierEventsAreTaggedFlagChangesThatSetAndClearTheFlag() {
        let down = ShortcutSender.heldKeyEvents(HeldKeyCommand(target: .modifiers([.command, .shift]), phase: .press), physicalModifiers: [])
        #expect(down.map(\.type) == [.flagsChanged, .flagsChanged])
        #expect(down.map { $0.getIntegerValueField(.keyboardEventKeycode) } == [55, 56])
        #expect(down.allSatisfy { $0.flags.contains([.maskCommand, .maskShift])
            && $0.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag })
        let up = ShortcutSender.heldKeyEvents(modifiers(.release), physicalModifiers: [])
        #expect(up.count == 1 && up[0].type == .flagsChanged && !up[0].flags.contains(.maskCommand))
        #expect(ShortcutSender.heldKeyEvents(HeldKeyCommand(shortcut: escape, phase: .repeatPress)).first?
            .getIntegerValueField(.keyboardEventAutorepeat) == 1)
    }

    @Test func aHoldRuleSendsItsShortPressShortcutOnlyWhenReleasedEarly() {
        let mailbox = mailbox(modifierRule(.hold, tap: escape))
        #expect(mailbox.handle(event(.down, at: 0), secureInput: false))
        #expect(mailbox.handle(event(.up, at: 50_000_000), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(escape)])
        #expect(mailbox.state.withLock { $0.held.isEmpty })
    }

    @Test func aHoldRuleHoldsItsModifierFromTheHoldTimeUntilRelease() {
        let mailbox = mailbox(modifierRule(.hold, tap: escape))
        #expect(mailbox.handle(event(.down, at: 0), secureInput: false))
        mailbox.pollHold(at: 100_000_000, secureInput: false)
        #expect(mailbox.state.withLock { $0.held.isEmpty })
        mailbox.pollHold(at: 200_000_000, secureInput: false)
        #expect(mailbox.nextHeldKey(at: 200_000_001) == modifiers(.press))
        #expect(mailbox.virtualModifiers == .command)
        #expect(mailbox.handle(event(.up, at: 900_000_000), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 900_000_001) == modifiers(.release))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @MainActor @Test func validationCatalogEditorAndPersistence() throws {
        #expect(modifierRule().isValid && modifierRule(.hold, tap: escape).isValid)
        #expect(modifierRule(.doublePress).isValid == false)
        var oneShot = modifierRule()
        oneShot.holdsOutput = false
        #expect(oneShot.isValid == false)
        #expect(modifierRule(.press, tap: escape).isValid == false)
        var scroll = modifierRule()
        scroll.trigger = .scroll(.up)
        #expect(scroll.isValid == false)
        for kind in [ActionKind.holdCommand, .holdOption, .holdControl, .holdShift] {
            let action = kind.configuredAction(shortcut: nil)
            #expect(action.map(ActionKind.init(action:)) == kind && action?.requiresHeldOutput == true)
            #expect(kind.canBeHeld == false)
        }
        var draft = BindingEditorDraft(scope: .allMice, existing: modifierRule(.hold, tap: escape))
        #expect(draft.tapOutput == escape)
        let saved = try #require(draft.binding(scope: .allMice, action: .modifier(.command), existing: nil))
        #expect(saved.holdsOutput && saved.tapShortcut == escape && saved.isValid)
        draft.activation = .press
        #expect(draft.binding(scope: .allMice, action: .modifier(.command), existing: nil)?.tapShortcut == nil)
        let configuration = Configuration(isEnabled: true, bindings: [modifierRule(.hold, tap: escape)])
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
        var old = configuration
        old.schemaVersion = 33
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }

    @Test func overlappingModifierSetsReleaseOnlyUnownedFlags() throws {
        let mailbox = EngineMailbox()
        var first = modifierRule()
        first.action = .modifier([.command, .shift])
        var second = modifierRule()
        second.trigger = .mouseButton(4)
        second.action = .modifier([.option, .shift])
        mailbox.configure(Configuration(isEnabled: true, bindings: [first, second]))
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 0)?.target == .modifiers([.command, .shift]))
        #expect(mailbox.handle(InputEvent(trigger: second.trigger, phase: .down), secureInput: false))
        let down = try #require(mailbox.nextHeldKey(at: 1))
        #expect(down.target == .modifiers(.option) && down.otherModifiers == [.command, .shift])
        #expect(mailbox.handle(event(.up), secureInput: false))
        let up = try #require(mailbox.nextHeldKey(at: 2))
        #expect(up.target == .modifiers(.command) && up.otherModifiers == [.option, .shift])
        let posted = ShortcutSender.heldKeyEvents(up, physicalModifiers: .maskControl)
        #expect(posted.count == 1 && posted[0].flags == [.maskControl, .maskAlternate, .maskShift])
        #expect(mailbox.handle(InputEvent(trigger: second.trigger, phase: .up), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 3)?.target == .modifiers([.option, .shift]))
    }
}
