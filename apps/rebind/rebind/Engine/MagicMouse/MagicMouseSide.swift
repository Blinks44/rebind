/// The half of the Magic Mouse surface a one-finger tap lands on.
nonisolated enum MagicMouseSide: String, CaseIterable, Codable, Hashable, Sendable {
    case left, right

    // Native normalized X grows to the right. A tap near the middle belongs to neither side,
    // so it falls back to the ordinary one-finger tap instead of guessing.
    static func containing(x: Float) -> Self? {
        guard x.isFinite, (0...1).contains(x) else { return nil }
        if x <= 0.4 { return .left }
        if x >= 0.6 { return .right }
        return nil
    }
}
