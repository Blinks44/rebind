import Testing
@testable import rebind

struct ScrollMatcherTests {
    private let output = KeyboardShortcut(keyCode: 13, modifiers: .command)
    private var rules: [MatchKey: CompiledBinding] {
        InputMatcher.compile(ScrollDirection.allCases.map {
            rebind.Binding(scope: .allMice, trigger: .scroll($0), modifiers: .control, action: .shortcut(output))
        })
    }

    private func scroll(_ direction: ScrollDirection = .up, at timestamp: UInt64,
                        modifiers: ModifierSet = .control) -> InputEvent {
        InputEvent(trigger: .scroll(direction), modifiers: modifiers, phase: .scroll, timestamp: timestamp)
    }

    @Test func rateLimitConsumesMappedImpulsesWithoutRepeatedOutput() {
        var matcher = InputMatcher()
        let first = matcher.handle(scroll(at: 0), rules: rules, enabled: true)
        #expect(first.shortcut == output)
        #expect(first.suppress)
        #expect(matcher.hasSuppressedInput == false)
        let limited = matcher.handle(scroll(at: 99_999_999), rules: rules, enabled: true)
        #expect(limited.suppress)
        #expect(limited.shortcut == nil)
        #expect(matcher.handle(scroll(at: 100_000_000), rules: rules, enabled: true).shortcut == output)
    }

    @Test func changingDirectionDoesNotBypassGlobalWheelRateLimit() {
        var matcher = InputMatcher()
        _ = matcher.handle(scroll(.up, at: 1), rules: rules, enabled: true)
        for direction in [ScrollDirection.down, .left, .right] {
            let limited = matcher.handle(scroll(direction, at: 2), rules: rules, enabled: true)
            #expect(limited.suppress)
            #expect(limited.shortcut == nil)
        }
    }

    @Test(arguments: [ModifierSet(), [.control, .shift], .function])
    func unmatchedModifierSetsPassThrough(_ modifiers: ModifierSet) {
        var matcher = InputMatcher()
        #expect(matcher.handle(scroll(at: 0, modifiers: modifiers), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(scroll(at: 0), rules: rules, enabled: true).shortcut == output)
    }

    @Test func pauseOverflowAndSyntheticEventsDoNotConsumeOrAdvanceTheLimiter() {
        var matcher = InputMatcher()
        #expect(matcher.handle(scroll(at: 0), rules: rules, enabled: false).suppress == false)
        #expect(matcher.handle(scroll(at: 0), rules: rules, enabled: true, canDispatch: false).suppress == false)
        var synthetic = scroll(at: 0)
        synthetic.isSynthetic = true
        #expect(matcher.handle(synthetic, rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(scroll(at: 0), rules: rules, enabled: true).shortcut == output)
    }

    @Test func outOfOrderTimestampFailsOpenAndDoesNotCorruptTheLimiter() {
        var matcher = InputMatcher()
        _ = matcher.handle(scroll(at: 200_000_000), rules: rules, enabled: true)
        #expect(matcher.handle(scroll(at: 1), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(scroll(at: 250_000_000), rules: rules, enabled: true).shortcut == nil)
        #expect(matcher.handle(scroll(at: 300_000_000), rules: rules, enabled: true).shortcut == output)
    }

    @Test func timestampBoundaryDoesNotOverflowAndResetRestoresFirstImpulse() {
        var matcher = InputMatcher()
        _ = matcher.handle(scroll(at: .max - 1), rules: rules, enabled: true)
        let limited = matcher.handle(scroll(at: .max), rules: rules, enabled: true)
        #expect(limited.suppress)
        #expect(limited.shortcut == nil)
        matcher.resetAfterCaptureLoss()
        #expect(matcher.handle(scroll(at: 0), rules: rules, enabled: true).shortcut == output)
    }

    @Test func wheelHasNoReleaseOwnershipAndCannotBeTreatedAsAPress() {
        var matcher = InputMatcher()
        let impulse = scroll(at: 0)
        matcher.consume(impulse)
        #expect(matcher.hasSuppressedInput == false)
        #expect(matcher.handle(impulse, rules: rules, enabled: true).shortcut == output)
        let invalidPress = InputEvent(trigger: .scroll(.up), modifiers: .control, phase: .down)
        #expect(matcher.handle(invalidPress, rules: rules, enabled: true).suppress == false)
    }

    @Test func wheelRateLimitDoesNotDelayKeyboardActions() {
        var matcher = InputMatcher()
        let keyboard = MatchKey(trigger: .key(0), modifiers: .control)
        var combined = rules
        combined[keyboard] = CompiledBinding(action: .shortcut(output), activation: .press)
        _ = matcher.handle(scroll(at: 0), rules: combined, enabled: true)
        #expect(matcher.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), rules: combined, enabled: true).shortcut == output)
    }
}
