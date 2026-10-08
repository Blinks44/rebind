nonisolated enum RebindAction: Codable, Equatable, Sendable {
    case shortcut(KeyboardShortcut)

    var shortcut: KeyboardShortcut {
        switch self { case .shortcut(let value): value }
    }
}
