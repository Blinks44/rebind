/// How many times each mouse wheel event is multiplied before apps see it.
nonisolated enum MouseWheelSpeed: String, Codable, CaseIterable, Hashable, Sendable {
    case standard, fast, faster

    var multiplier: Int64 {
        switch self {
        case .standard: 1
        case .fast: 2
        case .faster: 3
        }
    }
}

/// What the tap applies to a mouse wheel event it passes through. Nil means leave it alone.
nonisolated struct WheelAdjustment: Equatable, Sendable {
    var reverses: Bool
    var multiplier: Int64

    var factor: Int64 { (reverses ? -1 : 1) * multiplier }
}
