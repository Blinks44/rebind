import Foundation
import Testing
@testable import rebind

@MainActor struct ExcludedApplicationTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private let game = ApplicationTarget(url: URL(filePath: "/Applications/Game.app"), bundleIdentifier: "com.example.game")

    private func configuration() -> Configuration {
        var configuration = Configuration(isEnabled: true, bindings: [
            rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .shortcut(output))])
        configuration.excludedApplications = [game]
        return configuration
    }

    private func mailbox() -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration())
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }

    private func event(_ phase: InputEvent.Phase) -> InputEvent { InputEvent(trigger: .mouseButton(3), phase: phase) }

    @Test func inputPassesThroughOnlyWhileAnExcludedAppIsInFront() {
        let mailbox = mailbox()
        mailbox.setForegroundApplication("com.apple.Safari")
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.handle(event(.up), secureInput: false))
        mailbox.setForegroundApplication(game.bundleIdentifier)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.enabled })
        #expect(mailbox.handle(event(.down), secureInput: false) == false)
        #expect(mailbox.handle(event(.up), secureInput: false) == false)
        #expect(mailbox.trackpadRuntime() == nil)
        mailbox.setForegroundApplication(nil)
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
    }

    @Test func enteringAnExcludedAppKeepsTheReleaseOfASwallowedPressAndDropsQueuedWork() throws {
        let mailbox = mailbox()
        #expect(mailbox.handle(event(.down), secureInput: false))
        let dispatch = try #require(mailbox.nextAction())
        mailbox.setForegroundApplication(game.bundleIdentifier)
        #expect(mailbox.dispatchIsCurrent(dispatch) == false)
        #expect(mailbox.handle(event(.up), secureInput: false))
    }

    @Test func theListPersistsRejectsDuplicatesAndRebindItselfAndOldSchemasCannotCarryIt() throws {
        let configuration = configuration()
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(decoded == configuration)
        var invalid = configuration
        invalid.excludedApplications.append(game)
        #expect(throws: ConfigurationError.invalid) { try invalid.validate() }
        invalid.excludedApplications = [ApplicationTarget(url: URL(filePath: "/Applications/Rebind.app"),
                                                          bundleIdentifier: "blinks44.rebind")]
        #expect(throws: ConfigurationError.invalid) { try invalid.validate() }
        var old = configuration
        old.schemaVersion = 33
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }

    @Test func theModelAddsAndRemovesAppsThroughStorage() throws {
        let store = ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindExcluded-\(UUID())").appending(path: "config.json"))
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let model = AppModel(store: store, loadConfiguration: false)
        #expect(model.excludeApplication(game))
        #expect(model.excludeApplication(game) == false)
        #expect(try store.load().excludedApplications == [game])
        #expect(model.mailbox.state.withLock { $0.excludedApplications } == [game.bundleIdentifier])
        model.includeApplication(game.bundleIdentifier)
        #expect(try store.load().excludedApplications.isEmpty)
    }
}
