nonisolated struct KeyboardShortcut: Codable, Hashable, Sendable {
    var keyCode: UInt16
    var modifiers: ModifierSet

    var isSupported: Bool {
        Self.isSupportedKey(keyCode) && modifiers.subtracting(.supported).isEmpty
    }

    static func isSupportedKey(_ code: UInt16) -> Bool {
        // Modifier-only, Caps Lock and Fn require different lifecycle semantics.
        code < 128 && ![54, 55, 56, 57, 58, 59, 60, 61, 62, 63].contains(code)
    }
}
