import CoreGraphics

// Relative Quartz movement survives a display edge and suppressed cursor updates.
// These units depend on the device/driver; they are not physical distance or points.
nonisolated struct PointerMotion: Sendable {
    var deltaX: Int64
    var deltaY: Int64

    static func from(_ event: CGEvent) -> Self {
        Self(deltaX: event.getIntegerValueField(.mouseEventDeltaX),
             deltaY: event.getIntegerValueField(.mouseEventDeltaY))
    }
}
