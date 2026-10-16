/// Text a rule types into the app in front. It is user-authored configuration, never captured input.
nonisolated enum TextSnippet {
    static let maximumLength = 500
    /// Bound event construction even when a single grapheme contains thousands of combining marks.
    static let maximumUTF16Length = maximumLength * 20

    static func isValid(_ text: String) -> Bool {
        !text.isEmpty && text.utf16.count <= maximumUTF16Length && text.count <= maximumLength
            && !text.unicodeScalars.contains { $0.properties.generalCategory == .control }
    }
}
