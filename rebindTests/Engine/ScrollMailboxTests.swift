import Synchronization
import Testing
@testable import rebind

struct ScrollMailboxTests {
    private var configuration: Configuration {
        Configuration(isEnabled: true, bindings: [rebind.Binding(
            scope: .allMice, trigger: .scroll(.up), modifiers: .control,
            action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))])
    }
    private func impulse(at timestamp: UInt64 = 0) -> InputEvent {
        InputEvent(trigger: .scroll(.up), modifiers: .control, phase: .scroll, timestamp: timestamp)
    }

    @Test func recordedWheelNeverDispatchesAndDoesNotLeaveAPressedSource() throws {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        let request = RecordingRequest(target: .scrollTrigger)
        mailbox.record(request)
        #expect(mailbox.handle(impulse(), secureInput: false))
        let result = try #require(mailbox.state.withLock { $0.recorded })
        #expect(result.request == request)
        #expect(result.input == MatchKey(trigger: .scroll(.up), modifiers: .control))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.state.withLock { $0.matcher.hasSuppressedInput } == false)
    }

    @Test func buttonAndOutputRecordersIgnoreWheelInput() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        for target in [RecordingTarget.mouseTrigger, .output, .keyboardTrigger] {
            mailbox.record(RecordingRequest(target: target))
            #expect(mailbox.handle(impulse(), secureInput: false) == false)
            #expect(mailbox.state.withLock { $0.recorded == nil })
            #expect(mailbox.state.withLock { $0.pending.isEmpty })
        }
    }

    @Test func wheelRecorderIgnoresButtonAndEscapeStillCancels() {
        let mailbox = EngineMailbox()
        mailbox.record(RecordingRequest(target: .scrollTrigger))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false) == false)
        #expect(mailbox.handle(InputEvent(trigger: .key(53), phase: .down), secureInput: false))
        #expect(mailbox.state.withLock { $0.recording == nil })
        #expect(mailbox.handle(InputEvent(trigger: .key(53), phase: .up), secureInput: false))
    }

    @Test func rapidWheelBurstIsBoundedAndPauseClearsQueuedAction() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        for timestamp in UInt64(0)...99 {
            #expect(mailbox.handle(impulse(at: timestamp * 1_000_000), secureInput: false))
        }
        #expect(mailbox.state.withLock { $0.pending.count } == 1)
        mailbox.configure(Configuration())
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(impulse(at: 100_000_000), secureInput: false) == false)
        mailbox.configure(configuration)
        #expect(mailbox.handle(impulse(at: 100_000_000), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.count } == 1)
    }

    @Test func secureInputSuspensionAndEditingPassWheelThrough() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        _ = mailbox.handle(impulse(), secureInput: false)
        #expect(mailbox.handle(impulse(at: 100_000_000), secureInput: true) == false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        mailbox.suspend(true)
        #expect(mailbox.handle(impulse(), secureInput: false) == false)
        mailbox.suspend(false)
        mailbox.state.withLock { $0.editing = true }
        #expect(mailbox.handle(impulse(), secureInput: false) == false)
        mailbox.state.withLock { $0.editing = false }
        #expect(mailbox.handle(impulse(), secureInput: false))
    }

    @Test func fullOutputQueuePassesWheelThrough() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        mailbox.state.withLock {
            $0.pending = Array(repeating: RebindAction.shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)), count: 16)
        }
        #expect(mailbox.handle(impulse(), secureInput: false) == false)
        #expect(mailbox.state.withLock { $0.pending.count } == 16)
    }
}
