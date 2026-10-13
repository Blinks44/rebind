import Testing
@testable import rebind

struct DoublePressMatcherTests {
    private let output = KeyboardShortcut(keyCode: 13, modifiers: .command)
    private let interval: UInt64 = 500_000_000

    private func binding(_ trigger: InputTrigger = .key(0), activation: PressActivation = .doublePress) -> rebind.Binding {
        rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control,
                       action: .shortcut(output), activation: activation)
    }

    private func event(_ phase: InputEvent.Phase, at time: UInt64, trigger: InputTrigger = .key(0),
                       modifiers: ModifierSet = .control, repeat isRepeat: Bool = false) -> InputEvent {
        InputEvent(trigger: trigger, modifiers: modifiers, phase: phase, isRepeat: isRepeat, timestamp: time)
    }

    @Test(arguments: [InputTrigger.key(0), .mouseButton(2), .mouseButton(99)])
    func pairDispatchesOnceAndOwnsBothReleases(_ trigger: InputTrigger) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding(trigger)])
        let first = matcher.handle(event(.down, at: 0, trigger: trigger), rules: rules, enabled: true)
        #expect(first.suppress && first.shortcut == nil)
        #expect(matcher.handle(event(.up, at: 1, trigger: trigger), rules: rules, enabled: true).suppress)
        let second = matcher.handle(event(.down, at: interval, trigger: trigger), rules: rules, enabled: true)
        #expect(second.suppress && second.shortcut == output)
        #expect(matcher.handle(event(.down, at: interval + 1, trigger: trigger, repeat: true), rules: rules, enabled: true).shortcut == nil)
        #expect(matcher.handle(event(.up, at: interval + 2, trigger: trigger, modifiers: []), rules: rules, enabled: false).suppress)
        #expect(matcher.hasSuppressedInput == false)
    }

    @Test func expiredPairStartsANewSequenceWithoutDelayedOutput() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        _ = matcher.handle(event(.up, at: 1), rules: rules, enabled: true)
        let late = matcher.handle(event(.down, at: interval + 1), rules: rules, enabled: true)
        #expect(late.suppress && late.shortcut == nil)
        _ = matcher.handle(event(.up, at: interval + 2), rules: rules, enabled: true)
        #expect(matcher.handle(event(.down, at: interval + 3), rules: rules, enabled: true).shortcut == output)
    }

    @Test(arguments: [InputEvent.Phase.down, .drag])
    func repeatedDownAndDraggingCancelFirstPress(_ phase: InputEvent.Phase) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        let held = matcher.handle(event(phase, at: 1, repeat: phase == .down), rules: rules, enabled: true)
        #expect(held.suppress && held.shortcut == nil)
        _ = matcher.handle(event(.up, at: 2), rules: rules, enabled: true)
        #expect(matcher.handle(event(.down, at: 3), rules: rules, enabled: true).shortcut == nil)
    }

    @Test func secondDownWithoutReleaseIsNeverADoublePress() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        #expect(matcher.handle(event(.down, at: 1), rules: rules, enabled: true).shortcut == nil)
        _ = matcher.handle(event(.up, at: 2), rules: rules, enabled: true)
        #expect(matcher.handle(event(.down, at: 3), rules: rules, enabled: true).shortcut == nil)
    }

    @Test(arguments: [InputTrigger.key(1), .mouseButton(0), .mouseButton(1), .mouseButton(3)])
    func anotherPressInterruptsWithoutBeingConsumed(_ trigger: InputTrigger) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        _ = matcher.handle(event(.up, at: 1), rules: rules, enabled: true)
        #expect(matcher.handle(event(.down, at: 2, trigger: trigger), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(event(.down, at: 3), rules: rules, enabled: true).shortcut == nil)
    }

    @Test func modifierChangeAwayAndBackCancelsAndAlwaysPassesThrough() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        _ = matcher.handle(event(.up, at: 1), rules: rules, enabled: true)
        #expect(matcher.handle(event(.modifiersChanged, at: 2, modifiers: []), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(event(.modifiersChanged, at: 3), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(event(.down, at: 4), rules: rules, enabled: true).shortcut == nil)
    }

    @Test func changedReleaseModifiersOrLongFirstHoldCannotArmAPair() {
        for release in [event(.up, at: 1, modifiers: []), event(.up, at: interval + 1)] {
            var matcher = InputMatcher()
            let rules = InputMatcher.compile([binding()])
            _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
            #expect(matcher.handle(release, rules: rules, enabled: true).suppress)
            #expect(matcher.handle(event(.down, at: release.timestamp + 1), rules: rules, enabled: true).shortcut == nil)
        }
    }

    @Test func taggedFeedbackDoesNotInterruptThePhysicalPair() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        _ = matcher.handle(event(.up, at: 1), rules: rules, enabled: true)
        var feedback = event(.down, at: 2, trigger: .key(13), modifiers: .command)
        feedback.isSynthetic = true
        #expect(matcher.handle(feedback, rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(event(.down, at: 3), rules: rules, enabled: true).shortcut == output)
    }

    @Test func regressedTimeFailsOpenAndExtremeTimeDoesNotOverflow() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: .max - 3), rules: rules, enabled: true)
        _ = matcher.handle(event(.up, at: .max - 2), rules: rules, enabled: true)
        #expect(matcher.handle(event(.down, at: .max), rules: rules, enabled: true).shortcut == output)
        matcher.resetAfterCaptureLoss()
        _ = matcher.handle(event(.down, at: 10), rules: rules, enabled: true)
        _ = matcher.handle(event(.up, at: 11), rules: rules, enabled: true)
        #expect(matcher.handle(event(.down, at: 9), rules: rules, enabled: true).suppress == false)
        #expect(matcher.hasSuppressedInput == false)
        #expect(matcher.handle(event(.down, at: 12), rules: rules, enabled: true).shortcut == nil)
    }

    @Test func consecutivePairsDoNotReuseTheirSecondPress() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        for press in UInt64(0)..<4 {
            let result = matcher.handle(event(.down, at: press * 2), rules: rules, enabled: true)
            #expect(result.suppress)
            #expect(result.shortcut == (press % 2 == 1 ? output : nil))
            _ = matcher.handle(event(.up, at: press * 2 + 1), rules: rules, enabled: true)
        }
    }

    @Test func pressAndDoublePressForSameChordConflictRatherThanGuessing() {
        let rules = InputMatcher.compile([binding(), binding(activation: .press)])
        var matcher = InputMatcher()
        #expect(rules.isEmpty)
        #expect(matcher.handle(event(.down, at: 0), rules: rules, enabled: true).suppress == false)
    }
}
