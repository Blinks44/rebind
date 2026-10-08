import Testing
@testable import rebind

struct HoldMatcherTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private let threshold: UInt64 = 500_000_000

    private func binding(_ trigger: InputTrigger = .key(1), duration: UInt32 = 500) -> rebind.Binding {
        rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control,
                       action: .shortcut(output), activation: .hold, holdDurationMilliseconds: duration)
    }

    private func event(_ phase: InputEvent.Phase, at time: UInt64, trigger: InputTrigger = .key(1),
                       modifiers: ModifierSet = .control, repeat isRepeat: Bool = false) -> InputEvent {
        InputEvent(trigger: trigger, modifiers: modifiers, phase: phase, isRepeat: isRepeat, timestamp: time)
    }

    @Test(arguments: [InputTrigger.key(1), .mouseButton(2), .mouseButton(3), .mouseButton(100)])
    func firesAtThresholdOnceWithoutReleasingSource(_ trigger: InputTrigger) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding(trigger)])
        let down = matcher.handle(event(.down, at: 10, trigger: trigger), rules: rules, enabled: true)
        #expect(down.suppress && down.shortcut == nil)
        #expect(matcher.pollHold(at: threshold + 9, rules: rules, enabled: true) == nil)
        #expect(matcher.pollHold(at: threshold + 10, rules: rules, enabled: true) == output)
        #expect(matcher.pollHold(at: threshold * 2, rules: rules, enabled: true) == nil)
        #expect(matcher.handle(event(.up, at: threshold * 2, trigger: trigger, modifiers: []), rules: rules, enabled: false).suppress)
        #expect(!matcher.hasSuppressedInput)
    }

    @Test func shortReleaseIsConsumedWithoutFallbackOrDelayedOutput() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        #expect(matcher.handle(event(.up, at: threshold - 1), rules: rules, enabled: true).suppress)
        #expect(matcher.pollHold(at: threshold, rules: rules, enabled: true) == nil)
        #expect(!matcher.hasSuppressedInput)
    }

    @Test func keyboardRepeatsDoNotCancelOrRepeatTheHoldAction() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        #expect(matcher.handle(event(.down, at: threshold - 1, repeat: true), rules: rules, enabled: true).suppress)
        #expect(matcher.pollHold(at: threshold, rules: rules, enabled: true) == output)
        #expect(matcher.handle(event(.down, at: threshold + 1, repeat: true), rules: rules, enabled: true).shortcut == nil)
        #expect(matcher.pollHold(at: threshold * 2, rules: rules, enabled: true) == nil)
    }

    @Test(arguments: [InputEvent.Phase.down, .modifiersChanged, .scroll])
    func interruptionsCancelButRetainSourceRelease(_ phase: InputEvent.Phase) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding(.mouseButton(3))])
        _ = matcher.handle(event(.down, at: 0, trigger: .mouseButton(3)), rules: rules, enabled: true)
        let trigger: InputTrigger = phase == .scroll ? .scroll(.up) : (phase == .down ? .key(2) : .mouseButton(3))
        _ = matcher.handle(event(phase, at: 1, trigger: trigger, modifiers: []), rules: rules, enabled: true)
        #expect(matcher.pollHold(at: threshold, rules: rules, enabled: true) == nil)
        #expect(matcher.handle(event(.up, at: threshold + 1, trigger: .mouseButton(3)), rules: rules, enabled: true).suppress)
    }

    @Test func duplicateDownAndRegressedRepeatCancelWithoutRestartingDeadline() {
        for interruption in [event(.down, at: 11), event(.down, at: 9, repeat: true)] {
            var matcher = InputMatcher()
            let rules = InputMatcher.compile([binding()])
            _ = matcher.handle(event(.down, at: 10), rules: rules, enabled: true)
            #expect(matcher.handle(interruption, rules: rules, enabled: true).suppress)
            #expect(matcher.pollHold(at: threshold + 10, rules: rules, enabled: true) == nil)
        }
    }

    @Test func unrelatedPrimaryDragCancelsWithoutBeingSuppressed() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding(.mouseButton(3))])
        _ = matcher.handle(event(.down, at: 0, trigger: .mouseButton(3)), rules: rules, enabled: true)
        #expect(!matcher.handle(event(.drag, at: 1, trigger: .mouseButton(0)), rules: rules, enabled: true).suppress)
        #expect(matcher.pollHold(at: threshold, rules: rules, enabled: true) == nil)
        #expect(matcher.handle(event(.up, at: threshold + 1, trigger: .mouseButton(3)), rules: rules, enabled: true).suppress)
    }

    @Test(arguments: [UInt32(2), 3, 4, 100])
    func heldMouseMotionPreservesDeadlineAndOneShotDelivery(_ button: UInt32) {
        var matcher = InputMatcher()
        let trigger = InputTrigger.mouseButton(button)
        let rules = InputMatcher.compile([binding(trigger, duration: 1000)])
        let duration: UInt64 = 1_000_000_000
        #expect(matcher.handle(event(.down, at: 10, trigger: trigger), rules: rules, enabled: true).suppress)
        for time in [UInt64(20), 100_000_000, 999_999_999] {
            let decision = matcher.handle(event(.drag, at: time, trigger: trigger), rules: rules, enabled: true)
            #expect(decision.suppress && decision.shortcut == nil)
        }
        #expect(matcher.pollHold(at: duration + 9, rules: rules, enabled: true) == nil)
        #expect(matcher.pollHold(at: duration + 10, rules: rules, enabled: true) == output)
        #expect(matcher.handle(event(.drag, at: duration + 11, trigger: trigger), rules: rules, enabled: true).suppress)
        #expect(matcher.pollHold(at: duration * 2, rules: rules, enabled: true) == nil)
        #expect(matcher.handle(event(.up, at: duration * 2, trigger: trigger), rules: rules, enabled: true).suppress)
        #expect(!matcher.hasSuppressedInput)
    }

    @Test func changedModifiersOnHeldMouseMotionStillCancel() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding(.mouseButton(4))])
        _ = matcher.handle(event(.down, at: 0, trigger: .mouseButton(4)), rules: rules, enabled: true)
        #expect(matcher.handle(event(.drag, at: 1, trigger: .mouseButton(4), modifiers: []), rules: rules, enabled: true).suppress)
        #expect(matcher.pollHold(at: threshold, rules: rules, enabled: true) == nil)
        #expect(matcher.handle(event(.up, at: threshold + 1, trigger: .mouseButton(4)), rules: rules, enabled: true).suppress)
    }

    @Test func taggedFeedbackDoesNotCancelRecognition() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        var feedback = event(.down, at: 1, trigger: .key(0), modifiers: .command)
        feedback.isSynthetic = true
        #expect(!matcher.handle(feedback, rules: rules, enabled: true).suppress)
        #expect(matcher.pollHold(at: threshold, rules: rules, enabled: true) == output)
    }

    @Test func receiptClockControlsHoldIndependentlyOfQuartzTimestamp() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        var down = event(.down, at: .max)
        down.receivedAt = 0
        _ = matcher.handle(down, rules: rules, enabled: true)
        var repeated = event(.down, at: 1, repeat: true)
        repeated.receivedAt = 1
        #expect(matcher.handle(repeated, rules: rules, enabled: true).suppress)
        #expect(matcher.pollHold(at: threshold, rules: rules, enabled: true) == output)
    }

    @Test func queueDenialPauseAndRuleRemovalCancelPermanently() {
        for mode in 0..<3 {
            var matcher = InputMatcher()
            let rules = InputMatcher.compile([binding()])
            _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
            #expect(matcher.pollHold(at: threshold, rules: mode == 2 ? [:] : rules,
                                     enabled: mode != 0, canDispatch: mode != 1) == nil)
            #expect(matcher.pollHold(at: threshold + 1, rules: rules, enabled: true) == nil)
            #expect(matcher.handle(event(.up, at: threshold + 2), rules: rules, enabled: false).suppress)
        }
    }

    @Test func staleAndRegressedPollingNeverFiresAndArithmeticDoesNotOverflow() {
        for now in [UInt64(9), threshold + InputMatcher.holdLatenessNanoseconds + 11] {
            var matcher = InputMatcher()
            let rules = InputMatcher.compile([binding()])
            _ = matcher.handle(event(.down, at: 10), rules: rules, enabled: true)
            #expect(matcher.pollHold(at: now, rules: rules, enabled: true) == nil)
            #expect(matcher.pollHold(at: threshold + 10, rules: rules, enabled: true) == nil)
        }
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: .max - threshold), rules: rules, enabled: true)
        #expect(matcher.pollHold(at: .max, rules: rules, enabled: true) == output)
    }

    @Test(arguments: [UInt32(100), 700, 5000])
    func configuredThresholdIsUsed(_ milliseconds: UInt32) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding(duration: milliseconds)])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        let threshold = UInt64(milliseconds) * 1_000_000
        #expect(matcher.pollHold(at: threshold - 1, rules: rules, enabled: true) == nil)
        #expect(matcher.pollHold(at: threshold, rules: rules, enabled: true) == output)
    }
}
