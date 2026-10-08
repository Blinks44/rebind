import Foundation

extension ActionKind {
    var title: LocalizedStringResource {
        switch self {
        case .keyboardShortcut: .outputShortcut
        case .volumeUp: .volumeUpAction
        case .volumeDown: .volumeDownAction
        case .toggleMute: .toggleMuteAction
        case .closeWindow: .closeWindowAction
        case .minimizeWindow: .minimizeWindowAction
        case .toggleFullScreen: .toggleFullScreenAction
        case .hideApplication: .hideApplicationAction
        case .openApplication: .openApplicationAction
        case .activateApplication: .activateApplicationAction
        case .openURL: .openURLAction
        case .openFile: .openFileAction
        }
    }
}

extension ActionKind.Category {
    var title: LocalizedStringResource {
        switch self {
        case .keyboard: .keyboardActions
        case .audio: .audioActions
        case .windows: .windowActions
        }
    }
}

extension RebindAction {
    var label: String {
        switch self {
        case .shortcut(let shortcut): return InputLabels.shortcut(shortcut)
        case .system, .window: return String(localized: ActionKind(action: self).title)
        case .workspace(let action):
            let detail: String
            if case .openURL(let url) = action { detail = url.host ?? "" }
            else { detail = action.url.lastPathComponent }
            return "\(String(localized: ActionKind(action: self).title)) — \(detail)"
        }
    }
}
