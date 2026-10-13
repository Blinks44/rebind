nonisolated enum RebindAction: Codable, Equatable, Sendable {
    case shortcut(KeyboardShortcut)
    case mouse(MouseAction)
    case media(MediaAction)
    case system(SystemAction)
    case sleepSystem
    case lockScreen
    case window(WindowAction)
    case windowLayout(WindowLayoutAction)
    case windowCycle(WindowCycleAction)
    case workspace(WorkspaceAction)
    case appleShortcut(AppleShortcutTarget)
    // Read-only legacy payload for schema-11/12 migration.
    case desktop(DesktopAction, shortcut: KeyboardShortcut)
    case dock(DesktopAction)
    /// Swallows the trigger and sends nothing.
    case doNothing
    case control(ControlAction)
    case text(String)

    var shortcut: KeyboardShortcut? {
        if case .shortcut(let value) = self { return value }
        return nil
    }

    /// A shortcut stays pressed; these step actions repeat. Other actions run once.
    var canBeHeld: Bool {
        switch self {
        case .shortcut: true
        case .system(let action): action != .toggleMute
        case .media(let action): action.isBrightness
        case .mouse(let action): action.scrollLines != nil
        default: false
        }
    }

    var isSupported: Bool {
        switch self {
        case .shortcut(let value): value.isSupported
        case .mouse, .media, .system, .sleepSystem, .lockScreen, .window, .windowLayout, .windowCycle,
             .doNothing, .control: true
        case .text(let text): TextSnippet.isValid(text)
        case .workspace(let action): action.isSupported
        case .appleShortcut(let target): target.isSupported
        case .desktop: false
        case .dock: true
        }
    }
}
