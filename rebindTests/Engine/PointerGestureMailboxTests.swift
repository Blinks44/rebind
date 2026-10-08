import Testing
@testable import rebind

struct PointerGestureMailboxTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private var configuration: Configuration {
        Configuration(isEnabled: true, bindings: [rebind.Binding(scope: .allMice,
            trigger: .mouseGesture(button: 3, direction: .left), modifiers: .control, action: .shortcut(output))])
    }
    private func start(_ mailbox: EngineMailbox) {
        mailbox.configure(configuration)
        #expect(mailbox.state.withLock { $0.hasPointerGestureRules })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), modifiers: .control, phase: .down), secureInput: false))
    }
    private func move(_ mailbox: EngineMailbox, time: UInt64 = 1, secure: Bool = false) -> Bool {
        mailbox.handlePointerMotion(PointerMotion(deltaX: -50, deltaY: 0), modifiers: .control,
                                    receivedAt: time, secureInput: secure)
    }

    @Test func unbuttonedMotionAndDragShareOneCandidateAndBoundedQueue() {
        let mailbox = EngineMailbox()
        #expect(move(mailbox) == false)
        start(mailbox)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), modifiers: .control, phase: .drag,
                                         receivedAt: 1, motion: PointerMotion(deltaX: -49, deltaY: 0)), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handlePointerMotion(PointerMotion(deltaX: -1, deltaY: 0), modifiers: .control,
                                            receivedAt: 2, secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [output])
        #expect(move(mailbox, time: 3))
        #expect(mailbox.state.withLock { $0.pending.count } == 1)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
        #expect(move(mailbox, time: 4) == false)
    }

    @Test func saturatedQueueRestoresMotionAndNeverEnqueuesStaleGesture() {
        let mailbox = EngineMailbox()
        start(mailbox)
        mailbox.state.withLock { $0.pending = Array(repeating: output, count: 16) }
        #expect(move(mailbox) == false)
        #expect(mailbox.state.withLock { $0.pending.count } == 16)
        mailbox.state.withLock { $0.pending.removeAll() }
        #expect(move(mailbox, time: 2) == false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func editingRecordingConfigurationPauseAndUnsupportedWheelCancel() {
        for mode in 0..<5 {
            let mailbox = EngineMailbox()
            start(mailbox)
            switch mode {
            case 0: mailbox.setEditing(true); mailbox.setEditing(false)
            case 1: mailbox.record(RecordingRequest(target: .gestureTrigger)); mailbox.record(nil)
            case 2: mailbox.configure(configuration)
            case 3: mailbox.configure(Configuration()); mailbox.configure(configuration)
            default: mailbox.cancelHold()
            }
            #expect(move(mailbox) == false)
            #expect(mailbox.state.withLock { $0.pending.isEmpty })
            #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
        }
    }

    @Test func secureInputAndSuspensionFailOpenAndClearAcquisition() {
        for secure in [false, true] {
            let mailbox = EngineMailbox()
            start(mailbox)
            if !secure { mailbox.suspend(true); mailbox.suspend(false) }
            #expect(move(mailbox, secure: secure) == false)
            #expect(mailbox.state.withLock { $0.pending.isEmpty && !$0.matcher.hasSuppressedInput })
            #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false) == false)
        }
    }

    @Test func protectedUnbuttonedMotionClearsOtherQueuedOutputWithoutGestureCapture() {
        let mailbox = EngineMailbox()
        mailbox.state.withLock { $0.pending = [output] }
        #expect(move(mailbox, secure: true) == false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test func workerPollingExpiresMotionEvenWithoutAnotherEvent() {
        let mailbox = EngineMailbox()
        start(mailbox)
        mailbox.pollHold(at: InputMatcher.pointerTimeoutNanoseconds + 1, secureInput: false)
        #expect(move(mailbox, time: InputMatcher.pointerTimeoutNanoseconds + 2) == false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func sourceRecorderCapturesPhysicalButtonNotMotionAndNeverRunsAnAction() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        mailbox.setEditing(true)
        let request = RecordingRequest(target: .gestureTrigger)
        mailbox.record(request)
        #expect(move(mailbox) == false)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: .down), secureInput: false) == false)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(99), modifiers: .option, phase: .down), secureInput: false))
        let result = mailbox.state.withLock { ($0.recorded, $0.pending.isEmpty) }
        #expect(result.0?.request == request)
        #expect(result.0?.input == MatchKey(trigger: .mouseButton(99), modifiers: .option))
        #expect(result.1)
    }

    @Test func emergencyCancelsPendingAndAlreadyQueuedMotionOutput() {
        let mailbox = EngineMailbox()
        start(mailbox)
        #expect(move(mailbox))
        #expect(mailbox.state.withLock { $0.pending } == [output])
        #expect(mailbox.handle(InputEvent(trigger: .key(53), modifiers: [.control, .option, .shift, .command], phase: .down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.emergencyPause && !$0.enabled })
        #expect(move(mailbox, time: 2) == false)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func idleMotionSubscriptionFollowsEnabledCompiledRules() {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration())
        #expect(mailbox.state.withLock { $0.hasPointerGestureRules } == false)
        mailbox.configure(configuration)
        #expect(mailbox.state.withLock { $0.hasPointerGestureRules })
        var disabled = configuration
        disabled.bindings[0].isEnabled = false
        mailbox.configure(disabled)
        #expect(mailbox.state.withLock { $0.hasPointerGestureRules } == false)
    }
}
