import Foundation
import Testing
@testable import rebind

struct TrackpadModifierTests {
    private let plain = RebindAction.dock(.missionControl)
    private let modified = RebindAction.window(.close)

    private func rule(_ trigger: InputTrigger, _ modifiers: ModifierSet, _ action: RebindAction) -> rebind.Binding {
        rebind.Binding(scope: .builtInTrackpad, trigger: trigger, modifiers: modifiers, action: action)
    }

    private func mailbox(_ bindings: [rebind.Binding]) -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: bindings))
        mailbox.state.withLock { $0.status = .active }
        mailbox.updateTrackpadForeground(100)
        return mailbox
    }

    @Test func theSameGestureRunsADifferentRuleForExactlyTheHeldKey() throws {
        let mailbox = mailbox([rule(.threeFingerTap, [], plain), rule(.threeFingerTap, .command, modified)])
        #expect(mailbox.trackpadRuntime()?.actions[.single(.threeFinger)] == plain)
        let held = try #require(mailbox.trackpadRuntime(modifiers: .command))
        #expect(held.actions[.single(.threeFinger)] == modified && held.modifiers == .command)
        // Another key, or an extra one, matches nothing: modifiers are exact, as for keys and buttons.
        #expect(mailbox.trackpadRuntime(modifiers: .option) == nil)
        #expect(mailbox.trackpadRuntime(modifiers: [.command, .shift]) == nil)
        #expect(mailbox.submitTrackpad(held, gesture: .single(.threeFinger), pid: 100, at: 0))
        let dispatch = try #require(mailbox.nextAction())
        #expect(dispatch.action == modified && dispatch.trackpadTarget?.modifiers == .command)
    }

    @Test func aRuleWithAKeyDoesNotFireWithoutItAndClickRulesKeepFramesFlowingForAnyKey() {
        let mailbox = mailbox([rule(.fourFingerTap, .option, modified), rule(.trackpadClick(fingers: 3), .shift, plain)])
        let runtime = mailbox.trackpadRuntime()
        #expect(runtime?.actions.isEmpty == true && runtime?.hasClickRules == true)
        #expect(mailbox.trackpadRuntime(modifiers: .option)?.actions[.single(.fourFinger)] == modified)
    }

    @MainActor @Test func onlyOneCuratedKeyIsAllowedAndItShowsInTheLabelEditorAndStorage() throws {
        #expect(rule(.threeFingerTap, .control, plain).isValid)
        #expect(rule(.threeFingerTap, [.command, .shift], plain).isValid == false)
        #expect(InputLabels.trigger(.threeFingerTap, modifiers: .command).hasPrefix("⌘ "))
        var draft = BindingEditorDraft(scope: .builtInTrackpad, existing: rule(.cornerTap(.topLeft), .shift, plain))
        #expect(draft.trackpadModifiers == .shift)
        draft.trackpadPreset = .fourFingerTap
        #expect(draft.trigger == MatchKey(trigger: .fourFingerTap, modifiers: .shift))
        draft.trackpadModifiers = []
        #expect(draft.binding(scope: .builtInTrackpad, action: plain, existing: nil)?.modifiers.isEmpty == true)
        let configuration = Configuration(isEnabled: true, bindings: [rule(.threeFingerTap, .command, modified)])
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
        var old = configuration
        old.schemaVersion = 33
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }
}
