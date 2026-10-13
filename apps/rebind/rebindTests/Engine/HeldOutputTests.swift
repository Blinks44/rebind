import Foundation
import Synchronization
import Testing
@testable import rebind

struct HeldOutputTests {
    private let output = KeyboardShortcut(keyCode: 123, modifiers: [])
    private let timing = KeyRepeatTiming(delayNanoseconds: 500, intervalNanoseconds: 100)

    private func binding(_ action: RebindAction, trigger: InputTrigger = .mouseButton(3)) -> rebind.Binding {
        var binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: [], action: action)
        binding.holdsOutput = true
        return binding
    }

    private func mailbox(_ bindings: [rebind.Binding]) -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.updateAudioCapabilities(AudioOutputCapabilities(deviceID: 1, volume: true, mute: true))
        mailbox.configure(Configuration(isEnabled: true, bindings: bindings), keyRepeat: timing)
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }

    private func event(_ phase: InputEvent.Phase, _ trigger: InputTrigger = .mouseButton(3)) -> InputEvent {
        InputEvent(trigger: trigger, phase: phase)
    }

    private func command(_ phase: HeldKeyCommand.Phase) -> HeldKeyCommand { HeldKeyCommand(shortcut: output, phase: phase) }

    @Test func aHeldShortcutIsOnePressRepeatsAfterTheDelayAndOneRelease() {
        let mailbox = mailbox([binding(.shortcut(output))])
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.nextHeldKey(at: 1000) == command(.press))
        #expect(mailbox.nextHeldKey(at: 1499) == nil)
        #expect(mailbox.nextHeldKey(at: 1500) == command(.repeatPress))
        #expect(mailbox.nextHeldKey(at: 1599) == nil)
        #expect(mailbox.nextHeldKey(at: 1600) == command(.repeatPress))
        #expect(mailbox.handle(event(.up), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 1601) == command(.release))
        #expect(mailbox.nextHeldKey(at: 5000) == nil)
        #expect(mailbox.state.withLock { $0.held.isEmpty && $0.pending.isEmpty })
    }

    @Test func aTapReleasedBeforeTheWorkerRunsBecomesOneOrdinaryPulse() {
        let mailbox = mailbox([binding(.shortcut(output))])
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.handle(event(.up), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 0) == nil)
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
    }

    @Test(arguments: 0...5)
    func everyInterruptionReleasesAKeyThatIsDownAndPressesNothingElse(_ change: Int) {
        let rule = binding(.shortcut(output))
        let mailbox = mailbox([rule])
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 0) == command(.press))
        switch change {
        case 0: mailbox.configure(Configuration(isEnabled: false, bindings: [rule]), keyRepeat: timing)
        case 1: mailbox.setEditing(true)
        case 2: mailbox.record(RecordingRequest(target: .mouseTrigger))
        case 3: mailbox.suspend(true)
        case 4: mailbox.captureLost(status: .secureInput)
        default: mailbox.stop()
        }
        #expect(mailbox.nextHeldKey(at: 10_000) == command(.release))
        #expect(mailbox.nextHeldKey(at: 20_000) == nil)
        #expect(mailbox.state.withLock { $0.held.isEmpty })
    }

    @Test func anInterruptionBeforeThePressSendsNothingAtAll() {
        let mailbox = mailbox([binding(.shortcut(output))])
        #expect(mailbox.handle(event(.down), secureInput: false))
        mailbox.setEditing(true)
        #expect(mailbox.nextHeldKey(at: 0) == nil)
        #expect(mailbox.state.withLock { $0.held.isEmpty && $0.pending.isEmpty })
    }

    @Test func aStepActionRepeatsThroughTheOrdinaryQueueAndStopsOnRelease() {
        let mailbox = mailbox([binding(.system(.volumeUp))])
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 1000) == nil)
        #expect(mailbox.nextHeldKey(at: 1200) == nil)
        #expect(mailbox.nextHeldKey(at: 1500) == nil)
        #expect(mailbox.state.withLock { $0.pending } == [.system(.volumeUp), .system(.volumeUp)])
        #expect(mailbox.handle(event(.up), secureInput: false))
        #expect(mailbox.nextHeldKey(at: 1700) == nil)
        #expect(mailbox.nextHeldKey(at: 9000) == nil)
        #expect(mailbox.state.withLock { $0.pending.count == 2 && $0.held.isEmpty })
    }

    @Test func theWorkerReleasesAHeldKeyEvenWhenSecureInputBegins() {
        let mailbox = mailbox([binding(.shortcut(output))])
        let sent = Mutex<[HeldKeyCommand.Phase]>([])
        let secure = Mutex(false)
        let worker = ActionWorker(mailbox: mailbox,
            capabilities: { AudioOutputCapabilities(deviceID: 1, volume: true, mute: true) },
            sendShortcut: { _ in Issue.record("A held key is not a pulse"); return false },
            sendHeldKey: { command in sent.withLock { $0.append(command.phase) } },
            secureInput: { secure.withLock { $0 } }, postingAllowed: { true })
        #expect(mailbox.handle(event(.down), secureInput: false))
        worker.service(at: 0)
        secure.withLock { $0 = true }
        worker.service(at: 1)
        worker.service(at: 2)
        #expect(sent.withLock { $0 } == [.press, .release])
    }

    @Test func heldOutputIsLimitedToPressedKeysAndButtonsWithHoldableActions() throws {
        #expect(binding(.shortcut(output), trigger: .key(0)).isValid)
        #expect(binding(.system(.volumeDown)).isValid)
        #expect(binding(.system(.toggleMute)).isValid == false)
        #expect(binding(.lockScreen).isValid == false)
        #expect(binding(.shortcut(output), trigger: .scroll(.up)).isValid == false)
        // After a hold the trigger is still down, so its output may be held too; a double press is not.
        var hold = binding(.shortcut(output))
        hold.activation = .hold
        #expect(hold.isValid)
        hold.activation = .doublePress
        #expect(hold.isValid == false)
        // A gesture button decides its click on release, so it cannot also hold an output.
        let gesture = rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: 3, direction: .left), modifiers: [],
                                     action: .shortcut(output))
        #expect(InputMatcher.compile([gesture, binding(.shortcut(output))]).isEmpty)
        #expect(throws: ConfigurationError.conflict) {
            try Configuration(bindings: [gesture, binding(.shortcut(output))]).validate()
        }
    }

    @Test func theFlagPersistsAndOlderSchemasCannotCarryIt() throws {
        let configuration = Configuration(isEnabled: true, bindings: [binding(.shortcut(output))])
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(decoded == configuration && decoded.bindings[0].holdsOutput)
        var old = configuration
        old.schemaVersion = 33
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }

    @Test func systemKeyRepeatValuesAreBounded() {
        #expect(AppModel.keyRepeat(delay: 0.5, interval: 0.083)
            == KeyRepeatTiming(delayNanoseconds: 500_000_000, intervalNanoseconds: 83_000_000))
        #expect(AppModel.keyRepeat(delay: 0, interval: 0)
            == KeyRepeatTiming(delayNanoseconds: 200_000_000, intervalNanoseconds: 30_000_000))
        #expect(AppModel.keyRepeat(delay: .nan, interval: .infinity)
            == KeyRepeatTiming(delayNanoseconds: 500_000_000, intervalNanoseconds: 80_000_000))
    }
}
