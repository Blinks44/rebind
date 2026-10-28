import Foundation
import Synchronization
import Testing
@testable import rebind

@MainActor struct AppleShortcutDispatchTests {
    private let target = AppleShortcutTarget(id: UUID(), name: "Selected")

    private func mailbox() -> EngineMailbox {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .appleShortcut(target))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        return mailbox
    }

    private func worker(_ mailbox: EngineMailbox) -> ActionWorker {
        ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendShortcut: { _ in Issue.record("Apple Shortcut must not become a key pulse"); return false },
            secureInput: { false }, postingAllowed: { true })
    }

    @Test func serialWorkerHandsOffSelectedTargetAndExposesDistinctProgress() async {
        let mailbox = mailbox()
        let target = target
        worker(mailbox).service(at: 0)
        #expect(mailbox.state.withLock { $0.appleShortcutInProgress })
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in
            Issue.record("Unrelated application switch"); return .unavailable
        }, performAppleShortcut: { selected, allowed in
            #expect(selected == target && allowed())
            #expect(mailbox.state.withLock { $0.appleShortcutInProgress })
            return .performed
        }, secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(mailbox.state.withLock { !$0.appleShortcutInProgress && $0.actionFailed == nil })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func heldReleasePassesWhileShortcutRunsAndOrdinaryActionsKeepTheirOrder() async {
        let mailbox = mailbox()
        let sent = Mutex<[HeldKeyCommand.Phase]>([])
        let ordinary = Mutex(0)
        mailbox.state.withLock {
            $0.held = [HeldOutput(trigger: .mouseButton(4), action: .modifier(.command), pressedAt: 1)]
            $0.pending.append(.window(.close))
        }
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendHeldKey: { command in sent.withLock { $0.append(command.phase) } },
            performWindow: { _, _ in ordinary.withLock { $0 += 1 }; return .performed },
            secureInput: { false }, postingAllowed: { true })
        worker.service(at: 2)
        let started = ShortcutTestGate(), finish = ShortcutTestGate()
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in .unavailable },
            performAppleShortcut: { _, allowed in
                await started.signal()
                await finish.wait()
                #expect(allowed())
                return .performed
            }, secureInput: { false }, postingAllowed: { true })
        async let running: Void = executor.service()
        await started.wait()
        mailbox.state.withLock { $0.releaseHeldOutput(for: .mouseButton(4)) }
        worker.service(at: 3)
        #expect(sent.withLock { $0 } == [.release])
        #expect(ordinary.withLock { $0 } == 0)
        #expect(mailbox.state.withLock { $0.workspaceClaimed && $0.pending == [.window(.close)] })
        await finish.signal()
        await running
        worker.service(at: 4)
        #expect(ordinary.withLock { $0 } == 1)
    }

    @Test(arguments: 0...5)
    func lifecycleChangesInvalidateRunningGenerationAndIgnoreLateFailure(_ change: Int) async {
        let mailbox = mailbox()
        worker(mailbox).service(at: 0)
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in .unavailable },
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
                #expect(mailbox.state.withLock { $0.workspaceClaimed })
                #expect(mailbox.nextAction() == nil)
                return .failed
            }, secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(mailbox.state.withLock { !$0.appleShortcutInProgress && $0.actionFailed == nil })
    }

    @Test(arguments: [true, false])
    func protectedInputOrRevokedPostingPreventsExecution(_ secure: Bool) async {
        let mailbox = mailbox()
        worker(mailbox).service(at: 0)
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in .unavailable },
            performAppleShortcut: { _, _ in Issue.record("Protected input executed a shortcut"); return .failed },
            secureInput: { secure }, postingAllowed: { secure })
        await executor.service()
        #expect(mailbox.state.withLock { !$0.appleShortcutInProgress && $0.pending.isEmpty })
    }

    @Test(arguments: [true, false])
    func protectedInputOrRevokedPostingDuringRunRevokesAuthorization(_ secure: Bool) async {
        let mailbox = mailbox()
        let revoked = Mutex(false)
        worker(mailbox).service(at: 0)
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in .unavailable },
            performAppleShortcut: { _, allowed in
                #expect(allowed())
                revoked.withLock { $0 = true }
                #expect(!allowed())
                return .cancelled
            }, secureInput: { secure && revoked.withLock { $0 } },
            postingAllowed: { secure || !revoked.withLock { $0 } })
        await executor.service()
        #expect(mailbox.state.withLock { !$0.appleShortcutInProgress && $0.actionFailed == nil })
    }

    @Test(arguments: [AppleShortcutRunResult.failed, .cancelled])
    func failureDoesNotEmergencyPauseAndCancellationDoesNotReportError(_ result: AppleShortcutRunResult) async {
        let mailbox = mailbox()
        worker(mailbox).service(at: 0)
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in .unavailable },
            performAppleShortcut: { _, _ in result }, secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && !$0.appleShortcutInProgress })
        #expect(mailbox.state.withLock { $0.actionFailed } == (result == .failed ? .appleShortcut(target) : nil))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func modelDisplaysLocalizedFailure() {
        let model = AppModel(loadConfiguration: false)
        model.mailbox.state.withLock { $0.actionFailed = .appleShortcut(target) }
        model.refresh()
        #expect(model.error == .appleShortcutFailed)
    }
}

private extension EngineMailbox.State {
    var appleShortcutInProgress: Bool {
        if case .appleShortcut = workspaceRequest?.target { return true }
        return false
    }
}

private actor ShortcutTestGate {
    private var signalled = false
    private var waiter: CheckedContinuation<Void, Never>?
    func wait() async {
        if !signalled { await withCheckedContinuation { waiter = $0 } }
    }
    func signal() {
        signalled = true
        waiter?.resume()
        waiter = nil
    }
}
