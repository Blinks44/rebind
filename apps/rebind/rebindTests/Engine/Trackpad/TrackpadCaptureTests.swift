import Synchronization
import Testing
@testable import rebind

@MainActor struct TrackpadCaptureTests {
    @Test(arguments: [1, 2], 0...2)
    func trackpadCleanupPreservesMouseOutputUntilWorkerDelivery(_ fingers: Int, _ cleanup: Int) throws {
        let mailbox = EngineMailbox()
        let shortcut = KeyboardShortcut(keyCode: 13, modifiers: .command)
        mailbox.configure(Configuration(isEnabled: true, bindings: [
            rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: fingers), modifiers: [],
                           action: .shortcut(shortcut))
        ]))
        mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
        let runtime = try #require(mailbox.magicMouseRuntime())
        try #require(mailbox.submitMagicMouse(runtime, fingers: fingers, pid: 100, at: 0))
        let capture = TrackpadCapture(mailbox: mailbox)
        cleanUp(capture, mode: cleanup)
        #expect(mailbox.state.withLock { $0.trackpadStatus } == .idle)
        let delivered = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { output, target, canPerform in
                #expect(output == shortcut && target.isMagicMouse && target.pid == 100 && canPerform())
                delivered.withLock { $0 += 1 }
                return .performed
            }, sendShortcut: { _ in Issue.record("Mouse touch used global shortcut sender"); return false },
            secureInput: { false }, postingAllowed: { true })
        worker.service(at: 20_000_000)
        worker.service(at: 30_000_000)
        #expect(delivered.withLock { $0 } == 1)
    }

    @Test(arguments: [false, true], 0...2)
    func trackpadCleanupStillCancelsItsOwnOutput(_ external: Bool, _ cleanup: Int) throws {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [
            rebind.Binding(scope: external ? .magicTrackpad : .builtInTrackpad, trigger: .threeFingerTap,
                           modifiers: .option, action: .shortcut(.init(keyCode: 13, modifiers: .command)))
        ]))
        mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
        let runtime = try #require(mailbox.trackpadRuntime(magicTrackpad: external, modifiers: .option))
        try #require(mailbox.submitTrackpad(runtime, gesture: .single(.threeFinger), pid: 100, at: 0))
        cleanUp(TrackpadCapture(mailbox: mailbox), mode: cleanup)
        #expect(mailbox.nextAction() == nil)
    }

    private func cleanUp(_ capture: TrackpadCapture, mode: Int) {
        switch mode {
        case 0: capture.service(allowingInput: true, foregroundPID: 100, modifiers: [])
        case 1: capture.stop()
        default: capture.service(allowingInput: false, foregroundPID: nil, modifiers: [])
        }
    }

    @Test(arguments: [false, true])
    func workerProtectionStillCancelsPreservedMouseOutput(_ secureInput: Bool) throws {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [
            rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: 1), modifiers: [],
                           action: .shortcut(.init(keyCode: 13, modifiers: .command)))
        ]))
        mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
        let runtime = try #require(mailbox.magicMouseRuntime())
        try #require(mailbox.submitMagicMouse(runtime, fingers: 1, pid: 100, at: 0))
        TrackpadCapture(mailbox: mailbox).service(allowingInput: false, foregroundPID: nil, modifiers: [])
        try #require(mailbox.state.withLock { $0.trackpadDispatch != nil })
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { _, _, _ in Issue.record("Protected mouse output was sent"); return .performed },
            secureInput: { secureInput }, postingAllowed: { secureInput })
        worker.service(at: 20_000_000)
        #expect(mailbox.nextAction() == nil)
        #expect(mailbox.state.withLock { $0.status } == (secureInput ? .secureInput : .permissionRequired))
    }
}
