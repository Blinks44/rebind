import Testing
@testable import rebind

struct DiagnosticMailboxTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private func button(_ number: UInt32 = 3, phase: InputEvent.Phase = .down, time: UInt64 = 1) -> InputEvent {
        InputEvent(trigger: .mouseButton(number), modifiers: .control, phase: phase, receivedAt: time)
    }
    private func snapshot(_ mailbox: EngineMailbox) -> DiagnosticSnapshot {
        mailbox.state.withLock { $0.diagnostics.snapshot() }
    }

    @Test func pausedDiagnosticsNeverEnableRulesOrConsumeUnmatchedInput() {
        let mailbox = EngineMailbox()
        #expect(mailbox.startDiagnostics(at: 0))
        for number in [UInt32(0), 1, 3, 99, UInt32.max] {
            #expect(mailbox.handle(button(number), secureInput: false) == false)
            #expect(mailbox.handle(button(number, phase: .up), secureInput: false) == false)
        }
        #expect(mailbox.state.withLock { $0.enabled == false && $0.pending.isEmpty })
        #expect(snapshot(mailbox).entries.count == 10)
        #expect(snapshot(mailbox).entries.last?.kind == .button(UInt32.max))
        #expect(snapshot(mailbox).entries.allSatisfy { $0.outcome == .passedThrough })
    }

    @Test func matchingRuleReportsQueueAndReleaseConsumptionWithoutChangingOutput() {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: .control, action: .shortcut(output))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.startDiagnostics(at: 0)
        #expect(mailbox.handle(button(), secureInput: false))
        #expect(mailbox.handle(button(phase: .up, time: 2), secureInput: false))
        #expect(snapshot(mailbox).entries.map(\.outcome) == [.queued, .suppressed])
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
        #expect(mailbox.state.withLock { $0.matcher.hasSuppressedInput } == false)
    }

    @Test func holdDiagnosticUsesSourceModifiersAndDoesNotLogKeyboardHoldCodes() {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
                                     action: .shortcut(output), activation: .hold, holdDurationMilliseconds: 500)
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.startDiagnostics(at: 0)
        #expect(mailbox.handle(button(time: 0), secureInput: false))
        mailbox.pollHold(at: 500_000_000, secureInput: false)
        let activation = snapshot(mailbox).entries.last
        #expect(activation?.phase == .activation)
        #expect(activation?.modifiers == .control)
        #expect(activation?.outcome == .queued)
        var keyboard = binding
        keyboard.scope = .allKeyboards
        keyboard.trigger = .key(0)
        mailbox.configure(Configuration(isEnabled: true, bindings: [keyboard]))
        mailbox.clearDiagnostics()
        #expect(mailbox.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down, receivedAt: 600_000_000), secureInput: false))
        mailbox.pollHold(at: 1_100_000_000, secureInput: false)
        #expect(snapshot(mailbox).entries.isEmpty)
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
    }

    @Test func burstThrottlingDoesNotThrottleMatchingOrSwallowedReleases() {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: .control, action: .shortcut(output))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.startDiagnostics(at: 0)
        for _ in 0..<12 {
            #expect(mailbox.handle(button(), secureInput: false))
            #expect(mailbox.handle(button(phase: .up), secureInput: false))
        }
        #expect(mailbox.state.withLock { $0.pending.count } == 12)
        #expect(snapshot(mailbox).entries.count == 20)
        #expect(snapshot(mailbox).omitted == 4)
    }

    @Test(arguments: 0..<5) func protectedContextsAndFailuresEraseAndStopCollection(mode: Int) {
        let mailbox = EngineMailbox()
        mailbox.startDiagnostics(at: 0)
        _ = mailbox.handle(button(), secureInput: false)
        #expect(snapshot(mailbox).entries.count == 1)
        switch mode {
        case 0: _ = mailbox.handle(button(time: 2), secureInput: true)
        case 1: mailbox.handleUnsupportedScroll(modifiers: [], at: 2, secureInput: true)
        case 2: mailbox.captureLost(status: .permissionRequired)
        case 3: mailbox.suspend(true); mailbox.suspend(false)
        default: mailbox.stop()
        }
        #expect(snapshot(mailbox).isRunning == false)
        #expect(snapshot(mailbox).entries.isEmpty)
    }

    @Test func unsupportedScrollPassesThroughAndCancelsHoldWithoutLoggingDetails() {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
                                     action: .shortcut(output), activation: .hold, holdDurationMilliseconds: 500)
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.startDiagnostics(at: 0)
        #expect(mailbox.handle(button(time: 0), secureInput: false))
        mailbox.handleUnsupportedScroll(modifiers: .control, at: 1, secureInput: false)
        mailbox.pollHold(at: 500_000_000, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(snapshot(mailbox).entries.last?.kind == .unsupportedScroll)
        #expect(snapshot(mailbox).entries.last?.outcome == .passedThrough)
    }

    @Test func disabledStartAndEmergencyBypassDoNotKeepDiagnosticsAlive() {
        let mailbox = EngineMailbox()
        mailbox.suspend(true)
        #expect(mailbox.startDiagnostics(at: 0) == false)
        mailbox.suspend(false)
        #expect(mailbox.startDiagnostics(at: 0))
        _ = mailbox.handle(button(), secureInput: false)
        #expect(mailbox.handle(InputEvent(trigger: .key(53), modifiers: .supported, phase: .down, receivedAt: 2), secureInput: false))
        #expect(snapshot(mailbox).entries.isEmpty)
        #expect(snapshot(mailbox).isRunning == false)
        mailbox.stop()
        #expect(mailbox.startDiagnostics(at: 3) == false)
    }

    @Test func snapshotExpiryNeedsNoInputAndUnchangedRevisionsDoNotCopyRows() throws {
        let mailbox = EngineMailbox()
        #expect(mailbox.diagnosticSnapshot(since: 0, at: 0) == nil)
        mailbox.startDiagnostics(at: 0)
        _ = mailbox.handle(button(), secureInput: false)
        let first = try #require(mailbox.diagnosticSnapshot(since: 0, at: 1))
        #expect(mailbox.diagnosticSnapshot(since: first.revision, at: 2) == nil)
        let expired = try #require(mailbox.diagnosticSnapshot(since: first.revision, at: InputDiagnostics.sessionDuration))
        #expect(expired.isRunning == false)
        #expect(expired.entries == first.entries)
    }
}
