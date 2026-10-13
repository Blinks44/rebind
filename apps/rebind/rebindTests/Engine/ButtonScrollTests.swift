import Foundation
import Testing
@testable import rebind

struct ButtonScrollTests {
    private let volume = RebindAction.system(.volumeUp)
    private let press = RebindAction.shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command))

    private func wheelRule(_ direction: ScrollDirection = .up, button: UInt32 = 3) -> rebind.Binding {
        rebind.Binding(scope: .allMice, trigger: .buttonScroll(button: button, direction: direction), modifiers: [], action: volume)
    }

    private func button(_ phase: InputEvent.Phase, at time: UInt64 = 0) -> InputEvent {
        InputEvent(trigger: .mouseButton(3), phase: phase, timestamp: time, receivedAt: time)
    }

    private func wheel(_ direction: ScrollDirection, at time: UInt64) -> InputEvent {
        InputEvent(trigger: .scroll(direction), phase: .scroll, timestamp: time, receivedAt: time)
    }

    private let step = InputMatcher.scrollIntervalNanoseconds

    @Test func wheelStepsRunWhileTheButtonIsHeldAndTheHoldIsNotAClick() {
        let rules = InputMatcher.compile([wheelRule()])
        var matcher = InputMatcher()
        #expect(matcher.handle(button(.down), rules: rules, enabled: true) == MatchDecision(suppress: true))
        #expect(matcher.handle(wheel(.up, at: step), rules: rules, enabled: true) == MatchDecision(suppress: true, action: volume))
        // Throttled like every wheel rule, and still swallowed.
        #expect(matcher.handle(wheel(.up, at: step + 1), rules: rules, enabled: true) == MatchDecision(suppress: true))
        #expect(matcher.handle(wheel(.up, at: 2 * step), rules: rules, enabled: true).action == volume)
        #expect(matcher.handle(button(.up, at: 3 * step), rules: rules, enabled: true) == MatchDecision(suppress: true))
        // Without the button the wheel is ordinary input again.
        #expect(matcher.handle(wheel(.up, at: 5 * step), rules: rules, enabled: true) == MatchDecision())
    }

    @Test func aHoldWithoutTheWheelIsStillTheButtonsClickEvenAfterMovement() {
        let rules = InputMatcher.compile([wheelRule()])
        var matcher = InputMatcher()
        _ = matcher.handle(button(.down), rules: rules, enabled: true)
        var drag = button(.drag, at: 1)
        drag.motion = PointerMotion(deltaX: 400, deltaY: 0)
        // A wheel-only button does not capture movement or treat it as a gesture.
        #expect(matcher.handle(drag, rules: rules, enabled: true) == MatchDecision())
        #expect(matcher.handle(button(.up, at: 2), rules: rules, enabled: true)
            == MatchDecision(suppress: true, action: .mouse(.backClick)))
    }

    @Test func aPressRuleOnTheSameButtonRunsOnAPlainClickAndGesturesCoexist() {
        let pressRule = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: press)
        let gesture = rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: 3, direction: .left), modifiers: [],
                                     action: .dock(.missionControl))
        let rules = InputMatcher.compile([wheelRule(), pressRule, gesture])
        #expect(rules.count == 3)
        var matcher = InputMatcher()
        _ = matcher.handle(button(.down), rules: rules, enabled: true)
        #expect(matcher.handle(button(.up, at: 1), rules: rules, enabled: true).action == press)
        _ = matcher.handle(button(.down, at: 2), rules: rules, enabled: true)
        #expect(matcher.handle(wheel(.up, at: 10 * step), rules: rules, enabled: true).action == volume)
        var drag = button(.drag, at: 10 * step + 1)
        drag.motion = PointerMotion(deltaX: -400, deltaY: 0)
        // Once the wheel was used, the same hold no longer becomes a gesture or a click.
        #expect(matcher.handle(drag, rules: rules, enabled: true).action == nil)
        #expect(matcher.handle(button(.up, at: 10 * step + 2), rules: rules, enabled: true).action == nil)
    }

    @Test func anotherDirectionModifierOrPausePassesTheWheelThrough() {
        let rules = InputMatcher.compile([wheelRule()])
        var matcher = InputMatcher()
        _ = matcher.handle(button(.down), rules: rules, enabled: true)
        #expect(matcher.handle(wheel(.down, at: step), rules: rules, enabled: true) == MatchDecision())
        matcher = InputMatcher()
        _ = matcher.handle(button(.down), rules: rules, enabled: true)
        var modified = wheel(.up, at: step)
        modified.modifiers = .command
        #expect(matcher.handle(modified, rules: rules, enabled: true) == MatchDecision())
        matcher = InputMatcher()
        _ = matcher.handle(button(.down), rules: rules, enabled: true)
        #expect(matcher.handle(wheel(.up, at: step), rules: rules, enabled: false) == MatchDecision())
    }

    @MainActor @Test func validationLabelsEditorAndPersistence() throws {
        #expect(wheelRule().isValid)
        #expect(wheelRule(button: 1).isValid == false)
        var held = wheelRule()
        held.activation = .hold
        #expect(held.isValid == false)
        let holdRule = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: press, activation: .hold)
        #expect(InputMatcher.compile([wheelRule(), holdRule]).isEmpty)
        #expect(throws: ConfigurationError.conflict) { try Configuration(bindings: [wheelRule(), holdRule]).validate() }
        #expect(InputLabels.trigger(wheelRule().trigger, modifiers: []).contains("4"))

        var draft = BindingEditorDraft(scope: .allMice, existing: wheelRule(.down))
        #expect(draft.mouseTarget == .buttonScrollTrigger && draft.scrollDirection == .down)
        draft.scrollDirection = .left
        #expect(draft.binding(scope: .allMice, action: volume, existing: nil)?.trigger == .buttonScroll(button: 3, direction: .left))

        let configuration = Configuration(isEnabled: true, bindings: [wheelRule()])
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
        var old = configuration
        old.schemaVersion = 33
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }
}
