/// How long one wheel click glides once smooth scrolling turns it into continuous movement.
nonisolated enum SmoothScrollingGlide: String, Codable, CaseIterable, Hashable, Sendable {
    case short, standard, long

    /// Time constant of the ease-out: about 95 % of the distance is covered after three of them.
    var timeConstant: Double {
        switch self {
        case .short: 0.05
        case .standard: 0.09
        case .long: 0.15
        }
    }
}

/// Which mouse wheels smooth scrolling changes.
nonisolated enum SmoothScrollingScope: String, Codable, CaseIterable, Hashable, Sendable {
    /// Only wheels that click step by step; high-resolution wheels already scroll smoothly.
    case steppedWheels
    case allWheels
}

/// The smooth scrolling choice the event tap applies.
nonisolated struct SmoothScrollingSettings: Equatable, Sendable {
    var glide: SmoothScrollingGlide
    var scope: SmoothScrollingScope
}
