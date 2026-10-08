import Foundation
import Testing
@testable import rebind

struct ProfileSwitchTests {
    private let oldOutput = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private let newOutput = KeyboardShortcut(keyCode: 13, modifiers: .command)

    private func configuration(_ activation: PressActivation = .press) throws -> Configuration {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
                                    action: .shortcut(oldOutput), activation: activation, holdDurationMilliseconds: 500)
        var configuration = Configuration(isEnabled: true, bindings: [binding])
        try configuration.createProfile(name: "Second", copying: RuleProfile.defaultID)
        configuration.bindings[0].action = .shortcut(newOutput)
        try configuration.selectProfile(RuleProfile.defaultID)
        return configuration
    }

    private func event(_ phase: InputEvent.Phase, at time: UInt64 = 0) -> InputEvent {
        InputEvent(trigger: .mouseButton(3), phase: phase, timestamp: time, receivedAt: time)
    }

    @Test func switchClearsOldQueuePreservesOwnedReleaseAndOnlyUsesNewRules() throws {
        var configuration = try configuration()
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(oldOutput)])
        try configuration.selectProfile(configuration.profiles[1].id)
        mailbox.configure(configuration)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(event(.up), secureInput: false))
        #expect(mailbox.handle(event(.down, at: 1), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(newOutput)])
        #expect(mailbox.handle(event(.up, at: 2), secureInput: false))
        #expect(mailbox.state.withLock { $0.matcher.hasSuppressedInput } == false)
    }

    @Test func switchCancelsOldHoldAndRecordingButKeepsPauseAndDiagnostics() throws {
        var configuration = try configuration(.hold)
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        mailbox.startDiagnostics(at: 0)
        #expect(mailbox.handle(event(.down), secureInput: false))
        try configuration.selectProfile(configuration.profiles[1].id)
        mailbox.configure(configuration)
        mailbox.pollHold(at: 500_000_000, secureInput: false)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.diagnostics.isRunning })
        #expect(mailbox.handle(event(.up), secureInput: false))
        mailbox.record(RecordingRequest(target: .mouseTrigger))
        try configuration.selectProfile(RuleProfile.defaultID)
        configuration.isEnabled = false
        mailbox.configure(configuration)
        #expect(mailbox.state.withLock { $0.recording == nil && $0.recorded == nil && $0.enabled == false })
        #expect(mailbox.handle(event(.down, at: 600_000_000), secureInput: false) == false)
    }

    @Test func aDoublePressCannotSpanTwoProfiles() throws {
        var configuration = try configuration(.doublePress)
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.handle(event(.up, at: 1), secureInput: false))
        try configuration.selectProfile(configuration.profiles[1].id)
        mailbox.configure(configuration)
        #expect(mailbox.handle(event(.down, at: 2), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.handle(event(.up, at: 3), secureInput: false))
        #expect(mailbox.handle(event(.down, at: 4), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(newOutput)])
    }
}
