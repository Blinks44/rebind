import Foundation

nonisolated enum ActionKind: String, CaseIterable, Identifiable, Sendable {
    case keyboardShortcut, volumeUp, volumeDown, toggleMute
    case closeWindow, minimizeWindow, toggleFullScreen, hideApplication
    case openApplication, activateApplication, openURL, openFile
    var id: Self { self }

    enum Category: CaseIterable, Identifiable {
        case keyboard, audio, windows
        var id: Self { self }
    }

    var category: Category {
        if systemAction != nil { return .audio }
        if windowAction != nil { return .windows }
        if needsWorkspaceParameters { return .windows }
        return .keyboard
    }

    init(action: RebindAction) {
        switch action {
        case .shortcut: self = .keyboardShortcut
        case .system(.volumeUp): self = .volumeUp
        case .system(.volumeDown): self = .volumeDown
        case .system(.toggleMute): self = .toggleMute
        case .window(.close): self = .closeWindow
        case .window(.minimize): self = .minimizeWindow
        case .window(.toggleFullScreen): self = .toggleFullScreen
        case .window(.hideApplication): self = .hideApplication
        case .workspace(.openApplication): self = .openApplication
        case .workspace(.activateApplication): self = .activateApplication
        case .workspace(.openURL): self = .openURL
        case .workspace(.openFile): self = .openFile
        }
    }

    var systemAction: SystemAction? {
        switch self {
        case .keyboardShortcut, .closeWindow, .minimizeWindow, .toggleFullScreen, .hideApplication,
             .openApplication, .activateApplication, .openURL, .openFile: nil
        case .volumeUp: .volumeUp
        case .volumeDown: .volumeDown
        case .toggleMute: .toggleMute
        }
    }

    var windowAction: WindowAction? {
        switch self {
        case .closeWindow: .close
        case .minimizeWindow: .minimize
        case .toggleFullScreen: .toggleFullScreen
        case .hideApplication: .hideApplication
        default: nil
        }
    }

    var needsWorkspaceParameters: Bool {
        switch self {
        case .openApplication, .activateApplication, .openURL, .openFile: true
        default: false
        }
    }

    func configuredAction(shortcut: KeyboardShortcut?, application: ApplicationTarget? = nil,
                          webAddress: String = "", file: URL? = nil) -> RebindAction? {
        if let systemAction { return .system(systemAction) }
        if let windowAction { return .window(windowAction) }
        if needsWorkspaceParameters {
            let action: WorkspaceAction
            switch self {
            case .openApplication:
                guard let application else { return nil }
                action = .openApplication(application)
            case .activateApplication:
                guard let application else { return nil }
                action = .activateApplication(application)
            case .openURL:
                guard let url = WorkspaceAction.webURL(webAddress) else { return nil }
                action = .openURL(url)
            case .openFile:
                guard let file else { return nil }
                action = .openFile(file)
            default: return nil
            }
            return action.isSupported ? .workspace(action) : nil
        }
        guard let shortcut, shortcut.isSupported else { return nil }
        return .shortcut(shortcut)
    }

    func isAvailable(with capabilities: AudioOutputCapabilities) -> Bool {
        systemAction.map(capabilities.supports) ?? true
    }
}
