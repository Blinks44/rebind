nonisolated enum WindowLayoutAction: String, Codable, CaseIterable, Hashable, Sendable {
    case leftHalf, rightHalf, fill, center, fillWithStageManager
    case topHalf, bottomHalf, topLeft, topRight, bottomLeft, bottomRight
    /// Moves the window to the next display, keeping its size where it fits.
    case nextDisplay

    var isNewInSchema34: Bool { ![.leftHalf, .rightHalf, .fill, .center].contains(self) }
    /// These keep the window's size and only need a movable window.
    var keepsSize: Bool { self == .center }
}
