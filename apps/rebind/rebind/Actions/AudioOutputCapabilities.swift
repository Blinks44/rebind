nonisolated struct AudioOutputCapabilities: Equatable, Sendable {
    var deviceID: UInt32?
    var volume = false
    var mute = false
    // Cached away from the tap; also keeps unavailable rules in passthrough.
    var screenLock = ScreenLockExecutor.isAvailable

    var inputDeviceID: UInt32?
    var microphoneMute = false

    func deviceID(for action: RebindAction) -> UInt32? {
        action == .system(.toggleMicrophoneMute) ? inputDeviceID : deviceID
    }

    func supports(_ action: SystemAction) -> Bool {
        if action == .toggleMicrophoneMute { return inputDeviceID != nil && microphoneMute }
        guard deviceID != nil else { return false }
        switch action {
        case .volumeUp, .volumeDown: return volume
        case .toggleMute: return mute
        case .toggleMicrophoneMute: return microphoneMute
        }
    }

    func supports(_ action: RebindAction) -> Bool {
        switch action {
        case .shortcut, .mouse, .media, .sleepSystem, .window, .windowLayout, .windowCycle, .workspace, .appleShortcut,
             .doNothing, .control, .text, .modifier: true
        case .lockScreen: screenLock
        case .desktop: false
        case .system(let action): supports(action)
        case .dock(let action): DockActions.isAvailable(for: action)
        }
    }
}
