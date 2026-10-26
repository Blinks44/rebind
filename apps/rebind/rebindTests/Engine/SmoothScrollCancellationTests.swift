import Foundation
import Testing
@testable import rebind

struct SmoothScrollCancellationTests {
    @Test(arguments: 0...9)
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
        case 9: mailbox.captureLost(status: .permissionRequired)
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

    @Test func postingPermissionIsCheckedOncePerGlideButSecureInputStopsTheNextFrame() {
        let dispatch = SmoothScrollDispatch(sender: 1, revision: 1, settings: SmoothScrollingSettings(glide: .standard))
        var authorization = SmoothScrollAuthorization()
        var tccChecks = 0
        var secureChecks = 0
        for _ in 0..<120 {
            let allowed = authorization.allows(dispatch, generation: 0,
                secureInput: { secureChecks += 1; return false }, canPost: { tccChecks += 1; return true })
            #expect(allowed)
        }
        #expect(tccChecks == 1)
        #expect(secureChecks == 120)
        let protected = authorization.allows(dispatch, generation: 0, secureInput: { true },
                                             canPost: { tccChecks += 1; return true })
        #expect(protected == false)
        #expect(tccChecks == 1)
        let revoked = authorization.allows(dispatch, generation: 1, secureInput: { false },
                                           canPost: { tccChecks += 1; return false })
        #expect(revoked == false)
        #expect(tccChecks == 2)
        let changed = SmoothScrollDispatch(sender: 2, revision: 2, settings: dispatch.settings)
        let reauthorized = authorization.allows(changed, generation: 1, secureInput: { false },
                                                canPost: { tccChecks += 1; return true })
        #expect(reauthorized)
        #expect(tccChecks == 3)
    }
}
