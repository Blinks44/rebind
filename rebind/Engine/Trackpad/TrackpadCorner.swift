// Corner bounds adapted from Sanne's MIT CornerTapRecognizer.region(at:).
// Copyright (c) 2026 Sanne contributors. See Resources/ThirdPartyNotices.txt.
nonisolated enum TrackpadCorner: String, CaseIterable, Codable, Hashable, Sendable {
    case topLeft, topRight, bottomLeft, bottomRight

    // Native normalized trackpad Y increases toward the top, unlike Quartz Y.
    static func containing(x: Float, y: Float) -> Self? {
        guard x.isFinite, y.isFinite, (0...1).contains(x), (0...1).contains(y) else { return nil }
        let edge: Float = 0.22
        if x <= edge, y >= 1 - edge { return .topLeft }
        if x >= 1 - edge, y >= 1 - edge { return .topRight }
        if x <= edge, y <= edge { return .bottomLeft }
        if x >= 1 - edge, y <= edge { return .bottomRight }
        return nil
    }
}
