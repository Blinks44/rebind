import AppKit
import IOKit.hidsystem

// System media keys target the player selected by macOS, not the foreground app;
// sound keys target the default output.
// Quartz posting has no acknowledgement of playback or an eligible recipient.
nonisolated enum MediaKeySender {
    static func perform(_ action: MediaAction, canPerform: () -> Bool,
                        build: (MediaAction) -> [CGEvent]? = { events($0) },
                        post: (CGEvent, CGEventTapLocation) -> Void = { $0.post(tap: $1) }) -> WindowActionResult {
        perform(canPerform: canPerform, build: { build(action) }, post: post)
    }

    /// Sound keys let macOS change the output volume/mute exactly like its own keys,
    /// including unmuting on a volume step and showing the system volume HUD.
    static func perform(_ action: SystemAction, canPerform: () -> Bool,
                        post: (CGEvent, CGEventTapLocation) -> Void = { $0.post(tap: $1) }) -> WindowActionResult {
        perform(canPerform: canPerform, build: { events(action) }, post: post)
    }

    static func events(_ action: MediaAction,
                       source: () -> CGEventSource? = { CGEventSource(stateID: .privateState) },
                       make: (MediaAction, Bool) -> CGEvent? = { makeEvent($0.keyCode, down: $1) }) -> [CGEvent]? {
        pair(source: source, make: { make(action, $0) })
    }

    static func events(_ action: SystemAction) -> [CGEvent]? {
        pair(source: { CGEventSource(stateID: .privateState) }, make: { makeEvent(action.keyCode, down: $0) })
    }

    private static func perform(canPerform: () -> Bool, build: () -> [CGEvent]?,
                                post: (CGEvent, CGEventTapLocation) -> Void) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard let pair = build() else { return .unavailable }
        guard canPerform() else { return .cancelled }
        // Once down is posted, always finish up even if the generation changes.
        for event in pair { post(event, .cghidEventTap) }
        return .performed
    }

    private static func pair(source: () -> CGEventSource?, make: (Bool) -> CGEvent?) -> [CGEvent]? {
        guard let source = source(), let down = make(true), let up = make(false) else { return nil }
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

    private static func makeEvent(_ keyCode: Int, down: Bool) -> CGEvent? {
        let state = Int(down ? NX_KEYDOWN : NX_KEYUP) << 8
        // IOKit's auxiliary-control subtype uses key type in the high word,
        // down/up in the next byte, and repeat in the low byte (zero here).
        return NSEvent.otherEvent(with: .systemDefined, location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(state)), timestamp: 0,
            windowNumber: 0, context: nil, subtype: Int16(NX_SUBTYPE_AUX_CONTROL_BUTTONS),
            data1: keyCode << 16 | state, data2: -1)?.cgEvent
    }
}
