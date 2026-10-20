import CoreGraphics
import Testing
@testable import rebind

struct ScrollEventAdapterTests {
    @Test(arguments: [ScrollDirection.up, .down, .left, .right], [false, true])
    func configuredDirectionSelectsTheExpectedHeldButtonAction(_ direction: ScrollDirection, reversed: Bool) throws {
        let vertical: Int32 = direction == .up ? 1 : direction == .down ? -1 : 0
        let horizontal: Int32 = direction == .left ? 1 : direction == .right ? -1 : 0
        let event = try wheel(vertical: vertical, horizontal: horizontal)
        let adjustment = WheelAdjustment(reverses: reversed, multiplier: 3, reversesHorizontally: reversed)
        let input = try #require(ScrollEventAdapter.input(from: event, adjustment: adjustment))
        let expected: ScrollDirection
        switch direction {
        case .up: expected = reversed ? .down : .up
        case .down: expected = reversed ? .up : .down
        case .left: expected = reversed ? .right : .left
        case .right: expected = reversed ? .left : .right
        }
        let rules = InputMatcher.compile(ScrollDirection.allCases.map {
            rebind.Binding(scope: .allMice, trigger: .buttonScroll(button: 4, direction: $0),
                           modifiers: [], action: $0 == expected ? .system(.volumeUp) : .system(.volumeDown))
        })
        var matcher = InputMatcher()
        _ = matcher.handle(InputEvent(trigger: .mouseButton(4), phase: .down), rules: rules, enabled: true)
        #expect(matcher.handle(input, rules: rules, enabled: true).action == .system(.volumeUp))
        #expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis1) == Int64(vertical))
        #expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis2) == Int64(horizontal))
    }

    @Test func reversalKeepsAxesIndependentAndRejectsPhasedAndDiagonalInput() throws {
        let adjustment = WheelAdjustment(reverses: true, multiplier: 2)
        #expect(ScrollEventAdapter.input(from: try wheel(vertical: 0, horizontal: 1), adjustment: adjustment)?.trigger == .scroll(.left))
        #expect(ScrollEventAdapter.input(from: try wheel(vertical: 1, horizontal: 1), adjustment: adjustment) == nil)
        let pixel = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
                                        wheel1: -4, wheel2: 0, wheel3: 0))
        #expect(ScrollEventAdapter.input(from: pixel, adjustment: adjustment)?.trigger == .scroll(.up))
        pixel.setIntegerValueField(.scrollWheelEventScrollPhase, value: 2)
        #expect(ScrollEventAdapter.input(from: pixel, adjustment: adjustment) == nil)
    }

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

    @Test(arguments: [CGEventField.scrollWheelEventScrollPhase, .scrollWheelEventMomentumPhase,
                      .scrollWheelEventDeltaAxis3])
    func unsupportedScrollMetadataPassesThrough(_ field: CGEventField) throws {
        let event = try wheel()
        event.setIntegerValueField(field, value: 1)
        #expect(ScrollEventAdapter.input(from: event) == nil)
    }

    @Test func aContinuousWheelWithoutPhaseIsAWheelStepByItsPointDelta() throws {
        let event = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
                                         wheel1: -4, wheel2: 0, wheel3: 0))
        #expect(event.getIntegerValueField(.scrollWheelEventIsContinuous) == 1)
        #expect(ScrollEventAdapter.input(from: event)?.trigger == .scroll(.down))
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: 2)
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
