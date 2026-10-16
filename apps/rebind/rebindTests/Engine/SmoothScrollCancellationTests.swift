import Foundation
import Testing
@testable import rebind

struct SmoothScrollCancellationTests {
    @Test(arguments: 0...8)
    func interruptedGlidesNeverBecomeCurrentAgain(_ interruption: Int) throws {
        let mailbox = EngineMailbox()
        var configuration = Configuration(isEnabled: true)
        configuration.excludedApplications = [ExcludedApplication(target: ApplicationTarget(
            url: URL(filePath: "/Applications/Game.app"), bundleIdentifier: "test.game"),
            allowsBindings: true, allowsSmoothScrolling: false)]
        mailbox.configure(configuration)
        mailbox.setSmoothScrolling(bySender: [1: SmoothScrollingSettings(glide: .long)])
        mailbox.state.withLock { $0.status = .active }
        let dispatch = try #require(mailbox.smoothScrollDispatch(sender: 1))
        #expect(mailbox.smoothScrollIsCurrent(dispatch))
        switch interruption {
        case 0: configuration.isEnabled = false; mailbox.configure(configuration)
        case 1: mailbox.setEditing(true); mailbox.setEditing(false)
        case 2: mailbox.record(RecordingRequest(target: .output)); mailbox.record(nil)
        case 3: mailbox.suspend(true); mailbox.suspend(false)
        case 4: mailbox.captureLost(status: .secureInput)
        case 5: mailbox.stop()
        case 6: mailbox.setPointerApplication("test.game"); mailbox.setPointerApplication(nil)
        case 7: mailbox.setForegroundApplication("test.game"); mailbox.setForegroundApplication(nil)
        default: mailbox.setSmoothScrolling(bySender: [:]); mailbox.setSmoothScrolling(bySender: [1: dispatch.settings])
        }
        #expect(mailbox.smoothScrollIsCurrent(dispatch) == false)
    }

    @Test func malformedWheelValuesCannotOverflowPixelConversion() {
        #expect(SmoothScroller.add(.infinity, to: 0) == 0)
        #expect(SmoothScroller.add(.nan, to: 50) == 0)
        #expect(SmoothScroller.add(.greatestFiniteMagnitude, to: 10) == 100_000)
        #expect(SmoothScroller.add(-.greatestFiniteMagnitude, to: -10) == -100_000)
    }
}
