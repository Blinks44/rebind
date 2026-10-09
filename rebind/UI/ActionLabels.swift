import Foundation

extension ActionKind {
    var title: LocalizedStringResource {
        switch self {
        case .keyboardShortcut: .outputShortcut
        case .leftClick: .leftClickAction
        case .rightClick: .rightClickAction
        case .middleClick: .middleClickAction
        case .doubleLeftClick: .doubleLeftClickAction
        case .volumeUp: .volumeUpAction
        case .volumeDown: .volumeDownAction
        case .toggleMute: .toggleMuteAction
        case .playPause: .playPauseAction
        case .nextTrack: .nextTrackAction
        case .previousTrack: .previousTrackAction
        case .leftHalf: .leftHalfAction
        case .rightHalf: .rightHalfAction
        case .fillWindow: .fillWindowAction
        case .centerWindow: .centerWindowAction
        case .closeWindow: .closeWindowAction
        case .minimizeWindow: .minimizeWindowAction
        case .toggleFullScreen: .toggleFullScreenAction
        case .hideApplication: .hideApplicationAction
        case .openApplication: .openApplicationAction
        case .activateApplication: .activateApplicationAction
        case .openURL: .openURLAction
        case .openFile: .openFileAction
        case .runAppleShortcut: .runAppleShortcutAction
        case .missionControl: .missionControlAction
        case .applicationWindows: .applicationWindowsAction
        case .showDesktop: .showDesktopAction
        case .previousSpace: .previousSpaceAction
        case .nextSpace: .nextSpaceAction
        }
    }
}

extension ActionKind.Category {
    var title: LocalizedStringResource {
        switch self {
        case .keyboard: .keyboardActions
        case .mouse: .mouseActions
        case .audio: .audioActions
        case .windows: .windowActions
        case .automation: .automationActions
        case .desktop: .desktopActions
        }
    }
}

extension RebindAction {
    var label: String {
        switch self {
        case .shortcut(let shortcut): return InputLabels.shortcut(shortcut)
        case .mouse, .media, .system, .window, .windowLayout, .dock: return String(localized: ActionKind(action: self).title)
        case .appleShortcut(let target): return "\(String(localized: .runAppleShortcutAction)) — \(target.name)"
        case .desktop(_, let shortcut): return "\(String(localized: ActionKind(action: self).title)) — \(InputLabels.shortcut(shortcut))"
        case .workspace(let action):
            let detail: String
            if case .openURL(let url) = action { detail = url.host ?? "" }
            else { detail = action.url.lastPathComponent }
            return "\(String(localized: ActionKind(action: self).title)) — \(detail)"
        }
    }
}
