import CoreGraphics

nonisolated enum ShortcutSender {
    // Only our events carry this tag. Other apps' synthetic input remains eligible.
    static let eventTag: Int64 = 0x524542494E443031

    static func events(for shortcut: KeyboardShortcut) -> [CGEvent]? {
        guard shortcut.isSupported,
              let source = CGEventSource(stateID: .privateState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: false) else {
            return nil
        }
        // Encode shortcut modifiers on the balanced key pair rather than posting
        // modifier key-downs that could overwrite physically held modifier state.
        // This slice sends a pulse once per press; it does not synthesize held keys.
        for event in [down, up] {
            event.flags = shortcut.modifiers.flags
            event.setIntegerValueField(.eventSourceUserData, value: eventTag)
        }
        return [down, up]
    }

    static func send(_ shortcut: KeyboardShortcut) -> Bool {
        guard let events = events(for: shortcut) else { return false }
        for event in events { event.post(tap: .cgSessionEventTap) }
        // Quartz has no delivery acknowledgement; protected targets need manual validation.
        return true
    }
}
