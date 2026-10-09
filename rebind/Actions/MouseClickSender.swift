import CoreGraphics

nonisolated enum MouseClickSender {
    static func perform(_ action: MouseAction, canPerform: () -> Bool,
                        position: () -> CGPoint? = { CGEvent(source: nil)?.location },
                        isButtonDown: (CGMouseButton) -> Bool = buttonIsDown,
                        build: (MouseAction, CGPoint) -> [CGEvent]? = { events($0, at: $1) },
                        post: (CGEvent, CGEventTapLocation) -> Void = { $0.post(tap: $1) }) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        // Do not synthesize an up for a target button already held by hardware
        // or another event source. The trigger's own suppressed release stays owned.
        guard !isButtonDown(action.button), let point = position(),
              let batch = build(action, point), batch.count == action.clickCount * 2 else { return .unavailable }
        guard !isButtonDown(action.button) else { return .unavailable }
        guard canPerform() else { return .cancelled }
        // Construction and final checks precede any output. Finish every started
        // down/up pair; no delay, suspension or synthetic held-button state escapes.
        for event in batch { post(event, .cgSessionEventTap) }
        return .performed // Quartz posting cannot acknowledge the application's response.
    }

    static func events(_ action: MouseAction, at point: CGPoint,
                       source: () -> CGEventSource? = { CGEventSource(stateID: .privateState) },
                       make: (CGEventSource, CGEventType, CGPoint, CGMouseButton) -> CGEvent? = {
                           CGEvent(mouseEventSource: $0, mouseType: $1, mouseCursorPosition: $2, mouseButton: $3)
                       }) -> [CGEvent]? {
        guard point.x.isFinite, point.y.isFinite, let source = source() else { return nil }
        source.localEventsSuppressionInterval = 0
        var result: [CGEvent] = []
        for click in 1...action.clickCount {
            guard let down = make(source, action.downType, point, action.button),
                  let up = make(source, action.upType, point, action.button) else { return nil }
            up.setIntegerValueField(.mouseEventNumber, value: down.getIntegerValueField(.mouseEventNumber))
            for event in [down, up] {
                event.flags = [] // Plain click; do not inherit trigger/physical modifiers.
                event.setIntegerValueField(.mouseEventButtonNumber, value: Int64(action.button.rawValue))
                event.setIntegerValueField(.mouseEventClickState, value: Int64(click))
                event.setIntegerValueField(.mouseEventDeltaX, value: 0)
                event.setIntegerValueField(.mouseEventDeltaY, value: 0)
                event.setDoubleValueField(.mouseEventPressure, value: event === down ? 1 : 0)
                event.setIntegerValueField(.eventSourceUserData, value: ShortcutSender.eventTag)
            }
            result.append(contentsOf: [down, up])
        }
        return result
    }

    private static func buttonIsDown(_ button: CGMouseButton) -> Bool {
        CGEventSource.buttonState(.hidSystemState, button: button)
            || CGEventSource.buttonState(.combinedSessionState, button: button)
    }
}
