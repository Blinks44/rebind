import CoreGraphics
import Testing
@testable import rebind

struct ScrollEventAdapterTests {
    private func wheel(vertical: Int32 = 1, horizontal: Int32 = 0) throws -> CGEvent {
        try #require(CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2,
                             wheel1: vertical, wheel2: horizontal, wheel3: 0))
    }

    @Test(arguments: [ScrollDirection.up, .down, .left, .right])
    func directionUsesDeliveredLineDeltas(_ direction: ScrollDirection) throws {
        let deltas: (Int32, Int32)
        switch direction {
        case .up: deltas = (3, 0)
        case .down: deltas = (-3, 0)
        case .left: deltas = (0, 3)
        case .right: deltas = (0, -3)
        }
        let event = try wheel(vertical: deltas.0, horizontal: deltas.1)
        event.flags = [.maskControl, .maskAlternate]
        event.timestamp = 123_456_789
        let input = try #require(ScrollEventAdapter.input(from: event))
        #expect(input.trigger == .scroll(direction))
        #expect(input.phase == .scroll)
        #expect(input.modifiers == [.control, .option])
        #expect(input.timestamp == event.timestamp)
    }

    @Test(arguments: [CGEventField.scrollWheelEventIsContinuous, .scrollWheelEventScrollPhase,
                      .scrollWheelEventMomentumPhase, .scrollWheelEventDeltaAxis3])
    func unsupportedScrollMetadataPassesThrough(_ field: CGEventField) throws {
        let event = try wheel()
        event.setIntegerValueField(field, value: 1)
        #expect(ScrollEventAdapter.input(from: event) == nil)
    }

    @Test func zeroAndDiagonalEventsAreNotPartiallyConsumed() throws {
        #expect(ScrollEventAdapter.input(from: try wheel(vertical: 0)) == nil)
        #expect(ScrollEventAdapter.input(from: try wheel(vertical: 3, horizontal: 1)) == nil)
    }

    @Test func taggedFeedbackAndOtherEventTypesAreIgnored() throws {
        let tagged = try wheel()
        tagged.setIntegerValueField(.eventSourceUserData, value: ShortcutSender.eventTag)
        #expect(ScrollEventAdapter.input(from: tagged) == nil)
        let keyboard = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 13, keyDown: true))
        #expect(ScrollEventAdapter.input(from: keyboard) == nil)
    }

    @Test(arguments: [Int64.min, Int64.max])
    func extremeSignedDeltasDoNotOverflowNormalization(_ delta: Int64) {
        // CGEvent setters may convert/clamp extreme values internally; test the
        // normalized metadata boundary directly, not a requested constructor value.
        #expect(ScrollEventAdapter.direction(vertical: delta, horizontal: 0) == (delta < 0 ? .down : .up))
        #expect(ScrollEventAdapter.direction(vertical: 0, horizontal: delta) == (delta < 0 ? .right : .left))
    }
}
