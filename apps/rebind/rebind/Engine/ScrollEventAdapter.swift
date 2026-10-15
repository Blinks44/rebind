import CoreGraphics

// A wheel impulse is not a down/up press or a touch gesture. Trackpads and the Magic Mouse
// mark every scroll event with a gesture or momentum phase; a mouse wheel never does, even
// a high-resolution one that macOS delivers as continuous (pixel) scrolling. Phased
// streams pass unchanged.
nonisolated enum ScrollEventAdapter {
    static func isMouseWheel(_ event: CGEvent) -> Bool {
        event.type == .scrollWheel
            && event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0
            && event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0
    }

    static func input(from event: CGEvent) -> InputEvent? {
        guard isMouseWheel(event),
              event.getIntegerValueField(.eventSourceUserData) != ShortcutSender.eventTag,
              event.getIntegerValueField(.scrollWheelEventDeltaAxis3) == 0 else { return nil }

        // A continuous wheel moves in points; its line delta stays zero for small turns.
        let continuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        let vertical = event.getIntegerValueField(continuous ? .scrollWheelEventPointDeltaAxis1 : .scrollWheelEventDeltaAxis1)
        let horizontal = event.getIntegerValueField(continuous ? .scrollWheelEventPointDeltaAxis2 : .scrollWheelEventDeltaAxis2)
        guard let direction = direction(vertical: vertical, horizontal: horizontal) else { return nil }
        return InputEvent(trigger: .scroll(direction), modifiers: ModifierSet(flags: event.flags),
                          phase: .scroll, timestamp: event.timestamp)
    }

    /// Reverses or multiplies a mouse wheel event in place. Trackpad, Magic Mouse and momentum
    /// events are left exactly as the system produced them.
    static func adjust(_ event: CGEvent, by adjustment: WheelAdjustment) {
        guard !adjustment.changesNothing, isMouseWheel(event) else { return }
        let axes: [(CGEventField, CGEventField, CGEventField, Int64)] = [
            (.scrollWheelEventDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventPointDeltaAxis1, adjustment.factor),
            (.scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2, .scrollWheelEventPointDeltaAxis2,
             adjustment.horizontalFactor)
        ]
        for (lines, fixed, points, factor) in axes where factor != 1 {
            // Read all three first: writing the line delta makes Quartz recompute the others.
            // Point deltas of a continuous wheel are fractional, so they stay doubles.
            let lineDelta = event.getIntegerValueField(lines)
            let fixedDelta = event.getDoubleValueField(fixed)
            let pointDelta = event.getDoubleValueField(points)
            guard lineDelta != 0 || fixedDelta != 0 || pointDelta != 0 else { continue }
            event.setIntegerValueField(lines, value: lineDelta * factor)
            event.setDoubleValueField(fixed, value: fixedDelta * Double(factor))
            event.setDoubleValueField(points, value: pointDelta * Double(factor))
        }
        AttachedHIDScroll.scale(event, vertically: Double(adjustment.factor), horizontally: Double(adjustment.horizontalFactor))
    }

    static func direction(vertical: Int64, horizontal: Int64) -> ScrollDirection? {
        switch (vertical, horizontal) {
        case (let delta, 0) where delta != 0: delta > 0 ? .up : .down
        case (0, let delta) where delta != 0: delta > 0 ? .left : .right
        default: nil // Zero or diagonal: never swallow an unmapped component.
        }
    }
}
