import IOKit.hidsystem

nonisolated enum MediaAction: String, Codable, CaseIterable, Sendable {
    case playPause, nextTrack, previousTrack, fastForward, rewind
    /// Display brightness uses the same auxiliary system-key path as the media keys.
    case brightnessUp, brightnessDown

    var isBrightness: Bool { self == .brightnessUp || self == .brightnessDown }

    var keyCode: Int {
        switch self {
        case .fastForward: Int(NX_KEYTYPE_FAST)
        case .rewind: Int(NX_KEYTYPE_REWIND)
        case .playPause: Int(NX_KEYTYPE_PLAY)
        case .nextTrack: Int(NX_KEYTYPE_NEXT)
        case .previousTrack: Int(NX_KEYTYPE_PREVIOUS)
        case .brightnessUp: Int(NX_KEYTYPE_BRIGHTNESS_UP)
        case .brightnessDown: Int(NX_KEYTYPE_BRIGHTNESS_DOWN)
        }
    }
}
