import ApplicationServices
import Testing
@testable import rebind

struct WindowLayoutExecutorTests {
    private let displays = [WindowDisplay(frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
                                         visibleFrame: CGRect(x: 0, y: 25, width: 1000, height: 725))]

    @Test(arguments: WindowLayoutAction.allCases)
    func requestedGeometryIsAppliedAndReadBack(_ action: WindowLayoutAction) {
        let client = LayoutClient()
        let target = WindowLayoutGeometry.target(action, window: client.currentFrame, displays: displays)
        #expect(WindowLayoutExecutor.perform(action, displays: displays, client: client, ownPID: 99, canPerform: { true }) == .performed)
        #expect(client.currentFrame == target)
        #expect(client.writes == (action == .center ? ["position"] : ["size", "position", "size"]))
    }

    @Test(arguments: 0...10)
    func unsupportedTargetsDoNotMutate(_ scenario: Int) {
        let client = LayoutClient()
        switch scenario {
        case 0: client.trusted = false
        case 1: client.application = nil
        case 2: client.pid = 99
        case 3: client.childPID = 2
        case 4: client.window = nil
        case 5: client.standard = false
        case 6: client.minimized = true
        case 7: client.minimized = nil
        case 8: client.positionWritable = false
        case 9: client.sizeWritable = false
        default: client.frameAvailable = false
        }
        #expect(WindowLayoutExecutor.perform(.leftHalf, displays: displays, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.writes.isEmpty)
    }

    @Test func centerDoesNotRequireResizableWindow() {
        let client = LayoutClient()
        client.sizeWritable = false
        #expect(WindowLayoutExecutor.perform(.center, displays: displays, client: client, ownPID: 99, canPerform: { true }) == .performed)
        #expect(client.writes == ["position"] && client.currentFrame.size == CGSize(width: 300, height: 200))
    }

    @Test(arguments: 0...3)
    func cancellationStopsAtEachMutationBoundaryWithoutRollback(_ acceptedWrites: Int) {
        let client = LayoutClient()
        #expect(WindowLayoutExecutor.perform(.fill, displays: displays, client: client, ownPID: 99,
            canPerform: { client.writes.count < acceptedWrites }) == .cancelled)
        #expect(client.writes.count == acceptedWrites)
    }

    @Test(arguments: 0...2, [true, false])
    func focusOrTrustChangeStopsBeforeNextWrite(_ acceptedWrites: Int, _ trustChanged: Bool) {
        let client = LayoutClient()
        client.onGate = {
            if client.focusReads > 0 && client.writes.count == acceptedWrites {
                if trustChanged { client.trusted = false } else { client.window = "other" }
            }
            return true
        }
        #expect(WindowLayoutExecutor.perform(.fill, displays: displays, client: client, ownPID: 99,
            canPerform: { client.onGate?() ?? true }) == .unavailable)
        #expect(client.writes.count == acceptedWrites)
    }

    @Test(arguments: 1...3)
    func rejectedMutationIsNotRetriedOrRolledBack(_ failingWrite: Int) {
        let client = LayoutClient()
        client.failingWrite = failingWrite
        #expect(WindowLayoutExecutor.perform(.fill, displays: displays, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.writes.count == failingWrite)
    }

    @Test func appMinimumSizeConstraintIsReportedDespiteAcceptedAXWrites() {
        let client = LayoutClient()
        client.minimumWidth = 700
        #expect(WindowLayoutExecutor.perform(.leftHalf, displays: displays, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.writes == ["size", "position", "size"])
        #expect(client.currentFrame.width == 700)
    }

    @Test func cancellationDuringBlockingFocusReadPreventsNextMutation() {
        let client = LayoutClient()
        var allowed = true
        client.onFocusRead = { if client.focusReads == 2 { allowed = false } }
        #expect(WindowLayoutExecutor.perform(.fill, displays: displays, client: client, ownPID: 99, canPerform: { allowed }) == .cancelled)
        #expect(client.writes.isEmpty)
    }
}

nonisolated private final class LayoutClient: WindowLayoutAccessibility {
    var trusted = true
    var application: String? = "app"
    var window: String? = "window"
    var pid: pid_t = 1
    var childPID: pid_t = 1
    var standard = true
    var minimized: Bool? = false
    var frameAvailable = true
    var currentFrame = CGRect(x: 100, y: 100, width: 300, height: 200)
    var positionWritable = true
    var sizeWritable = true
    var minimumWidth: CGFloat = 0
    var failingWrite = 0
    var writes: [String] = []
    var onGate: (() -> Bool)?
    var onFocusRead: (() -> Void)?
    var focusReads = 0
    func processID(of element: String) -> pid_t? { element == "app" ? pid : childPID }
    func element(_ attribute: String, of element: String) -> String? {
        focusReads += 1
        onFocusRead?()
        return window
    }
    func isWindow(_ element: String) -> Bool { true }
    func isStandardWindow(_ element: String) -> Bool { standard }
    func isMinimized(_ element: String) -> Bool? { minimized }
    func isSettable(_ attribute: String, of element: String) -> Bool {
        attribute == kAXPositionAttribute ? positionWritable : sizeWritable
    }
    func isEnabled(_ element: String) -> Bool { true }
    func setTrue(_ attribute: String, of element: String) -> Bool { Issue.record("Unexpected boolean mutation"); return false }
    func press(_ element: String) -> Bool { Issue.record("Unexpected press"); return false }
    func frame(of element: String) -> CGRect? { frameAvailable ? currentFrame : nil }
    func setPosition(_ position: CGPoint, of element: String) -> Bool {
        writes.append("position")
        guard writes.count != failingWrite else { return false }
        currentFrame.origin = position
        return true
    }
    func setSize(_ size: CGSize, of element: String) -> Bool {
        writes.append("size")
        guard writes.count != failingWrite else { return false }
        currentFrame.size = CGSize(width: max(size.width, minimumWidth), height: size.height)
        return true
    }
}
