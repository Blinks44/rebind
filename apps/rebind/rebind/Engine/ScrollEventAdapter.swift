import CoreGraphics

// A discrete wheel impulse is not a down/up press or a touch gesture. Keep
// phase/continuous metadata here so unsupported scroll streams pass unchanged.
nonisolated enum ScrollEventAdapter {
    static func input(from event: CGEvent) -> InputEvent? {
        guard event.type == .scrollWheel,
              event.getIntegerValueField(.eventSourceUserData) != ShortcutSender.eventTag,
              event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0,
              event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0,
              event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0,
              event.getIntegerValueField(.scrollWheelEventDeltaAxis3) == 0 else { return nil }

        let vertical = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let horizontal = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
        guard let direction = direction(vertical: vertical, horizontal: horizontal) else { return nil }
        return InputEvent(trigger: .scroll(direction), modifiers: ModifierSet(flags: event.flags),
                          phase: .scroll, timestamp: event.timestamp)
    }

    /// Reverses or multiplies a stepped wheel event in place. Continuous (trackpad, Magic Mouse,
    /// smooth-wheel) and momentum events are left exactly as the system produced them.
    static func adjust(_ event: CGEvent, by adjustment: WheelAdjustment) {
        guard event.type == .scrollWheel, adjustment.factor != 1,
              event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0,
              event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0,
              event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0 else { return }
        let axes: [(CGEventField, CGEventField, CGEventField)] = [
            (.scrollWheelEventDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventPointDeltaAxis1),
            (.scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2, .scrollWheelEventPointDeltaAxis2)
        ]
        for (lines, fixed, points) in axes {
            // Read all three first: writing the line delta makes Quartz recompute the others.
            let lineDelta = event.getIntegerValueField(lines)
            let fixedDelta = event.getDoubleValueField(fixed)
            let pointDelta = event.getIntegerValueField(points)
            guard lineDelta != 0 || fixedDelta != 0 || pointDelta != 0 else { continue }
            event.setIntegerValueField(lines, value: lineDelta * adjustment.factor)
            event.setDoubleValueField(fixed, value: fixedDelta * Double(adjustment.factor))
            event.setIntegerValueField(points, value: pointDelta * adjustment.factor)
        }
    }

    static func direction(vertical: Int64, horizontal: Int64) -> ScrollDirection? {
        switch (vertical, horizontal) {
        case (let delta, 0) where delta != 0: delta > 0 ? .up : .down
        case (0, let delta) where delta != 0: delta > 0 ? .left : .right
        default: nil // Zero or diagonal: never swallow an unmapped component.
        }
    }
}
