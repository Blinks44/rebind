import IOKit.hidsystem

nonisolated enum SystemAction: String, Codable, CaseIterable, Hashable, Sendable {
    case volumeUp, volumeDown, toggleMute

    var keyCode: Int {
        switch self {
        case .volumeUp: Int(NX_KEYTYPE_SOUND_UP)
        case .volumeDown: Int(NX_KEYTYPE_SOUND_DOWN)
        case .toggleMute: Int(NX_KEYTYPE_MUTE)
        }
    }
}
