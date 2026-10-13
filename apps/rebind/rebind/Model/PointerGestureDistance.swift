/// How far the pointer travels, in points, before a held-button gesture is recognized.
nonisolated enum PointerGestureDistance: String, Codable, CaseIterable, Hashable, Sendable {
    case short, standard, long

    var points: Int64 {
        switch self {
        case .short: 30
        case .standard: 50
        case .long: 90
        }
    }
}
