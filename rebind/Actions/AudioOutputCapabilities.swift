nonisolated struct AudioOutputCapabilities: Equatable, Sendable {
    var deviceID: UInt32?
    var volume = false
    var mute = false

    func supports(_ action: SystemAction) -> Bool {
        guard deviceID != nil else { return false }
        switch action {
        case .volumeUp, .volumeDown: return volume
        case .toggleMute: return mute
        }
    }

    func supports(_ action: RebindAction) -> Bool {
        switch action {
        case .shortcut, .mouse, .media, .window, .windowLayout, .workspace, .appleShortcut: true
        case .desktop: false
        case .system(let action): supports(action)
        case .dock(let action): DockActions.isAvailable(for: action)
        }
    }
}
