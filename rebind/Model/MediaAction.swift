import IOKit.hidsystem

nonisolated enum MediaAction: String, Codable, CaseIterable, Sendable {
    case playPause, nextTrack, previousTrack

    var keyCode: Int {
        switch self {
        case .playPause: Int(NX_KEYTYPE_PLAY)
        case .nextTrack: Int(NX_KEYTYPE_NEXT)
        case .previousTrack: Int(NX_KEYTYPE_PREVIOUS)
        }
    }
}
