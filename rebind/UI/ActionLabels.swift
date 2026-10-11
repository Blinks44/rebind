import Foundation

extension ActionKind {
    var unavailableMessage: LocalizedStringResource {
        if self == .lockScreen { return .lockScreenUnavailable }
        if self == .sleepSystem { return .sleepSystemUnavailable }
        if let desktopAction { return desktopAction.isSpaceNavigation ? .spaceActionUnavailable : .dockActionUnavailable }
        return .audioActionUnavailable
    }

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
        case .nextWindow: .nextWindowAction
        case .previousWindow: .previousWindowAction
        case .previousApplication: .previousApplicationAction
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
        case .quitApplication: .quitApplicationAction
        case .lockScreen: .lockScreenAction
        case .sleepSystem: .sleepSystemAction
        case .openSystemSettings: .openSystemSettingsAction
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
        case .system: .systemActions
        case .desktop: .desktopActions
        }
    }
}

extension RebindAction {
    var label: String {
        switch self {
        case .shortcut(let shortcut): return InputLabels.shortcut(shortcut)
        case .mouse, .media, .system, .sleepSystem, .lockScreen, .window, .windowLayout, .windowCycle, .dock: return AppLocalization.string(ActionKind(action: self).title)
        case .appleShortcut(let target): return "\(AppLocalization.string(.runAppleShortcutAction)) — \(target.name)"
        case .desktop(_, let shortcut): return "\(AppLocalization.string(ActionKind(action: self).title)) — \(InputLabels.shortcut(shortcut))"
        case .workspace(let action):
            let detail: String
            if case .openURL(let url) = action { detail = url.host ?? "" }
            else if let url = action.url { detail = url.lastPathComponent }
            else { return AppLocalization.string(ActionKind(action: self).title) }
            return "\(AppLocalization.string(ActionKind(action: self).title)) — \(detail)"
        }
    }
}
