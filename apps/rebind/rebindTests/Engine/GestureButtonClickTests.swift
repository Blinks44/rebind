import Testing
@testable import rebind

/// A button that carries pointer gestures still clicks when it is released without movement.
struct GestureButtonClickTests {
    private let gesture = rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: 3, direction: .left), modifiers: [],
                                         action: .shortcut(.init(keyCode: 123, modifiers: .control)))
    private let press = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
                                       action: .shortcut(.init(keyCode: 33, modifiers: .command)))

    private func event(_ phase: InputEvent.Phase, at time: UInt64, dx: Int64 = 0) -> InputEvent {
        InputEvent(trigger: .mouseButton(3), phase: phase, timestamp: time, receivedAt: time,
                   motion: phase == .drag ? PointerMotion(deltaX: dx, deltaY: 0) : nil)
    }

    @Test func clickWithoutMovementRunsThePressRuleOnRelease() throws {
        let configuration = Configuration(isEnabled: true, bindings: [gesture, press])
        try configuration.validate()
        let rules = InputMatcher.compile(configuration.bindings)
        #expect(rules.count == 2)
        var matcher = InputMatcher()
        #expect(matcher.handle(event(.down, at: 1_000), rules: rules, enabled: true) == MatchDecision(suppress: true))
        #expect(matcher.handle(event(.up, at: 90_000_000), rules: rules, enabled: true)
                == MatchDecision(suppress: true, action: press.action))
        #expect(!matcher.hasSuppressedInput)
    }

    @Test func movementRunsOnlyTheGesture() {
        let rules = InputMatcher.compile([gesture, press])
        var matcher = InputMatcher()
        _ = matcher.handle(event(.down, at: 1_000), rules: rules, enabled: true)
        let moved = matcher.handle(event(.drag, at: 20_000_000, dx: -80), rules: rules, enabled: true)
        #expect(moved.action == gesture.action)
        #expect(matcher.handle(event(.up, at: 90_000_000), rules: rules, enabled: true) == MatchDecision(suppress: true))
    }

    @Test func withoutAPressRuleTheOrdinaryClickIsGivenBack() {
        let rules = InputMatcher.compile([gesture])
        var matcher = InputMatcher()
        _ = matcher.handle(event(.down, at: 1_000), rules: rules, enabled: true)
        #expect(matcher.handle(event(.up, at: 90_000_000), rules: rules, enabled: true)
                == MatchDecision(suppress: true, action: .mouse(.backClick)))
    }

    @Test func pauseOrACancelledStrokeNeverClicks() {
        let rules = InputMatcher.compile([gesture, press])
        var matcher = InputMatcher()
        _ = matcher.handle(event(.down, at: 1_000), rules: rules, enabled: true)
        #expect(matcher.handle(event(.up, at: 90_000_000), rules: rules, enabled: false) == MatchDecision(suppress: true))
        _ = matcher.handle(event(.down, at: 200_000_000), rules: rules, enabled: true)
        // An unconfigured direction ends recognition; releasing afterwards is not a click.
        _ = matcher.handle(event(.drag, at: 220_000_000, dx: 80), rules: rules, enabled: true)
        #expect(matcher.handle(event(.up, at: 290_000_000), rules: rules, enabled: true) == MatchDecision(suppress: true))
    }

    @Test func holdOrDoublePressOnAGestureButtonStaysAConflict() {
        for activation in [PressActivation.hold, .doublePress] {
            var timed = press
            timed.activation = activation
            #expect(throws: ConfigurationError.conflict) {
                try Configuration(isEnabled: true, bindings: [gesture, timed]).validate()
            }
            #expect(InputMatcher.compile([gesture, timed]).isEmpty)
        }
    }

    @Test @MainActor func backAndForwardAreTheStandardShortcutsAndKeepTheirNames() {
        let back = ActionKind.navigateBack.configuredAction(shortcut: nil)
        #expect(back == .shortcut(.init(keyCode: 33, modifiers: .command)))
        #expect(ActionKind.navigateForward.configuredAction(shortcut: nil) == .shortcut(.init(keyCode: 30, modifiers: .command)))
        #expect(back.map(ActionKind.init(action:)) == .navigateBack)
        #expect(back?.label == AppLocalization.string(.navigateBackAction))
        #expect(ActionKind(action: .shortcut(.init(keyCode: 13, modifiers: .command))) == .keyboardShortcut)
    }
}
