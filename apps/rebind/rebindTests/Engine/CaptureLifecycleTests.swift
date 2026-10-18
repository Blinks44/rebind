import Testing
@testable import rebind

struct CaptureLifecycleTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)

    private func configuration(activation: PressActivation = .press) -> Configuration {
        Configuration(isEnabled: true, bindings: [rebind.Binding(scope: .allMice,
            trigger: .mouseButton(3), modifiers: [], action: .shortcut(output),
            activation: activation, holdDurationMilliseconds: 500)])
    }

    @Test func permissionLossClearsOutputOwnershipAndCancelsRecorder() throws {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration())
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
        mailbox.captureLost(status: .permissionRequired)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.matcher.hasSuppressedInput == false })
        #expect(mailbox.state.withLock { $0.enabled }) // Permission restoration preserves user preference.
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false) == false)

        let request = RecordingRequest(target: .mouseTrigger)
        mailbox.record(request)
        mailbox.captureLost(status: .permissionRequired)
        let cancellation = try #require(mailbox.state.withLock { $0.recorded })
        #expect(cancellation.request == request)
        #expect(cancellation.input == nil)
        #expect(mailbox.state.withLock { $0.recording == nil })
        mailbox.captureLost(status: .permissionRequired)
        #expect(mailbox.state.withLock { $0.recorded?.request } == request)
    }

    @Test func lostCaptureCannotDeliverAnOldHoldAfterRestoration() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration(activation: .hold))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down, receivedAt: 0), secureInput: false))
        mailbox.captureLost(status: .permissionRequired)
        mailbox.pollHold(at: 500_000_000, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down, receivedAt: 600_000_000), secureInput: false))
        mailbox.pollHold(at: 1_100_000_000, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
    }

    @Test func interruptionPausesUntilExplicitResumeAndAdvancesRetry() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration())
        let retry = mailbox.state.withLock { $0.retryID }
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        mailbox.captureLost(status: .interrupted, pause: true)
        #expect(mailbox.state.withLock { $0.enabled == false && $0.emergencyPause && $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false) == false)
        mailbox.configure(configuration())
        #expect(mailbox.state.withLock { $0.retryID } == retry + 1)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
    }

    @Test func aDisabledTapRecoversAtMostThreeTimesAMinute() {
        var recent: [UInt64] = []
        let second: UInt64 = 1_000_000_000
        #expect((0..<3).allSatisfy { EventTapWorker.mayRecover(at: UInt64($0) * second, recent: &recent) })
        #expect(!EventTapWorker.mayRecover(at: 10 * second, recent: &recent))
        // The first recovery leaves the window after a minute.
        #expect(EventTapWorker.mayRecover(at: 60 * second, recent: &recent))
        #expect(!EventTapWorker.mayRecover(at: 60 * second + 1, recent: &recent))
    }

    @Test func outputFailureClearsPointerCaptureAsWellAsOutput() {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: 3, direction: .left),
                                     modifiers: [], action: .shortcut(output))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        #expect(mailbox.handlePointerMotion(PointerMotion(deltaX: -50, deltaY: 0), modifiers: [], receivedAt: 1, secureInput: false))
        mailbox.captureLost(status: .outputFailed, pause: true)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.matcher.hasSuppressedInput == false && $0.enabled == false })
        #expect(mailbox.handlePointerMotion(PointerMotion(deltaX: -50, deltaY: 0), modifiers: [], receivedAt: 2, secureInput: false) == false)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false) == false)
    }

    @Test(arguments: 0..<3) func secureInputCancelsRecorderOnEveryEntryPath(path: Int) throws {
        let mailbox = EngineMailbox()
        let request = RecordingRequest(target: .gestureTrigger)
        mailbox.record(request)
        switch path {
        case 0: #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: true) == false)
        case 1: #expect(mailbox.handlePointerMotion(PointerMotion(deltaX: 1, deltaY: 0), modifiers: [], receivedAt: 1, secureInput: true) == false)
        default: mailbox.pollHold(at: 1, secureInput: true)
        }
        let cancellation = try #require(mailbox.state.withLock { $0.recorded })
        #expect(cancellation.request == request)
        #expect(cancellation.input == nil)
        #expect(mailbox.state.withLock { $0.recording == nil && $0.pending.isEmpty })
    }

    @Test func suspensionCancelsRecorderAndDoesNotReplayAcrossWake() throws {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration())
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        mailbox.suspend(true)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.matcher.hasSuppressedInput == false })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false) == false)
        mailbox.suspend(false)
        let request = RecordingRequest(target: .mouseTrigger)
        mailbox.record(request)
        mailbox.suspend(true)
        #expect(try #require(mailbox.state.withLock { $0.recorded }).request == request)
        mailbox.suspend(false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.recording == nil })
    }

    @Test func stopClearsAcquisitionAndAllInputPathsFailOpen() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration(activation: .hold))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        mailbox.stop()
        mailbox.pollHold(at: 500_000_000, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.matcher.hasSuppressedInput == false && $0.stopped })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false) == false)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false) == false)
        #expect(mailbox.handlePointerMotion(PointerMotion(deltaX: -50, deltaY: 0), modifiers: [], receivedAt: 1, secureInput: false) == false)
    }
}
