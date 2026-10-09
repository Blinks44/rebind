import Foundation
import Synchronization
import Testing
@testable import rebind

struct AppleShortcutDispatchTests {
    private let target = AppleShortcutTarget(id: UUID(), name: "Selected")

    private func mailbox() -> EngineMailbox {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .appleShortcut(target))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        return mailbox
    }

    @Test func serialWorkerRoutesSelectedTargetAndExposesProgressWithoutKeyPosting() {
        let mailbox = mailbox()
        let calls = Mutex<[RebindAction]>([])
        let target = target
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendShortcut: { _ in Issue.record("Apple Shortcut must not become a key pulse"); return false },
            performAppleShortcut: { selected, allowed in
                #expect(selected == target && allowed())
                #expect(mailbox.state.withLock { $0.appleShortcutInProgress })
                calls.withLock { $0.append(.appleShortcut(selected)) }
                return .performed
            }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == [.appleShortcut(target)])
        #expect(mailbox.state.withLock { !$0.appleShortcutInProgress && $0.actionFailed == nil })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test(arguments: 0...5)
    func lifecycleChangesInvalidateRunningGenerationAndIgnoreLateFailure(_ change: Int) {
        let mailbox = mailbox()
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performAppleShortcut: { _, allowed in
                #expect(allowed())
                switch change {
                case 0: mailbox.configure(Configuration(isEnabled: true))
                case 1: mailbox.configure(Configuration(isEnabled: false))
                case 2: mailbox.setEditing(true)
                case 3: mailbox.record(RecordingRequest(target: .mouseTrigger))
                case 4: mailbox.suspend(true)
                default: mailbox.stop()
                }
                #expect(allowed() == false)
                return .failed
            }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 0)
        #expect(mailbox.state.withLock { !$0.appleShortcutInProgress && $0.actionFailed == nil })
    }

    @Test(arguments: [true, false])
    func protectedInputOrRevokedPostingPreventsExecution(_ secure: Bool) {
        let mailbox = mailbox()
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performAppleShortcut: { _, _ in Issue.record("Protected input must not execute a shortcut"); return .failed },
            secureInput: { secure }, postingAllowed: { secure })
        worker.service(at: 0)
        #expect(mailbox.state.withLock { !$0.appleShortcutInProgress && $0.pending.isEmpty })
    }

    @Test(arguments: [AppleShortcutRunResult.failed, .cancelled])
    func failureDoesNotEmergencyPauseAndCancellationDoesNotReportError(_ result: AppleShortcutRunResult) {
        let mailbox = mailbox()
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performAppleShortcut: { _, _ in result }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && !$0.appleShortcutInProgress })
        #expect(mailbox.state.withLock { $0.actionFailed } == (result == .failed ? .appleShortcut(target) : nil))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @MainActor @Test func modelDisplaysLocalizedFailureAndProgress() {
        let model = AppModel(loadConfiguration: false)
        model.mailbox.state.withLock { $0.actionFailed = .appleShortcut(target); $0.appleShortcutInProgress = true }
        model.refresh()
        #expect(model.error == .appleShortcutFailed && model.appleShortcutInProgress)
        model.mailbox.state.withLock { $0.appleShortcutInProgress = false }
        model.refresh()
        #expect(model.appleShortcutInProgress == false)
    }
}
