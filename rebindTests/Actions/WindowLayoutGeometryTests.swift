import CoreGraphics
import Testing
@testable import rebind

struct WindowLayoutGeometryTests {
    private let display = WindowDisplay(frame: CGRect(x: 0, y: 0, width: 1001, height: 800),
                                        visibleFrame: CGRect(x: 0, y: 25, width: 1001, height: 725))
    private let window = CGRect(x: 100, y: 100, width: 300, height: 200)

    @Test func halvesShareAnEdgeAndCoverOnlyUsableArea() throws {
        let left = try #require(WindowLayoutGeometry.target(.leftHalf, window: window, displays: [display]))
        let right = try #require(WindowLayoutGeometry.target(.rightHalf, window: window, displays: [display]))
        #expect(left == CGRect(x: 0, y: 25, width: 500, height: 725))
        #expect(right == CGRect(x: 500, y: 25, width: 501, height: 725))
        #expect(left.union(right) == display.visibleFrame)
        #expect(WindowLayoutGeometry.target(.fill, window: window, displays: [display]) == display.visibleFrame)
    }

    @Test func centerPreservesSizeAndRejectsOversizedWindows() {
        #expect(WindowLayoutGeometry.target(.center, window: window, displays: [display]) == CGRect(x: 350.5, y: 287.5, width: 300, height: 200))
        #expect(WindowLayoutGeometry.target(.center, window: CGRect(x: 0, y: 100, width: 1100, height: 300), displays: [display]) == nil)
    }

    @Test func largestOverlapSelectsDisplayAndTiesUseStableInputOrder() {
        let right = WindowDisplay(frame: CGRect(x: 1001, y: -500, width: 1200, height: 900),
                                  visibleFrame: CGRect(x: 1001, y: -475, width: 1200, height: 850))
        let crossing = CGRect(x: 900, y: 50, width: 600, height: 250)
        #expect(WindowLayoutGeometry.target(.fill, window: crossing, displays: [display, right]) == right.visibleFrame)
        let tie = CGRect(x: 901, y: 50, width: 200, height: 250)
        #expect(WindowLayoutGeometry.target(.fill, window: tie, displays: [display, right]) == display.visibleFrame)
        #expect(WindowLayoutGeometry.target(.fill, window: tie, displays: [right, display]) == right.visibleFrame)
    }

    @Test func cocoaConversionUsesPrimaryTopAndPointsOnAllSides() {
        let converted = WindowDisplay.fromCocoa(frame: CGRect(x: -1200, y: 800, width: 1200, height: 900),
            visibleFrame: CGRect(x: -1150, y: 800, width: 1150, height: 875), primaryTop: 800)
        #expect(converted.frame == CGRect(x: -1200, y: -900, width: 1200, height: 900))
        #expect(converted.visibleFrame == CGRect(x: -1150, y: -875, width: 1150, height: 875))
        #expect(WindowDisplay.fromCocoa(frame: CGRect(x: 0, y: -700, width: 1000, height: 700),
            visibleFrame: CGRect(x: 0, y: -650, width: 1000, height: 650), primaryTop: 800).visibleFrame == CGRect(x: 0, y: 800, width: 1000, height: 650))
    }

    @Test(arguments: [CGRect.zero, CGRect.null, CGRect.infinite, CGRect(x: 0, y: 0, width: -1, height: 300),
                      CGRect(x: CGFloat.nan, y: 0, width: 100, height: 100)])
    func invalidWindowGeometryIsRejected(_ rect: CGRect) {
        #expect(WindowLayoutGeometry.target(.fill, window: rect, displays: [display]) == nil)
    }

    @Test func missingOffscreenMalformedAndDisplayCoveringTargetsAreRejected() {
        #expect(WindowLayoutGeometry.target(.fill, window: window, displays: []) == nil)
        #expect(WindowLayoutGeometry.target(.fill, window: CGRect(x: -5000, y: 0, width: 300, height: 200), displays: [display]) == nil)
        #expect(WindowLayoutGeometry.target(.fill, window: display.frame, displays: [display]) == nil)
        var invalid = display
        invalid.visibleFrame = CGRect(x: -1, y: 0, width: 1001, height: 800)
        #expect(WindowLayoutGeometry.target(.fill, window: window, displays: [invalid]) == nil)
    }

    @Test func snapshotFreshnessIsBoundedAndClockReversalIsRejected() {
        let snapshot = WindowDisplaySnapshot(displays: [display], capturedAt: 100)
        #expect(snapshot.isFresh(at: 100) && snapshot.isFresh(at: 2_000_000_100))
        #expect(!snapshot.isFresh(at: 99) && !snapshot.isFresh(at: 2_000_000_101))
        #expect(!WindowDisplaySnapshot().isFresh(at: 0))
    }
}
