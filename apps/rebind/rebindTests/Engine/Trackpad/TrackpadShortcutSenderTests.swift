import ApplicationServices
import Dispatch
import Synchronization
import Testing
@testable import rebind

struct TrackpadShortcutSenderTests {
    private let shortcut = KeyboardShortcut(keyCode: 13, modifiers: .command)
    private let target = TrackpadDispatchTarget(pid: 100, inputActivity: 0, expiresAt: 100_000_000)

    @Test func activeTargetPostsOneTaggedBalancedPairWithoutReadingItsAXTree() {
        var activeChecks = 0
        var posted: [CGEvent] = []
        let diagnostics = Mutex<[String]>([])
        let result = ShortcutSender.send(shortcut, to: target, canPerform: { true },
            diagnose: { event in diagnostics.withLock { $0.append(event.key) } },
            allowsInput: { true }, blockedInput: { _ in nil },
            targetIsActive: { pid in activeChecks += 1; return pid == 100 }, clock: { 1 },
            post: { event, pid in
                #expect(pid == 100)
                #expect(diagnostics.withLock { $0.isEmpty })
                posted.append(event)
            })
        #expect(result == .performed)
        #expect(activeChecks == 2)
        #expect(diagnostics.withLock { $0 } == ["posted-queue-age-le-10ms"])
        #expect(posted.map(\.type) == [.keyDown, .keyUp])
        #expect(posted.allSatisfy {
            $0.flags.contains(.maskCommand)
                && $0.getIntegerValueField(.keyboardEventKeycode) == 13
                && $0.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag
        })
    }

    @Test(arguments: 0...7) func cancellationDuringPreparationNeverPosts(_ scenario: Int) {
        let reasons = Mutex<[String]>([])
        let runtimeChecks = Mutex(0)
        var activeChecks = 0, permissionChecks = 0, heldChecks = 0, posts = 0
        let result = ShortcutSender.send(shortcut, to: target, canPerform: {
            runtimeChecks.withLock { $0 += 1; return scenario != 0 || $0 == 1 }
        }, diagnose: { event in reasons.withLock { $0.append(event.key) } },
            allowsInput: { permissionChecks += 1; return scenario != 1 || permissionChecks == 1 },
            blockedInput: { _ in
                heldChecks += 1
                guard (3...5).contains(scenario), heldChecks == 2 else { return nil }
                return scenario == 3 ? .heldModifier : scenario == 4 ? .heldButton : .heldKey
            }, targetIsActive: { _ in
                activeChecks += 1
                return scenario != 6 && (scenario != 2 || activeChecks == 1)
            }, clock: { scenario == 7 ? 100_000_001 : 1 }, post: { _, _ in posts += 1 })
        #expect(result == .cancelled)
        #expect(posts == 0)
        #expect(reasons.withLock { $0 } == [["output-runtime-changed"], ["output-protected-context"],
            ["output-target-inactive"], ["output-held-modifier"], ["output-held-button"],
            ["output-held-key"], ["output-target-inactive"], ["output-expired"]][scenario])
    }

    @Test func workerContinuesPostingAfterRepeatedRealButtonPairs() throws {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .builtInTrackpad, trigger: .fourFingerTap,
                                     modifiers: [], action: .shortcut(shortcut))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock {
            $0.status = .active; $0.foregroundPID = 100
            $0.trackpadDiagnostics = .init(startedAt: DispatchTime.now().uptimeNanoseconds)
        }
        let posted = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { shortcut, target, canPerform in
                ShortcutSender.send(shortcut, to: target, canPerform: canPerform,
                    diagnose: { mailbox.recordTrackpadDiagnostic($0) },
                    allowsInput: { true }, blockedInput: { _ in nil }, targetIsActive: { $0 == 100 },
                    clock: { 1 }, post: { _, _ in posted.withLock { $0 += 1 } })
            }, secureInput: { false }, postingAllowed: { true })
        for _ in 0..<37 {
            _ = mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: .down), secureInput: false)
            _ = mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: .up), secureInput: false)
            let runtime = try #require(mailbox.trackpadRuntime())
            #expect(mailbox.submitTrackpad(runtime, pid: 100, at: 0))
            worker.service(at: 1)
        }
        #expect(posted.withLock { $0 } == 74)
        #expect(mailbox.state.withLock { $0.trackpadDiagnostics?.counts["output-posted"] } == 37)
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause })
    }
}
