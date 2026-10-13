/// Text a rule types into the app in front. It is user-authored configuration, never captured input.
nonisolated enum TextSnippet {
    static let maximumLength = 500

    static func isValid(_ text: String) -> Bool {
        !text.isEmpty && text.count <= maximumLength
            && !text.unicodeScalars.contains { $0.properties.generalCategory == .control }
    }
}
