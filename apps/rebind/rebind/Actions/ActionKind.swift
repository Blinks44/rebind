import Foundation

nonisolated enum ActionKind: String, CaseIterable, Identifiable, Sendable {
    case keyboardShortcut, navigateBack, navigateForward, volumeUp, volumeDown, toggleMute
    case playPause, nextTrack, previousTrack
    case leftClick, rightClick, middleClick, doubleLeftClick, backClick, forwardClick
    case scrollUp, scrollDown, scrollLeft, scrollRight
    case closeWindow, minimizeWindow, toggleFullScreen, hideApplication
    case leftHalf, rightHalf, fillWindow, centerWindow
    case nextWindow, previousWindow, previousApplication
    case openApplication, activateApplication, quitApplication, openURL, openFile
    case brightnessUp, brightnessDown, openSystemSettings, sleepSystem, lockScreen
    case runAppleShortcut
    case missionControl, applicationWindows, showDesktop, previousSpace, nextSpace
    var id: Self { self }

    enum Category: CaseIterable, Identifiable {
        case keyboard, mouse, audio, windows, desktop, system, automation
        var id: Self { self }
    }

    var category: Category {
        if self == .openSystemSettings || self == .sleepSystem || self == .lockScreen
            || mediaAction?.isBrightness == true { return .system }
        if mouseAction != nil { return .mouse }
        if desktopAction != nil { return .desktop }
        if self == .runAppleShortcut { return .automation }
        if systemAction != nil || mediaAction != nil { return .audio }
        if windowAction != nil || windowLayoutAction != nil || windowCycleAction != nil { return .windows }
        if needsWorkspaceParameters || self == .previousApplication || fixedShortcut != nil { return .windows }
        return .keyboard
    }

    init(action: RebindAction) {
        switch action {
        case .lockScreen: self = .lockScreen
        case .sleepSystem: self = .sleepSystem
        case .shortcut(let shortcut):
            self = [.navigateBack, .navigateForward].first { $0.fixedShortcut == shortcut } ?? .keyboardShortcut
        case .media(.playPause): self = .playPause
        case .media(.nextTrack): self = .nextTrack
        case .media(.previousTrack): self = .previousTrack
        case .media(.brightnessUp): self = .brightnessUp
        case .media(.brightnessDown): self = .brightnessDown
        case .mouse(let action): self = Self(rawValue: action.rawValue) ?? .leftClick
        case .system(.volumeUp): self = .volumeUp
        case .system(.volumeDown): self = .volumeDown
        case .system(.toggleMute): self = .toggleMute
        case .windowCycle(.next): self = .nextWindow
        case .windowCycle(.previous): self = .previousWindow
        case .windowLayout(.leftHalf): self = .leftHalf
        case .windowLayout(.rightHalf): self = .rightHalf
        case .windowLayout(.fill): self = .fillWindow
        case .windowLayout(.center): self = .centerWindow
        case .window(.close): self = .closeWindow
        case .window(.minimize): self = .minimizeWindow
        case .window(.toggleFullScreen): self = .toggleFullScreen
        case .window(.hideApplication): self = .hideApplication
        case .workspace(.openApplication): self = .openApplication
        case .workspace(.activateApplication): self = .activateApplication
        case .workspace(.quitApplication): self = .quitApplication
        case .workspace(.previousApplication): self = .previousApplication
        case .workspace(.openSystemSettings): self = .openSystemSettings
        case .workspace(.openURL): self = .openURL
        case .workspace(.openFile): self = .openFile
        case .appleShortcut: self = .runAppleShortcut
        case .desktop(.missionControl, _): self = .missionControl
        case .desktop(.applicationWindows, _): self = .applicationWindows
        case .desktop(.showDesktop, _): self = .showDesktop
        case .desktop(.previousSpace, _): self = .previousSpace
        case .desktop(.nextSpace, _): self = .nextSpace
        case .dock(let action):
            switch action {
            case .missionControl: self = .missionControl
            case .applicationWindows: self = .applicationWindows
            case .showDesktop: self = .showDesktop
            case .previousSpace: self = .previousSpace
            case .nextSpace: self = .nextSpace
            }
        }
    }

    var systemAction: SystemAction? {
        switch self {
        case .volumeUp: .volumeUp
        case .volumeDown: .volumeDown
        case .toggleMute: .toggleMute
        default: nil
        }
    }

    var mouseAction: MouseAction? { MouseAction(rawValue: rawValue) }

    var mediaAction: MediaAction? {
        switch self {
        case .playPause: .playPause
        case .nextTrack: .nextTrack
        case .previousTrack: .previousTrack
        case .brightnessUp: .brightnessUp
        case .brightnessDown: .brightnessDown
        default: nil
        }
    }

    var windowCycleAction: WindowCycleAction? {
        switch self {
        case .nextWindow: .next
        case .previousWindow: .previous
        default: nil
        }
    }

    var windowLayoutAction: WindowLayoutAction? {
        switch self {
        case .leftHalf: .leftHalf
        case .rightHalf: .rightHalf
        case .fillWindow: .fill
        case .centerWindow: .center
        default: nil
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
        case .openApplication, .activateApplication, .quitApplication, .openURL, .openFile: true
        default: false
        }
    }

    var desktopAction: DesktopAction? {
        switch self {
        case .missionControl: .missionControl
        case .applicationWindows: .applicationWindows
        case .showDesktop: .showDesktop
        case .previousSpace: .previousSpace
        case .nextSpace: .nextSpace
        default: nil
        }
    }

    /// Back and Forward are the standard ⌘[ and ⌘] shortcuts, which most apps understand.
    var fixedShortcut: KeyboardShortcut? {
        switch self {
        case .navigateBack: KeyboardShortcut(keyCode: 33, modifiers: .command)
        case .navigateForward: KeyboardShortcut(keyCode: 30, modifiers: .command)
        default: nil
        }
    }

    func configuredAction(shortcut: KeyboardShortcut?, application: ApplicationTarget? = nil,
                          webAddress: String = "", file: URL? = nil,
                          appleShortcut: AppleShortcutTarget? = nil) -> RebindAction? {
        if let fixedShortcut { return .shortcut(fixedShortcut) }
        if self == .lockScreen { return .lockScreen }
        if self == .sleepSystem { return .sleepSystem }
        if self == .openSystemSettings { return .workspace(.openSystemSettings) }
        if self == .previousApplication { return .workspace(.previousApplication) }
        if let mouseAction { return .mouse(mouseAction) }
        if let mediaAction { return .media(mediaAction) }
        if let desktopAction { return .dock(desktopAction) }
        if self == .runAppleShortcut {
            guard let appleShortcut, appleShortcut.isSupported else { return nil }
            return .appleShortcut(appleShortcut)
        }
        if let systemAction { return .system(systemAction) }
        if let windowCycleAction { return .windowCycle(windowCycleAction) }
        if let windowLayoutAction { return .windowLayout(windowLayoutAction) }
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
            case .quitApplication:
                guard let application else { return nil }
                action = .quitApplication(application)
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
        if self == .lockScreen { return capabilities.screenLock }
        if self == .sleepSystem { return SystemSleepExecutor.isAvailable() }
        if let desktopAction { return DockActions.isAvailable(for: desktopAction) }
        return systemAction.map(capabilities.supports) ?? true
    }
}
