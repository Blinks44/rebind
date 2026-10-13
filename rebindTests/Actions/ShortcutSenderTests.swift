import CoreGraphics
import Testing
@testable import rebind

struct ShortcutSenderTests {
    @Test func shortcutIsBalancedTaggedAndUsesExactOutputFlags() throws {
        let output = KeyboardShortcut(keyCode: 13, modifiers: [.command, .shift])
        let events = try #require(ShortcutSender.events(for: output))
        #expect(events.count == 2)
        #expect(events.map(\.type) == [.keyDown, .keyUp])
        for event in events {
            #expect(event.flags == output.modifiers.flags)
            #expect(event.getIntegerValueField(.keyboardEventKeycode) == 13)
            #expect(event.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag)
        }
        // Construct only; this test never posts global input.
    }

    @Test func unsupportedOutputProducesNoEvents() {
        #expect(ShortcutSender.events(for: KeyboardShortcut(keyCode: 57, modifiers: [])) == nil)
    }
}
