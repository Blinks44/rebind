import AppKit
import IOKit.hidsystem

// System media keys target the player selected by macOS, not the foreground app.
// Quartz posting has no acknowledgement of playback or an eligible recipient.
nonisolated enum MediaKeySender {
    static func perform(_ action: MediaAction, canPerform: () -> Bool,
                        build: (MediaAction) -> [CGEvent]? = { events($0) },
                        post: (CGEvent, CGEventTapLocation) -> Void = { $0.post(tap: $1) }) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard let pair = build(action) else { return .unavailable }
        guard canPerform() else { return .cancelled }
        // Once down is posted, always finish up even if the generation changes.
        for event in pair { post(event, .cghidEventTap) }
        return .performed
    }

    static func events(_ action: MediaAction,
                       source: () -> CGEventSource? = { CGEventSource(stateID: .privateState) },
                       make: (MediaAction, Bool) -> CGEvent? = { makeEvent($0, down: $1) }) -> [CGEvent]? {
        guard let source = source(), let down = make(action, true), let up = make(action, false) else { return nil }
        source.localEventsSuppressionInterval = 0
        for (event, state) in [(down, NX_KEYDOWN), (up, NX_KEYUP)] {
            event.setSource(source)
            // Auxiliary-event phase bits, not Command/Control/Option/etc.
            // Never inherit physical modifiers from the source trigger.
            event.flags = CGEventFlags(rawValue: UInt64(state) << 8)
            event.setIntegerValueField(.eventSourceUserData, value: ShortcutSender.eventTag)
        }
        return [down, up]
    }

    private static func makeEvent(_ action: MediaAction, down: Bool) -> CGEvent? {
        let state = Int(down ? NX_KEYDOWN : NX_KEYUP) << 8
        // IOKit's auxiliary-control subtype uses key type in the high word,
        // down/up in the next byte, and repeat in the low byte (zero here).
        return NSEvent.otherEvent(with: .systemDefined, location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(state)), timestamp: 0,
            windowNumber: 0, context: nil, subtype: Int16(NX_SUBTYPE_AUX_CONTROL_BUTTONS),
            data1: action.keyCode << 16 | state, data2: -1)?.cgEvent
    }
}
