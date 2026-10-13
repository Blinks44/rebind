import Foundation
import Synchronization
import Testing
@testable import rebind

struct EngineMailboxTests {
    @Test func fnFlagIsNotSilentlyRecordedAsAnOrdinaryShortcut() {
        let mailbox = EngineMailbox()
        mailbox.record(RecordingRequest(target: .keyboardTrigger))
        #expect(mailbox.handle(InputEvent(trigger: .key(0), modifiers: .function, phase: .down), secureInput: false) == false)
        #expect(mailbox.state.withLock { $0.recorded == nil })
    }

    private func configured() -> EngineMailbox {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: .control,
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        return mailbox
    }

    @Test func pauseDiscardsPendingButSwallowsOwnedRelease() {
        let mailbox = configured()
        #expect(mailbox.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.count } == 1)
        mailbox.configure(Configuration())
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .key(0), phase: .up), secureInput: false))
        #expect(mailbox.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), secureInput: false) == false)
    }

    @Test func recordingOutputNeverDispatchesAnAction() throws {
        let mailbox = configured()
        let request = RecordingRequest(target: .output)
        mailbox.record(request)
        #expect(mailbox.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), secureInput: false))
        let captured = try #require(mailbox.state.withLock { $0.recorded })
        #expect(captured.request == request)
        #expect(captured.input == MatchKey(trigger: .key(0), modifiers: .control))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(InputEvent(trigger: .key(0), phase: .up), secureInput: false))
    }

    @Test func mouseRecorderIgnoresKeysAndEscapeCancels() throws {
        let mailbox = configured()
        mailbox.record(RecordingRequest(target: .mouseTrigger))
        #expect(mailbox.handle(InputEvent(trigger: .key(0), phase: .down), secureInput: false) == false)
        #expect(mailbox.handle(InputEvent(trigger: .key(53), phase: .down), secureInput: false))
        #expect(try #require(mailbox.state.withLock { $0.recorded }).input == nil)
        #expect(mailbox.state.withLock { $0.recording == nil })
        #expect(mailbox.handle(InputEvent(trigger: .key(53), phase: .up), secureInput: false))
    }

    @Test func secureInputAndSuspensionClearQueuedOutput() {
        let mailbox = configured()
        let down = InputEvent(trigger: .key(0), modifiers: .control, phase: .down)
        _ = mailbox.handle(down, secureInput: false)
        #expect(mailbox.handle(InputEvent(trigger: .key(1), phase: .down), secureInput: true) == false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        mailbox.suspend(true)
        #expect(mailbox.handle(down, secureInput: false) == false)
        mailbox.suspend(false)
        #expect(mailbox.handle(down, secureInput: false))
    }

    @Test func emergencyPauseClearsQueuedOutput() {
        let mailbox = configured()
        _ = mailbox.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), secureInput: false)
        #expect(mailbox.handle(InputEvent(trigger: .key(53), modifiers: .supported, phase: .down), secureInput: false))
        #expect(mailbox.state.withLock { $0.enabled } == false)
        #expect(mailbox.state.withLock { $0.emergencyPause })
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test func queueIsBoundedAndOverflowPassesThrough() {
        let mailbox = EngineMailbox()
        let bindings = (UInt32(2)...20).map {
            rebind.Binding(scope: .allMice, trigger: .mouseButton($0), modifiers: [],
                           action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        }
        mailbox.configure(Configuration(isEnabled: true, bindings: bindings))
        for number in UInt32(2)...17 {
            #expect(mailbox.handle(InputEvent(trigger: .mouseButton(number), phase: .down), secureInput: false))
        }
        #expect(mailbox.state.withLock { $0.pending.count } == 16)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(18), phase: .down), secureInput: false) == false)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(18), phase: .up), secureInput: false) == false)
    }

    @Test func editingSuspendsMappingsButKeepsRecorderAvailable() {
        let mailbox = configured()
        mailbox.state.withLock { $0.editing = true }
        #expect(mailbox.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), secureInput: false) == false)
        mailbox.record(RecordingRequest(target: .keyboardTrigger))
        #expect(mailbox.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }
}
