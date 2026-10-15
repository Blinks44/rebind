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

/// How far one wheel click glides, in points per line of an accelerated click. A stepped
/// click reports only about 10 points, while apps scroll a line much further, so the glide
/// sets its own distance.
nonisolated enum SmoothScrollingDistance {
    static let range = 20...400
    static let step = 10
    static let standard = 50
}

/// The smooth scrolling choice the event tap applies.
nonisolated struct SmoothScrollingSettings: Equatable, Sendable {
    var glide: SmoothScrollingGlide
    var pointsPerLine = Double(SmoothScrollingDistance.standard)
}
