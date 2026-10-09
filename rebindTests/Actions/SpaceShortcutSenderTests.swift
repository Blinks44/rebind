import CoreGraphics
import Foundation
import Testing
@testable import rebind

struct SpaceShortcutSenderTests {
    @Test(arguments: [DesktopAction.previousSpace, .nextSpace])
    func balancedHIDArrowPairHasExactControlFnFlagsAndNoInheritedOption(_ action: DesktopAction) throws {
        let events = try #require(SpaceShortcutSender.events(action, make: { source, key, down in
            #expect(source.sourceStateID == .hidSystemState)
            let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down)
            event?.flags = CGEventFlags(rawValue: CGEventFlags.maskAlternate.rawValue | 0x40)
            event?.setIntegerValueField(.keyboardEventAutorepeat, value: 1)
            return event
        }))
        #expect(events.map(\.type) == [.keyDown, .keyUp])
        #expect(events.allSatisfy { $0.flags == [.maskControl, .maskSecondaryFn]
            && $0.getIntegerValueField(.keyboardEventKeycode) == (action == .previousSpace ? 123 : 124)
            && $0.getIntegerValueField(.keyboardEventAutorepeat) == 0
            && $0.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag })
        // Only event construction: no system shortcut is executed by these tests.
    }

    @Test(arguments: [DesktopAction.previousSpace, .nextSpace])
    func absentOverridesAndEnabledDefaultEntriesUseNativeChord(_ action: DesktopAction) {
        let id = action == .previousSpace ? "79" : "81"
        let key = action == .previousSpace ? 123 : 124
        #expect(SpaceShortcutSender.usesStandardShortcut(action, preferences: nil))
        #expect(SpaceShortcutSender.usesStandardShortcut(action, preferences: [:]))
        #expect(SpaceShortcutSender.usesStandardShortcut(action, preferences: [id: ["enabled": true]]))
        for flags in [262144, 8650752] {
            #expect(SpaceShortcutSender.usesStandardShortcut(action, preferences: [id: ["enabled": true,
                "value": ["type": "standard", "parameters": [65535, key, flags]]]]))
        }
    }

    @Test func disabledCustomizedAndMalformedSettingsNeverBuildOrPostIntoAnApp() {
        let settings: [Any] = ["invalid", ["81": false], ["81": [:]],
            ["81": ["enabled": false]], ["81": ["enabled": 1]],
            ["81": ["enabled": true, "value": false]],
            ["81": ["enabled": true, "value": ["type": "other", "parameters": [65535, 124, 8650752]]]],
            ["81": ["enabled": true, "value": ["type": "standard", "parameters": [65535, 123, 8650752]]]],
            ["81": ["enabled": true, "value": ["type": "standard", "parameters": [65535, 124, 524288]]]],
            ["81": ["enabled": true, "value": ["type": "standard", "parameters": [124, 8650752]]]]]
        for value in settings {
            var builds = 0, posts = 0
            let result = SpaceShortcutSender.perform(.nextSpace, canPerform: { true }, preferences: { value },
                build: { _ in builds += 1; return nil }, post: { _, _ in posts += 1 })
            #expect(result == .unavailable && builds == 0 && posts == 0)
        }
    }

    @Test func postingUsesHIDTapAndCompletesKeyUpAfterStartedCancellation() throws {
        let pair = try #require(SpaceShortcutSender.events(.nextSpace))
        var allowed = true
        var delivered: [CGEventType] = []
        let result = SpaceShortcutSender.perform(.nextSpace, canPerform: { allowed }, preferences: { nil },
            build: { _ in pair }, post: { event, tap in
                #expect(tap == .cghidEventTap)
                delivered.append(event.type)
                allowed = false
            })
        #expect(result == .performed && delivered == [.keyDown, .keyUp])
    }

    @Test func cancellationAfterPreparationPreventsBothEvents() throws {
        let pair = try #require(SpaceShortcutSender.events(.nextSpace))
        var allowed = true, posts = 0
        let result = SpaceShortcutSender.perform(.nextSpace, canPerform: { allowed }, preferences: { nil },
            build: { _ in allowed = false; return pair }, post: { _, _ in posts += 1 })
        #expect(result == .cancelled && posts == 0)
    }

    @Test(arguments: 1...2)
    func allocationFailureNeverPostsPartialKeyPair(_ failingCall: Int) {
        var allocations = 0, posts = 0
        let result = SpaceShortcutSender.perform(.previousSpace, canPerform: { true }, preferences: { nil }, build: { action in
            SpaceShortcutSender.events(action, make: { source, key, down in
                allocations += 1
                return allocations == failingCall ? nil : CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down)
            })
        }, post: { _, _ in posts += 1 })
        #expect(result == .unavailable && posts == 0)
        #expect(SpaceShortcutSender.events(.nextSpace, source: { nil }) == nil)
    }

    @Test func invalidActionAndInitialCancellationDoNotReadSettingsOrConstructKeys() {
        var reads = 0, builds = 0, posts = 0
        for (action, allowed, expected) in [(DesktopAction.missionControl, true, WindowActionResult.unavailable),
                                          (.previousSpace, false, .cancelled)] {
            let result = SpaceShortcutSender.perform(action, canPerform: { allowed },
                preferences: { reads += 1; return nil }, build: { _ in builds += 1; return nil }, post: { _, _ in posts += 1 })
            #expect(result == expected)
        }
        #expect(reads == 0 && builds == 0 && posts == 0)
    }

    @Test(arguments: 1...12)
    func nativeSpacePayloadIsRejectedInEveryOlderSchema(_ schema: Int) throws {
        let rule = rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: [], action: .dock(.nextSpace))
        var old = Configuration(bindings: schema < 6 ? [rule] : [])
        if schema >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [rule])) }
        old.schemaVersion = schema
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }
}
