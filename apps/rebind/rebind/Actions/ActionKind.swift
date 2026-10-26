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
    case doNothing, pauseRebind, nextProfile, previousProfile
    case copy, paste, cut, undo, redo, selectAll, insertText
    case holdCommand, holdOption, holdControl, holdShift
    case nextTab, previousTab, newTab, reopenTab, zoomIn, zoomOut
    case screenshotScreen, screenshotArea, screenshotTools
    case topHalf, bottomHalf, topLeftQuarter, topRightQuarter, bottomLeftQuarter, bottomRightQuarter, nextDisplay
    case spotlight, forceQuitWindow, emojiSymbols, toggleDock, hideOthers, lookUp, quitFrontApplication, newWindow, find, reload, save
    case openApps, fastForward, rewind, toggleMicrophoneMute, fillWindowWithStageManager
    var id: Self { self }

    enum Category: CaseIterable, Identifiable {
        case keyboard, mouse, audio, windows, desktop, system, automation, rebind
        var id: Self { self }
    }

    var category: Category {
        if self == .doNothing || controlAction != nil { return .rebind }
        if [.copy, .paste, .cut, .undo, .redo, .selectAll, .insertText].contains(self) || modifierAction != nil { return .keyboard }
        if [.screenshotScreen, .screenshotArea, .screenshotTools, .spotlight, .forceQuitWindow, .emojiSymbols, .toggleDock, .openApps].contains(self) { return .system }
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
        case .doNothing: self = .doNothing
        case .control(.pause): self = .pauseRebind
        case .control(.nextProfile): self = .nextProfile
        case .control(.previousProfile): self = .previousProfile
        case .shortcut(let shortcut):
            self = Self.allCases.first { $0.fixedShortcut == shortcut } ?? .keyboardShortcut
        case .media(.fastForward): self = .fastForward
        case .media(.rewind): self = .rewind
        case .system(.toggleMicrophoneMute): self = .toggleMicrophoneMute
        case .workspace(.openApps): self = .openApps
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
        case .windowLayout(let layout): self = Self.allCases.first { $0.windowLayoutAction == layout } ?? .fillWindow
        case .text: self = .insertText
        case .modifier(let modifiers): self = Self.allCases.first { $0.modifierAction == modifiers } ?? .holdCommand
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

    /// Keep the repeat control editable when a held shortcut also has a catalog command name.
    init(binding: Binding) {
        if binding.holdsOutput, binding.action.shortcut != nil { self = .keyboardShortcut }
        else { self.init(action: binding.action) }
    }

    var systemAction: SystemAction? {
        switch self {
        case .volumeUp: .volumeUp
        case .volumeDown: .volumeDown
        case .toggleMicrophoneMute: .toggleMicrophoneMute
        case .toggleMute: .toggleMute
        default: nil
        }
    }

    var modifierAction: ModifierSet? {
        switch self {
        case .holdCommand: .command
        case .holdOption: .option
        case .holdControl: .control
        case .holdShift: .shift
        default: nil
        }
    }

    /// Whether "Repeat while held" applies; named shortcuts such as Back run once.
    var canBeHeld: Bool {
        self == .keyboardShortcut || [.volumeUp, .volumeDown, .brightnessUp, .brightnessDown].contains(self)
            || mouseAction?.scrollLines != nil
    }

    var controlAction: ControlAction? {
        switch self {
        case .pauseRebind: .pause
        case .nextProfile: .nextProfile
        case .previousProfile: .previousProfile
        default: nil
        }
    }

    var mouseAction: MouseAction? { MouseAction(rawValue: rawValue) }

    var mediaAction: MediaAction? {
        switch self {
        case .fastForward: .fastForward
        case .rewind: .rewind
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
        case .fillWindowWithStageManager: .fillWithStageManager
        case .fillWindow: .fill
        case .centerWindow: .center
        case .topHalf: .topHalf
        case .bottomHalf: .bottomHalf
        case .topLeftQuarter: .topLeft
        case .topRightQuarter: .topRight
        case .bottomLeftQuarter: .bottomLeft
        case .bottomRightQuarter: .bottomRight
        case .nextDisplay: .nextDisplay
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

    /// Named commands that are the standard macOS shortcut for what they do, such as ⌘[ for Back.
    var fixedShortcut: KeyboardShortcut? {
        switch self {
        case .spotlight: KeyboardShortcut(keyCode: 49, modifiers: .command)
        case .forceQuitWindow: KeyboardShortcut(keyCode: 53, modifiers: [.option, .command])
        case .emojiSymbols: KeyboardShortcut(keyCode: 49, modifiers: [.control, .command])
        case .toggleDock: KeyboardShortcut(keyCode: 2, modifiers: [.option, .command])
        case .hideOthers: KeyboardShortcut(keyCode: 4, modifiers: [.option, .command])
        case .lookUp: KeyboardShortcut(keyCode: 2, modifiers: [.control, .command])
        case .quitFrontApplication: KeyboardShortcut(keyCode: 12, modifiers: .command)
        case .newWindow: KeyboardShortcut(keyCode: 45, modifiers: .command)
        case .find: KeyboardShortcut(keyCode: 3, modifiers: .command)
        case .reload: KeyboardShortcut(keyCode: 15, modifiers: .command)
        case .save: KeyboardShortcut(keyCode: 1, modifiers: .command)
        case .navigateBack: KeyboardShortcut(keyCode: 33, modifiers: .command)
        case .navigateForward: KeyboardShortcut(keyCode: 30, modifiers: .command)
        case .copy: KeyboardShortcut(keyCode: 8, modifiers: .command)
        case .paste: KeyboardShortcut(keyCode: 9, modifiers: .command)
        case .cut: KeyboardShortcut(keyCode: 7, modifiers: .command)
        case .undo: KeyboardShortcut(keyCode: 6, modifiers: .command)
        case .redo: KeyboardShortcut(keyCode: 6, modifiers: [.command, .shift])
        case .selectAll: KeyboardShortcut(keyCode: 0, modifiers: .command)
        case .nextTab: KeyboardShortcut(keyCode: 48, modifiers: .control)
        case .previousTab: KeyboardShortcut(keyCode: 48, modifiers: [.control, .shift])
        case .newTab: KeyboardShortcut(keyCode: 17, modifiers: .command)
        case .reopenTab: KeyboardShortcut(keyCode: 17, modifiers: [.command, .shift])
        case .zoomIn: KeyboardShortcut(keyCode: 24, modifiers: .command)
        case .zoomOut: KeyboardShortcut(keyCode: 27, modifiers: .command)
        case .screenshotScreen: KeyboardShortcut(keyCode: 20, modifiers: [.command, .shift])
        case .screenshotArea: KeyboardShortcut(keyCode: 21, modifiers: [.command, .shift])
        case .screenshotTools: KeyboardShortcut(keyCode: 23, modifiers: [.command, .shift])
        default: nil
        }
    }

    func configuredAction(shortcut: KeyboardShortcut?, application: ApplicationTarget? = nil,
                          webAddress: String = "", file: URL? = nil,
                          appleShortcut: AppleShortcutTarget? = nil, text: String = "") -> RebindAction? {
        if let fixedShortcut { return .shortcut(fixedShortcut) }
        if self == .insertText { return TextSnippet.isValid(text) ? .text(text) : nil }
        if let modifierAction { return .modifier(modifierAction) }
        if self == .doNothing { return .doNothing }
        if let controlAction { return .control(controlAction) }
        if self == .lockScreen { return .lockScreen }
        if self == .sleepSystem { return .sleepSystem }
        if self == .openSystemSettings { return .workspace(.openSystemSettings) }
        if self == .openApps { return .workspace(.openApps) }
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
        if self == .openApps { return FileManager.default.fileExists(atPath: "/System/Applications/Apps.app") }
        if self == .lockScreen { return capabilities.screenLock }
        if self == .sleepSystem { return SystemSleepExecutor.isAvailable() }
        if let desktopAction { return DockActions.isAvailable(for: desktopAction) }
        return systemAction.map(capabilities.supports) ?? true
    }
}
