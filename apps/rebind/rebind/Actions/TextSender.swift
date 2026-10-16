import CoreGraphics

/// Types configured text as tagged Unicode key events, so Rebind's own rules ignore it.
nonisolated enum TextSender {
    /// Quartz carries at most 20 UTF-16 units per key event.
    static let unitsPerEvent = 20

    static func perform(_ text: String, canPerform: () -> Bool,
                        post: (CGEvent) -> Void = { $0.post(tap: .cgSessionEventTap) }) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard TextSnippet.isValid(text), let source = CGEventSource(stateID: .privateState) else { return .unavailable }
        var batch: [CGEvent] = []
        for chunk in chunks(of: text) {
            for keyDown in [true, false] {
                guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: keyDown) else { return .unavailable }
                event.flags = [] // Plain text; do not inherit trigger or physical modifiers.
                event.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
                event.setIntegerValueField(.eventSourceUserData, value: ShortcutSender.eventTag)
                batch.append(event)
            }
        }
        // Recheck between chunks, but always finish an accepted down/up pair.
        for index in stride(from: 0, to: batch.count, by: 2) {
            guard canPerform() else { return .cancelled }
            post(batch[index])
            post(batch[index + 1])
        }
        return .performed
    }

    /// Prefer grapheme boundaries; unusually long graphemes split only between Unicode scalars.
    /// Quartz's hard unit limit still applies to combining sequences longer than one event.
    static func chunks(of text: String) -> [[UniChar]] {
        var result: [[UniChar]] = []
        var current: [UniChar] = []
        for character in text {
            let units = Array(String(character).utf16)
            if units.count > unitsPerEvent {
                if !current.isEmpty { result.append(current); current = [] }
                for scalar in String(character).unicodeScalars {
                    let scalarUnits = Array(String(scalar).utf16)
                    if current.count + scalarUnits.count > unitsPerEvent {
                        result.append(current)
                        current = []
                    }
                    current.append(contentsOf: scalarUnits)
                }
                continue
            }
            if !current.isEmpty, current.count + units.count > unitsPerEvent {
                result.append(current)
                current = []
            }
            current.append(contentsOf: units)
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}
