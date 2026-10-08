import Synchronization
import Testing
@testable import rebind

struct DoublePressMailboxTests {
    private let output = KeyboardShortcut(keyCode: 13, modifiers: .command)
    private var configuration: Configuration {
        Configuration(isEnabled: true, bindings: [rebind.Binding(scope: .allKeyboards, trigger: .key(0),
            modifiers: .control, action: .shortcut(output), activation: .doublePress)])
    }
    private func event(_ phase: InputEvent.Phase, at time: UInt64) -> InputEvent {
        InputEvent(trigger: .key(0), modifiers: .control, phase: phase, timestamp: time)
    }
    private func firstPress(_ mailbox: EngineMailbox) {
        #expect(mailbox.handle(event(.down, at: 0), secureInput: false))
        #expect(mailbox.handle(event(.up, at: 1), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test func mailboxPreservesPairAndQueuesOnlyOneOutput() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration, doublePressIntervalNanoseconds: 100)
        firstPress(mailbox)
        #expect(mailbox.handle(event(.down, at: 100), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
        #expect(mailbox.handle(event(.up, at: 101), secureInput: false))
        #expect(mailbox.state.withLock { $0.matcher.hasSuppressedInput } == false)
    }

    @Test(arguments: ["pause", "configure", "record", "edit", "secure", "suspend"])
    func lifecycleChangesCannotCompleteAStalePair(_ change: String) {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        firstPress(mailbox)
        switch change {
        case "pause": mailbox.configure(Configuration()); mailbox.configure(configuration)
        case "configure": mailbox.configure(configuration)
        case "record": mailbox.record(RecordingRequest(target: .output)); mailbox.record(nil)
        case "edit": mailbox.setEditing(true); mailbox.setEditing(false)
        case "secure": #expect(mailbox.handle(event(.modifiersChanged, at: 2), secureInput: true) == false)
        case "suspend": mailbox.suspend(true); mailbox.suspend(false)
        default: Issue.record("Unknown test case")
        }
        #expect(mailbox.handle(event(.down, at: 3), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test func pauseAndEditingKeepOwnedReleaseSymmetric() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        #expect(mailbox.handle(event(.down, at: 0), secureInput: false))
        mailbox.setEditing(true)
        mailbox.configure(Configuration())
        #expect(mailbox.handle(event(.up, at: 1), secureInput: false))
        #expect(mailbox.state.withLock { $0.matcher.hasSuppressedInput } == false)
        #expect(mailbox.handle(event(.down, at: 2), secureInput: false) == false)
    }

    @Test func recordingCapturesPhysicalPressWithoutRunningDoubleAction() throws {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        let request = RecordingRequest(target: .keyboardTrigger)
        mailbox.record(request)
        #expect(mailbox.handle(event(.down, at: 0), secureInput: false))
        let recorded = try #require(mailbox.state.withLock { $0.recorded })
        #expect(recorded.request == request)
        #expect(recorded.input == MatchKey(trigger: .key(0), modifiers: .control))
        #expect(mailbox.handle(event(.up, at: 1), secureInput: false))
        #expect(mailbox.handle(event(.down, at: 2), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test func queueOverflowFailsOpenAndCancelsPendingPair() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        firstPress(mailbox)
        mailbox.state.withLock { $0.pending = Array(repeating: RebindAction.shortcut(output), count: 16) }
        #expect(mailbox.handle(event(.down, at: 2), secureInput: false) == false)
        mailbox.state.withLock { $0.pending.removeAll() }
        // The failed-open second press was never owned and must have a normal up.
        #expect(mailbox.handle(event(.up, at: 3), secureInput: false) == false)
        #expect(mailbox.handle(event(.down, at: 4), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test func emergencyPauseCancelsCandidateAndPreservesEscapeRelease() {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        firstPress(mailbox)
        #expect(mailbox.handle(InputEvent(trigger: .key(53), modifiers: [.control, .option, .shift, .command],
                                         phase: .down, timestamp: 2), secureInput: false))
        #expect(mailbox.state.withLock { $0.emergencyPause && !$0.enabled && $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .key(53), phase: .up, timestamp: 3), secureInput: false))
        mailbox.configure(configuration)
        #expect(mailbox.handle(event(.down, at: 4), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }
}
