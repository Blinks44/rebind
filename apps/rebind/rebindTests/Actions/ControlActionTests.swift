import Foundation
import Testing
@testable import rebind

@MainActor struct ControlActionTests {
    private func binding(_ action: RebindAction) -> rebind.Binding {
        rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: action)
    }

    private func mailbox(_ action: RebindAction) -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding(action)]))
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }

    private func worker(_ mailbox: EngineMailbox) -> ActionWorker {
        ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
                     sendShortcut: { _ in Issue.record("Nothing may be posted"); return false },
                     secureInput: { false }, postingAllowed: { true })
    }

    private func event(_ phase: InputEvent.Phase) -> InputEvent { InputEvent(trigger: .mouseButton(3), phase: phase) }

    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindControl-\(UUID())").appending(path: "config.json"))
    }

    @Test func everyControlKindRoundTripsThroughTheCatalog() {
        #expect(ActionKind.doNothing.configuredAction(shortcut: nil) == .doNothing)
        #expect(ActionKind(action: .doNothing) == .doNothing)
        for kind in [ActionKind.pauseRebind, .nextProfile, .previousProfile] {
            let action = kind.configuredAction(shortcut: nil)
            #expect(action.map(ActionKind.init(action:)) == kind)
            #expect(kind.category == .rebind)
        }
    }

    @Test func doNothingSwallowsThePressAndItsReleaseWithoutOutputOrFailure() {
        let mailbox = mailbox(.doNothing)
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.handle(event(.up), secureInput: false))
        worker(mailbox).service(at: 0)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.actionFailed == nil && $0.status == .active })
    }

    @Test func pauseStopsMatchingButStillOwnsTheReleaseOfItsOwnPress() {
        let mailbox = mailbox(.control(.pause))
        #expect(mailbox.handle(event(.down), secureInput: false))
        worker(mailbox).service(at: 0)
        #expect(mailbox.state.withLock { !$0.enabled && $0.emergencyPause })
        #expect(mailbox.handle(event(.up), secureInput: false))
        #expect(mailbox.handle(event(.down), secureInput: false) == false)
    }

    @Test func aStaleProfileStepIsDropped() throws {
        let mailbox = mailbox(.control(.nextProfile))
        #expect(mailbox.handle(event(.down), secureInput: false))
        let dispatch = try #require(mailbox.nextAction())
        mailbox.setEditing(true)
        mailbox.requestControl(.nextProfile, for: dispatch)
        #expect(mailbox.state.withLock { $0.profileStep } == 0)
    }

    @Test func profileStepsWrapAroundAndPersistTheSelection() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var configuration = Configuration(isEnabled: true, bindings: [binding(.control(.nextProfile))])
        try configuration.createProfile(name: "Second", copying: RuleProfile.defaultID)
        try configuration.selectProfile(RuleProfile.defaultID)
        try store.save(configuration)
        let model = AppModel(store: store)
        let second = model.configuration.profiles[1].id
        for expected in [second, RuleProfile.defaultID] {
            model.mailbox.configure(model.configuration)
            model.mailbox.state.withLock { $0.status = .active }
            #expect(model.mailbox.handle(event(.down), secureInput: false))
            #expect(model.mailbox.handle(event(.up), secureInput: false))
            worker(model.mailbox).service(at: 0)
            model.refresh()
            #expect(model.configuration.selectedProfileID == expected)
        }
        #expect(try store.load().selectedProfileID == RuleProfile.defaultID)
    }

    @Test func olderSchemasCannotContainControlActions() throws {
        var old = Configuration(schemaVersion: 33, isEnabled: true, bindings: [binding(.doNothing)])
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
        old.bindings[0].action = .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command))
        #expect(try old.migrated().schemaVersion == Configuration.currentSchemaVersion)
    }
}
