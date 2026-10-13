import CoreGraphics
import Testing
@testable import rebind

struct PointerMotionTests {
    @Test(arguments: [CGEventType.mouseMoved, .otherMouseDragged])
    func adapterUsesRelativeFieldsRatherThanAbsoluteCursorLocation(_ type: CGEventType) throws {
        let event = try #require(CGEvent(mouseEventSource: nil, mouseType: type,
                                        mouseCursorPosition: CGPoint(x: 0, y: 0), mouseButton: .center))
        event.setIntegerValueField(.mouseEventDeltaX, value: -30)
        event.setIntegerValueField(.mouseEventDeltaY, value: 10)
        let motion = PointerMotion.from(event)
        #expect(motion.deltaX == -30 && motion.deltaY == 10)
        event.location = CGPoint(x: 2000, y: 2000)
        let moved = PointerMotion.from(event)
        #expect(moved.deltaX == -30 && moved.deltaY == 10)
    }

    @Test func idleMotionMaskIsOptionalWhileButtonLifecycleIsAlwaysCaptured() {
        let idle = CGEventMask(1) << CGEventType.mouseMoved.rawValue
        let ordinary = EventTapWorker.eventMask(capturePointerMotion: false)
        let gestures = EventTapWorker.eventMask(capturePointerMotion: true)
        #expect(ordinary & idle == 0)
        #expect(gestures == ordinary | idle)
        for type in [CGEventType.otherMouseDown, .otherMouseUp, .otherMouseDragged, .keyDown, .keyUp, .scrollWheel] {
            #expect(ordinary & (CGEventMask(1) << type.rawValue) != 0)
        }
    }
}
