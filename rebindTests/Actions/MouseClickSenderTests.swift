import AppKit
import CoreGraphics
import Testing
@testable import rebind

struct MouseClickSenderTests {
    @Test(arguments: MouseAction.allCases)
    func constructsBalancedPlainTaggedClicksAtOneGlobalPosition(_ action: MouseAction) throws {
        let point = CGPoint(x: -280, y: 42)
        let events = try #require(MouseClickSender.events(action, at: point, make: { source, type, location, button in
            // Private-state IDs are unique, not necessarily the .privateState sentinel.
            #expect(source.sourceStateID != .hidSystemState && source.sourceStateID != .combinedSessionState)
            #expect(source.localEventsSuppressionInterval == 0)
            let event = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: location, mouseButton: button)
            event?.flags = CGEventFlags(rawValue: CGEventFlags.maskControl.rawValue | CGEventFlags.maskAlternate.rawValue | 0x40)
            event?.setIntegerValueField(.mouseEventDeltaX, value: 20)
            return event
        }))
        #expect(events.count == action.clickCount * 2)
        for click in 0..<action.clickCount {
            let down = events[click * 2], up = events[click * 2 + 1]
            #expect(down.type == action.downType && up.type == action.upType)
            #expect(down.getIntegerValueField(.mouseEventNumber) == up.getIntegerValueField(.mouseEventNumber))
            #expect(down.getDoubleValueField(.mouseEventPressure) == 1 && up.getDoubleValueField(.mouseEventPressure) == 0)
            for event in [down, up] {
                #expect(event.location == point && event.flags.rawValue == 0)
                #expect(event.getIntegerValueField(.mouseEventClickState) == click + 1)
                #expect(event.getIntegerValueField(.mouseEventButtonNumber) == Int64(action.button.rawValue))
                #expect(event.getIntegerValueField(.mouseEventDeltaX) == 0 && event.getIntegerValueField(.mouseEventDeltaY) == 0)
                #expect(event.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag)
            }
        }
    }

    @Test @MainActor func doubleClickBridgesToAppKitWithTwoBalancedClicksAndCorrectClickCounts() throws {
        let events = try #require(MouseClickSender.events(.doubleLeftClick, at: .zero))
        let native = try events.map { try #require(NSEvent(cgEvent: $0)) }
        #expect(native.map(\.type) == [.leftMouseDown, .leftMouseUp, .leftMouseDown, .leftMouseUp])
        #expect(native.map(\.clickCount) == [1, 1, 2, 2])
        #expect(native.allSatisfy { $0.buttonNumber == 0 && $0.modifierFlags.isEmpty })
    }

    @Test func initialCancellationNeverReadsPointerButtonsOrAllocatesEvents() {
        var calls = 0
        let result = MouseClickSender.perform(.leftClick, canPerform: { false },
            position: { calls += 1; return .zero }, isButtonDown: { _ in calls += 1; return false },
            build: { _, _ in calls += 1; return nil }, post: { _, _ in calls += 1 })
        #expect(result == .cancelled && calls == 0)
    }

    @Test(arguments: [0, 1]) func heldTargetBeforeOrAfterConstructionNeverPosts(_ stage: Int) {
        var checks = 0, posts = 0
        let result = MouseClickSender.perform(.middleClick, canPerform: { true }, position: { .zero },
            isButtonDown: { button in
                #expect(button == .center)
                checks += 1
                return stage == 0 || checks == 2
            }, post: { _, _ in posts += 1 })
        #expect(result == .unavailable && posts == 0)
        #expect(checks == (stage == 0 ? 1 : 2))
    }

    @Test func missingPositionInvalidCoordinatesAndSourceFailWithoutPosting() {
        var posts = 0
        #expect(MouseClickSender.perform(.leftClick, canPerform: { true }, position: { nil },
            isButtonDown: { _ in false }, post: { _, _ in posts += 1 }) == .unavailable)
        for point in [CGPoint(x: CGFloat.nan, y: 0), CGPoint(x: 0, y: CGFloat.infinity)] {
            #expect(MouseClickSender.perform(.leftClick, canPerform: { true }, position: { point },
                isButtonDown: { _ in false }, post: { _, _ in posts += 1 }) == .unavailable)
        }
        #expect(MouseClickSender.events(.leftClick, at: .zero, source: { nil }) == nil)
        #expect(posts == 0)
    }

    @Test(arguments: 1...4) func allocationFailureCannotPostPartOfADoubleClick(_ failure: Int) {
        var allocations = 0, posts = 0
        let result = MouseClickSender.perform(.doubleLeftClick, canPerform: { true }, position: { .zero },
            isButtonDown: { _ in false }, build: { action, point in
                MouseClickSender.events(action, at: point, make: { source, type, location, button in
                    allocations += 1
                    return allocations == failure ? nil : CGEvent(mouseEventSource: source, mouseType: type,
                        mouseCursorPosition: location, mouseButton: button)
                })
            }, post: { _, _ in posts += 1 })
        #expect(result == .unavailable && posts == 0)
    }

    @Test func cancellationDuringConstructionOrFinalButtonCheckPreventsEntireClick() {
        for stage in 0...1 {
            var allowed = true, checks = 0, posts = 0
            let result = MouseClickSender.perform(.rightClick, canPerform: { allowed }, position: { .zero },
                isButtonDown: { _ in
                    checks += 1
                    if stage == 1 && checks == 2 { allowed = false }
                    return false
                }, build: { action, point in
                    if stage == 0 { allowed = false }
                    return MouseClickSender.events(action, at: point)
                }, post: { _, _ in posts += 1 })
            #expect(result == .cancelled && posts == 0)
        }
    }

    @Test(arguments: MouseAction.allCases)
    func startedBatchFinishesBalancedReleaseAtSessionTapWithoutResamplingPointer(_ action: MouseAction) {
        var allowed = true, reads = 0
        var posted: [CGEventType] = []
        let point = CGPoint(x: 50, y: 70)
        let result = MouseClickSender.perform(action, canPerform: { allowed }, position: { reads += 1; return point },
            isButtonDown: { _ in false }, post: { event, tap in
                #expect(tap == .cgSessionEventTap && event.location == point)
                posted.append(event.type)
                allowed = false
            })
        #expect(result == .performed && posted.count == action.clickCount * 2 && reads == 1)
        #expect(posted.last == action.upType)
    }
}
