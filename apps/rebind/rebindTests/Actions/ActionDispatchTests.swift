import Foundation
import Synchronization
import Testing
@testable import rebind

struct ActionDispatchTests {
    private let audio = AudioOutputCapabilities(deviceID: 17, volume: true, mute: true)
    private let shortcut = KeyboardShortcut(keyCode: 0, modifiers: .command)

    private func mailbox(action: RebindAction = .system(.volumeUp)) -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.updateAudioCapabilities(audio)
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: action)
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }

    private func press(_ mailbox: EngineMailbox) -> Bool {
        mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false)
    }

    @Test func unavailableAudioPassesThroughWhileShortcutsStillMatch() {
        let mailbox = mailbox()
        mailbox.updateAudioCapabilities(AudioOutputCapabilities(deviceID: 17, mute: true))
        #expect(press(mailbox) == false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .shortcut(shortcut))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        #expect(press(mailbox))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(shortcut)])
    }

    @Test func oneSerialConsumerPreservesTypedOrderAndNeverPostsAudioAsKeys() {
        let mailbox = mailbox()
        let calls = Mutex<[RebindAction]>([])
        let audio = audio
        let worker = ActionWorker(mailbox: mailbox, capabilities: { audio },
            performAudio: { action, device in
                #expect(device == 17)
                calls.withLock { $0.append(.system(action)) }
                return true
            }, sendShortcut: { value in calls.withLock { $0.append(.shortcut(value)) }; return true },
            secureInput: { false }, postingAllowed: { true })
        mailbox.state.withLock { $0.pending = [.system(.volumeDown), .shortcut(shortcut), .system(.toggleMute)] }
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == [.system(.volumeDown)])
        worker.service(at: 1)
        worker.service(at: 2)
        #expect(calls.withLock { $0 } == [.system(.volumeDown), .shortcut(shortcut), .system(.toggleMute)])
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test(arguments: 0...5)
    func profilePauseEditRecordSuspendAndStopInvalidateDequeuedActions(_ change: Int) throws {
        let mailbox = mailbox()
        #expect(press(mailbox))
        let dispatch = try #require(mailbox.nextAction())
        switch change {
        case 0:
            var configuration = Configuration(isEnabled: true)
            try configuration.createProfile(name: "Second")
            mailbox.configure(configuration)
        case 1: mailbox.configure(Configuration(isEnabled: false))
        case 2: mailbox.setEditing(true)
        case 3: mailbox.record(RecordingRequest(target: .mouseTrigger))
        case 4: mailbox.suspend(true)
        default: mailbox.stop()
        }
        #expect(mailbox.dispatchIsCurrent(dispatch) == false)
        mailbox.actionFailed(dispatch)
        #expect(mailbox.state.withLock { $0.actionFailed == nil })
    }

    @Test func outputReplacementCancelsQueueAndHoldButPreservesOwnedRelease() throws {
        let mailbox = mailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .system(.toggleMute), activation: .hold)
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        #expect(press(mailbox))
        mailbox.updateAudioCapabilities(AudioOutputCapabilities(deviceID: 21, volume: true, mute: true))
        mailbox.pollHold(at: 500_000_000, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
        #expect(mailbox.state.withLock { $0.matcher.hasSuppressedInput } == false)
    }

    @Test func cancellationBetweenDequeueAndExecutionDoesNotCallBackend() {
        let mailbox = mailbox()
        let calls = Mutex(0)
        let preflights = Mutex(0)
        let audio = audio
        let worker = ActionWorker(mailbox: mailbox, capabilities: { audio },
            performAudio: { _, _ in calls.withLock { $0 += 1 }; return true },
            sendShortcut: { _ in calls.withLock { $0 += 1 }; return true }, secureInput: { false },
            postingAllowed: {
                preflights.withLock { count in
                    // First preflight precedes dequeue; second changes state
                    // after dequeue to exercise the final generation check.
                    count += 1
                    if count == 2 { mailbox.setEditing(true) }
                }
                return true
            })
        #expect(press(mailbox))
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 0)
        #expect(preflights.withLock { $0 } == 2)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test(arguments: [true, false])
    func secureInputAndRevokedPostingClearPendingWithoutExecuting(_ secure: Bool) {
        let mailbox = mailbox()
        let audio = audio
        let calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { audio },
            performAudio: { _, _ in calls.withLock { $0 += 1 }; return true },
            sendShortcut: { _ in calls.withLock { $0 += 1 }; return true },
            secureInput: { secure }, postingAllowed: { secure })
        #expect(press(mailbox))
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 0)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.state.withLock { $0.status } == (secure ? .secureInput : .permissionRequired))
    }

    @Test func audioFailureReportsErrorWithoutDisablingUnrelatedRules() {
        let mailbox = mailbox()
        let audio = audio
        let worker = ActionWorker(mailbox: mailbox, capabilities: { audio }, performAudio: { _, _ in false },
            sendShortcut: { _ in true }, secureInput: { false }, postingAllowed: { true })
        #expect(press(mailbox))
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.actionFailed } == .system(.volumeUp))
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func failedShortcutStopsOutputAndRequestsEmergencyPause() {
        let mailbox = mailbox(action: .shortcut(shortcut))
        let audio = audio
        let worker = ActionWorker(mailbox: mailbox, capabilities: { audio }, performAudio: { _, _ in true },
            sendShortcut: { _ in false }, secureInput: { false }, postingAllowed: { true })
        #expect(press(mailbox))
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.actionFailed } == .shortcut(shortcut))
        #expect(mailbox.state.withLock { $0.enabled == false && $0.emergencyPause && $0.pending.isEmpty })
    }
}
