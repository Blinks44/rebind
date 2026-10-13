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

    static func direction(vertical: Int64, horizontal: Int64) -> ScrollDirection? {
        switch (vertical, horizontal) {
        case (let delta, 0) where delta != 0: delta > 0 ? .up : .down
        case (0, let delta) where delta != 0: delta > 0 ? .left : .right
        default: nil // Zero or diagonal: never swallow an unmapped component.
        }
    }
}
