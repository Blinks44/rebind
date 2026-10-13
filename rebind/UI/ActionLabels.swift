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
        case .backClick: .backClickAction
        case .forwardClick: .forwardClickAction
        case .scrollUp: .scrollUpAction
        case .scrollDown: .scrollDownAction
        case .scrollLeft: .scrollLeftAction
        case .scrollRight: .scrollRightAction
        case .volumeUp: .volumeUpAction
        case .volumeDown: .volumeDownAction
        case .toggleMute: .toggleMuteAction
        case .playPause: .playPauseAction
        case .nextTrack: .nextTrackAction
        case .previousTrack: .previousTrackAction
        case .brightnessUp: .brightnessUpAction
        case .brightnessDown: .brightnessDownAction
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

extension ActionKind {
    /// SF Symbol shown on the action tile of a rule.
    var symbol: String {
        switch self {
        case .keyboardShortcut: "command"
        case .volumeUp: "speaker.wave.3"
        case .volumeDown: "speaker.wave.1"
        case .toggleMute: "speaker.slash"
        case .playPause: "playpause"
        case .nextTrack: "forward.end"
        case .previousTrack: "backward.end"
        case .brightnessUp: "sun.max"
        case .brightnessDown: "sun.min"
        case .leftClick, .rightClick, .middleClick: "cursorarrow.click"
        case .doubleLeftClick: "cursorarrow.click.2"
        case .backClick: "chevron.backward"
        case .forwardClick: "chevron.forward"
        case .scrollUp: "arrow.up"
        case .scrollDown: "arrow.down"
        case .scrollLeft: "arrow.left"
        case .scrollRight: "arrow.right"
        case .closeWindow: "xmark.square"
        case .minimizeWindow: "minus.square"
        case .toggleFullScreen: "arrow.up.left.and.arrow.down.right"
        case .hideApplication: "eye.slash"
        case .leftHalf: "rectangle.lefthalf.filled"
        case .rightHalf: "rectangle.righthalf.filled"
        case .fillWindow: "rectangle.inset.filled"
        case .centerWindow: "rectangle.center.inset.filled"
        case .nextWindow, .previousWindow, .applicationWindows: "macwindow.on.rectangle"
        case .previousApplication: "arrow.uturn.backward.square"
        case .openApplication, .activateApplication: "app"
        case .quitApplication: "xmark.app"
        case .openURL: "link"
        case .openFile: "doc"
        case .openSystemSettings: "gearshape"
        case .sleepSystem: "moon"
        case .lockScreen: "lock"
        case .runAppleShortcut: "bolt"
        case .missionControl: "rectangle.3.group"
        case .showDesktop: "desktopcomputer"
        case .previousSpace: "arrow.left.square"
        case .nextSpace: "arrow.right.square"
        }
    }
}
