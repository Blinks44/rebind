import Testing
@testable import rebind

struct HoldMailboxTests {
    private let threshold: UInt64 = 500_000_000
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private var configuration: Configuration {
        Configuration(isEnabled: true, bindings: [rebind.Binding(scope: .allMice, trigger: .mouseButton(3),
            modifiers: .control, action: .shortcut(output), activation: .hold)])
    }
    private func start(_ mailbox: EngineMailbox) {
        mailbox.configure(configuration)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), modifiers: .control, phase: .down), secureInput: false))
    }

    @Test func pollingEnqueuesOnePulseAndConsumesRelease() {
        let mailbox = EngineMailbox()
        start(mailbox)
        mailbox.pollHold(at: threshold - 1, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        mailbox.pollHold(at: threshold, secureInput: false)
        mailbox.pollHold(at: threshold + 1, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func g603ButtonFiveWithoutModifiersSurvivesMotion() {
        let mailbox = EngineMailbox()
        let ordinary = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
                                      action: .shortcut(output))
        let held = rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: [],
                                  action: .shortcut(output), activation: .hold, holdDurationMilliseconds: 1000)
        mailbox.configure(Configuration(isEnabled: true, bindings: [ordinary, held]))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(4), phase: .down, receivedAt: 10), secureInput: false))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(4), phase: .drag, receivedAt: 900_000_000), secureInput: false))
        mailbox.pollHold(at: 1_000_000_009, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        mailbox.pollHold(at: 1_000_000_010, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(4), phase: .up), secureInput: false))
        mailbox.state.withLock { $0.pending.removeAll() }
        #expect(!mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        #expect(!mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), modifiers: .control, phase: .down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
    }

    @Test func editingRecordingConfigurationAndPauseCancelPendingHold() {
        for mode in 0..<4 {
            let mailbox = EngineMailbox()
            start(mailbox)
            switch mode {
            case 0: mailbox.setEditing(true); mailbox.setEditing(false)
            case 1: mailbox.record(RecordingRequest(target: .mouseTrigger)); mailbox.record(nil)
            case 2: mailbox.configure(configuration)
            default: mailbox.configure(Configuration()); mailbox.configure(configuration)
            }
            mailbox.pollHold(at: threshold, secureInput: false)
            #expect(mailbox.state.withLock { $0.pending.isEmpty })
            #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
        }
    }

    @Test func secureInputSuspensionAndCaptureLossCancelAllAcquisition() {
        for mode in 0..<3 {
            let mailbox = EngineMailbox()
            start(mailbox)
            switch mode {
            case 0: mailbox.pollHold(at: 1, secureInput: true)
            case 1: mailbox.suspend(true); mailbox.suspend(false)
            default: mailbox.state.withLock { $0.matcher.resetAfterCaptureLoss() }
            }
            mailbox.pollHold(at: threshold, secureInput: false)
            #expect(mailbox.state.withLock { $0.pending.isEmpty && !$0.matcher.hasSuppressedInput })
            #expect(!mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
        }
    }

    @Test func saturatedQueueCancelsInsteadOfDeliveringLater() {
        let mailbox = EngineMailbox()
        start(mailbox)
        mailbox.state.withLock { $0.pending = Array(repeating: RebindAction.shortcut(output), count: 16) }
        mailbox.pollHold(at: threshold, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.count } == 16)
        mailbox.state.withLock { $0.pending.removeAll() }
        mailbox.pollHold(at: threshold + 1, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test func unsupportedWheelCancellationKeepsOwnedReleaseWithoutOutput() {
        let mailbox = EngineMailbox()
        start(mailbox)
        mailbox.cancelHold()
        mailbox.pollHold(at: threshold, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func emergencyCancelsHoldAndOwnsEscapeRelease() {
        let mailbox = EngineMailbox()
        start(mailbox)
        #expect(mailbox.handle(InputEvent(trigger: .key(53), modifiers: [.control, .option, .shift, .command], phase: .down), secureInput: false))
        mailbox.pollHold(at: threshold, secureInput: false)
        #expect(mailbox.state.withLock { $0.emergencyPause && !$0.enabled && $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .key(53), phase: .up), secureInput: false))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }
}
