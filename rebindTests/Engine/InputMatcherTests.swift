import Testing
@testable import rebind

struct InputMatcherTests {
    private let output = KeyboardShortcut(keyCode: 13, modifiers: .command)

    private func rule(_ trigger: InputTrigger = .key(0), modifiers: ModifierSet = .control) -> rebind.Binding {
        rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: modifiers, action: .shortcut(output))
    }

    @Test(arguments: [ModifierSet(), .control, [.control, .option], [.control, .shift], .command, [.control, .function]])
    func exactModifiers(_ modifiers: ModifierSet) {
        var matcher = InputMatcher()
        let result = matcher.handle(InputEvent(trigger: .key(0), modifiers: modifiers, phase: .down),
                                    rules: InputMatcher.compile([rule()]), enabled: true)
        #expect(result.suppress == (modifiers == .control))
        #expect(result.shortcut == (modifiers == .control ? output : nil))
    }

    @Test func releaseUsesPressOwnershipAfterModifierChangeAndPause() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([rule()])
        #expect(matcher.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), rules: rules, enabled: true).suppress)
        let repeatResult = matcher.handle(InputEvent(trigger: .key(0), phase: .down, isRepeat: true), rules: [:], enabled: false)
        #expect(repeatResult.suppress)
        #expect(repeatResult.shortcut == nil)
        #expect(matcher.handle(InputEvent(trigger: .key(0), phase: .up), rules: [:], enabled: false).suppress)
        #expect(matcher.handle(InputEvent(trigger: .key(0), phase: .up), rules: rules, enabled: true).suppress == false)
    }

    @Test func pressThatPassedThroughNeverRemapsMidHold() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([rule()])
        #expect(matcher.handle(InputEvent(trigger: .key(0), phase: .down), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down, isRepeat: true), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .up), rules: rules, enabled: true).suppress == false)
    }

    @Test(arguments: [UInt32(3), 4, 8, 31, 1000, .max])
    func mouseHasNoFixedMaximum(_ number: UInt32) {
        var matcher = InputMatcher()
        let trigger = InputTrigger.mouseButton(number)
        let rules = InputMatcher.compile([rule(trigger)])
        #expect(matcher.handle(InputEvent(trigger: trigger, phase: .down), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(InputEvent(trigger: trigger, modifiers: .control, phase: .down), rules: rules, enabled: true).shortcut == output)
        #expect(matcher.handle(InputEvent(trigger: trigger, phase: .drag), rules: rules, enabled: true).suppress)
        #expect(matcher.handle(InputEvent(trigger: trigger, phase: .up), rules: rules, enabled: false).suppress)
    }

    @Test func conflictsAndDisabledRulesFailOpen() {
        let first = rule()
        var second = first
        second.id = .init()
        #expect(InputMatcher.compile([first, second]).isEmpty)
        second.isEnabled = false
        #expect(InputMatcher.compile([first, second])[first.matchKey]?.shortcut == output)
        var invalid = first
        invalid.scope = .allMice
        #expect(InputMatcher.compile([invalid]).isEmpty)
    }

    @Test func taggedSyntheticReleaseCannotReleasePhysicalSuppression() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([rule()])
        _ = matcher.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), rules: rules, enabled: true)
        #expect(matcher.handle(InputEvent(trigger: .key(0), phase: .up, isSynthetic: true), rules: rules, enabled: true).suppress == false)
        #expect(matcher.handle(InputEvent(trigger: .key(0), phase: .up), rules: rules, enabled: true).suppress)
    }

    @Test func overflowAndCaptureLossFailOpen() {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([rule()])
        let down = InputEvent(trigger: .key(0), modifiers: .control, phase: .down)
        #expect(matcher.handle(down, rules: rules, enabled: true, canDispatch: false).suppress == false)
        #expect(matcher.handle(InputEvent(trigger: .key(0), phase: .up), rules: rules, enabled: true).suppress == false)
        _ = matcher.handle(down, rules: rules, enabled: true)
        matcher.resetAfterCaptureLoss()
        #expect(matcher.handle(InputEvent(trigger: .key(0), phase: .up), rules: rules, enabled: false).suppress == false)
    }

    @Test func emergencyComboAlwaysWins() {
        var matcher = InputMatcher()
        let emergency = MatchKey.emergencyBypass
        #expect(rule(emergency.trigger, modifiers: emergency.modifiers).isValid == false)
        let result = matcher.handle(InputEvent(trigger: emergency.trigger, modifiers: emergency.modifiers, phase: .down), rules: [:], enabled: false)
        #expect(result.emergencyPause)
        #expect(result.shortcut == nil)
        #expect(result.suppress)
    }
}
