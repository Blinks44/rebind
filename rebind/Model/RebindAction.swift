nonisolated enum RebindAction: Codable, Equatable, Sendable {
    case shortcut(KeyboardShortcut)
    case system(SystemAction)
    case window(WindowAction)
    case workspace(WorkspaceAction)

    var shortcut: KeyboardShortcut? {
        if case .shortcut(let value) = self { return value }
        return nil
    }

    var isSupported: Bool {
        switch self {
        case .shortcut(let value): value.isSupported
        case .system, .window: true
        case .workspace(let action): action.isSupported
        }
    }
}
