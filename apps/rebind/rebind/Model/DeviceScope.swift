nonisolated enum DeviceScope: String, Codable, Hashable, Sendable {
    case allKeyboards, allMice, builtInTrackpad
    /// An external Magic Trackpad: the same gesture presets as the built-in one, with its own rules.
    case magicTrackpad

    var isTrackpad: Bool { self == .builtInTrackpad || self == .magicTrackpad }
}
