import Testing
@testable import rebind

struct PointerGestureMatcherTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private func binding(_ direction: PointerDirection = .left, button: UInt32 = 3) -> rebind.Binding {
        rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: button, direction: direction),
                       modifiers: .control, action: .shortcut(output))
    }
    private func event(_ phase: InputEvent.Phase, x: Int64 = 0, y: Int64 = 0,
                       at time: UInt64 = 1, button: UInt32 = 3, modifiers: ModifierSet = .control) -> InputEvent {
        InputEvent(trigger: .mouseButton(button), modifiers: modifiers, phase: phase,
                   receivedAt: time, motion: phase == .drag ? PointerMotion(deltaX: x, deltaY: y) : nil)
    }
    private func delta(_ direction: PointerDirection, distance: Int64) -> (Int64, Int64) {
        switch direction {
        case .left: (-distance, 0)
        case .right: (distance, 0)
        case .up: (0, -distance)
        case .down: (0, distance)
        }
    }

    @Test(arguments: PointerDirection.allCases)
    func accumulatedDirectionFiresAtBoundaryOnceAndRearmsAfterRelease(_ direction: PointerDirection) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding(direction)])
        #expect(matcher.handle(event(.down, at: 0), rules: rules, enabled: true).suppress)
        let partial = delta(direction, distance: 49)
        let remaining = delta(direction, distance: 1)
        #expect(matcher.handle(event(.drag, x: partial.0, y: partial.1), rules: rules, enabled: true).shortcut == nil)
        let decision = matcher.handle(event(.drag, x: remaining.0, y: remaining.1, at: 2), rules: rules, enabled: true)
        #expect(decision.suppress && decision.shortcut == output)
        #expect(matcher.handle(event(.drag, x: partial.0, y: partial.1, at: 3), rules: rules, enabled: true).shortcut == nil)
        #expect(matcher.handle(event(.up, at: 4, modifiers: []), rules: rules, enabled: true).suppress)
        #expect(matcher.hasSuppressedInput == false)
        #expect(matcher.pointerGestureSource == nil)
        #expect(matcher.handle(event(.down, at: 5), rules: rules, enabled: true).suppress)
        let complete = delta(direction, distance: 50)
        #expect(matcher.handle(event(.drag, x: complete.0, y: complete.1, at: 6), rules: rules, enabled: true).shortcut == output)
    }

    @Test func separateDirectionsShareOneSourceAndChooseOneAction() {
        var matcher = InputMatcher()
        let left = binding()
        var right = binding(.right)
        right.action = .shortcut(KeyboardShortcut(keyCode: 1, modifiers: .option))
        let rules = InputMatcher.compile([left, right])
        #expect(rules.count == 2)
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        #expect(matcher.handle(event(.drag, x: 50), rules: rules, enabled: true).shortcut == right.action.shortcut)
        #expect(matcher.handle(event(.drag, x: -100, at: 2), rules: rules, enabled: true).shortcut == nil)
    }

    @Test(arguments: [UInt32(2), 4, 99, .max])
    func numericButtonsAreUnboundedAndModifiersMatchExactly(_ button: UInt32) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding(button: button)])
        #expect(matcher.handle(event(.down, button: button, modifiers: []), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(event(.down, button: button, modifiers: [.control, .shift]), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(event(.down, at: 2, button: button), rules: rules, enabled: true).suppress)
        #expect(matcher.handle(event(.drag, x: -50, at: 3, button: button), rules: rules, enabled: true).shortcut == output)
    }

    @Test func shortPressAndNetJitterDoNotReplayOrFire() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        for time in UInt64(1)...20 {
            let x: Int64 = time.isMultiple(of: 2) ? 20 : -20
            #expect(matcher.handle(event(.drag, x: x, at: time), rules: rules, enabled: true).shortcut == nil)
        }
        #expect(matcher.handle(event(.up, at: 21), rules: rules, enabled: true).suppress)
        #expect(matcher.handle(event(.drag, x: -50, at: 22), rules: rules, enabled: true).suppress == false)
    }

    @Test(arguments: [PointerMotion(deltaX: 50, deltaY: 0), PointerMotion(deltaX: -50, deltaY: 26), PointerMotion(deltaX: -50, deltaY: 50)])
    func wrongDirectionOrAmbiguousDiagonalCancelRatherThanChooseLater(_ motion: PointerMotion) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        #expect(matcher.handle(event(.drag, x: motion.deltaX, y: motion.deltaY), rules: rules, enabled: true).shortcut == nil)
        #expect(matcher.pointerGestureSource == nil)
        #expect(matcher.handle(event(.drag, x: -100, at: 2), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(event(.up, at: 3), rules: rules, enabled: true).suppress)
    }

    @Test func perpendicularNoiseAtDominanceBoundaryIsAllowed() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        #expect(matcher.handle(event(.drag, x: -50, y: 25), rules: rules, enabled: true).shortcut == output)
    }

    @Test(arguments: [InputEvent.Phase.down, .modifiersChanged, .scroll, .drag])
    func interruptionsKeepReleaseOwnershipButRestoreMotion(_ phase: InputEvent.Phase) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        var interruption = event(phase, button: 0, modifiers: [])
        if phase == .down { interruption.trigger = .key(2) }
        if phase == .scroll { interruption.trigger = .scroll(.up) }
        #expect(matcher.handle(interruption, rules: rules, enabled: true).suppress == false)
        #expect(matcher.pointerGestureSource == nil)
        #expect(matcher.handle(event(.drag, x: -100, at: 2), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(event(.up, at: 3), rules: rules, enabled: true).suppress)
    }

    @Test func pauseQueueDenialAndExplicitCancellationDoNotDeliverLater() {
        for mode in 0..<3 {
            var matcher = InputMatcher()
            let rules = InputMatcher.compile([binding()])
            _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
            if mode == 2 { matcher.cancelPendingActivation() }
            #expect(matcher.handle(event(.drag, x: -50), rules: rules, enabled: mode != 0, canDispatch: mode != 1).shortcut == nil)
            #expect(matcher.handle(event(.drag, x: -50, at: 2), rules: rules, enabled: true).suppress == false)
            #expect(matcher.handle(event(.up, at: 3), rules: rules, enabled: false).suppress)
        }
    }

    @Test func timeoutAndRegressedClockRestoreMotionWithoutFiring() {
        for time in [UInt64(9), 10 + InputMatcher.pointerTimeoutNanoseconds + 1] {
            var matcher = InputMatcher()
            let rules = InputMatcher.compile([binding()])
            _ = matcher.handle(event(.down, at: 10), rules: rules, enabled: true)
            matcher.expirePointerGesture(at: time)
            #expect(matcher.pointerGestureSource == nil)
            #expect(matcher.handle(event(.drag, x: -100, at: time), rules: rules, enabled: true).suppress == false)
            #expect(matcher.handle(event(.up, at: time), rules: rules, enabled: true).suppress)
        }
    }

    @Test func deadlineBoundaryStillRecognizesAndFiredCaptureAlsoExpires() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        matcher.expirePointerGesture(at: InputMatcher.pointerTimeoutNanoseconds)
        #expect(matcher.handle(event(.drag, x: -50, at: InputMatcher.pointerTimeoutNanoseconds), rules: rules, enabled: true).shortcut == output)
        matcher.expirePointerGesture(at: InputMatcher.pointerTimeoutNanoseconds + 1)
        #expect(matcher.pointerGestureSource == nil)
    }

    @Test(arguments: [Int64.min, Int64.max, -4097, 4097])
    func extremeMovementFailsSafelyWithoutIntegerOverflow(_ x: Int64) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        #expect(matcher.handle(event(.drag, x: x), rules: rules, enabled: true).shortcut == nil)
        #expect(matcher.pointerGestureSource == nil)
        #expect(matcher.handle(event(.up, at: 2), rules: rules, enabled: true).suppress)
    }

    @Test func taggedFeedbackDoesNotInterruptButDuplicateDownDoes() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        var feedback = InputEvent(trigger: .key(0), modifiers: .command, phase: .down, isSynthetic: true)
        #expect(matcher.handle(feedback, rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(event(.drag, x: -10), rules: rules, enabled: true).shortcut == nil)
        feedback = event(.down, at: 2)
        #expect(matcher.handle(feedback, rules: rules, enabled: true).suppress)
        #expect(matcher.handle(event(.drag, x: -50, at: 3), rules: rules, enabled: true).shortcut == nil)
        #expect(matcher.pointerGestureSource == nil)
    }

    @Test func captureLossDropsSourceAndDoesNotRetainMotion() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([binding()])
        _ = matcher.handle(event(.down, at: 0), rules: rules, enabled: true)
        matcher.resetAfterCaptureLoss()
        #expect(matcher.pointerGestureSource == nil)
        #expect(matcher.hasSuppressedInput == false)
        #expect(matcher.handle(event(.up), rules: rules, enabled: true).suppress == false)
    }
}
