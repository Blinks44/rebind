import Foundation
import Testing
@testable import rebind

struct ConfigurationMigrationTests {
    private func temporaryStore() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindMigration-\(UUID())", directoryHint: .isDirectory)
            .appending(path: "configuration.json"))
    }

    @Test func version1MigratesWithoutRewritingOrLosingIdentity() throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let bytes = Data(ConfigurationFixtures.version1.utf8)
        try bytes.write(to: store.url)
        let configuration = try store.load()
        #expect(configuration.schemaVersion == Configuration.currentSchemaVersion)
        #expect(configuration.isEnabled)
        #expect(configuration.bindings.count == 2)
        let keyboard = try #require(configuration.bindings.first)
        #expect(keyboard.id.uuidString == "00000000-0000-0000-0000-000000000001")
        #expect(keyboard.trigger == .key(0))
        #expect(keyboard.modifiers == [.control, .option])
        #expect(keyboard.action.shortcut == KeyboardShortcut(keyCode: 13, modifiers: .command))
        let mouse = try #require(configuration.bindings.last)
        #expect(mouse.id.uuidString == "00000000-0000-0000-0000-000000000002")
        #expect(mouse.trigger == .mouseButton(3))
        #expect(mouse.isEnabled == false)
        #expect(try Data(contentsOf: store.url) == bytes)
        try store.save(configuration)
        #expect(try JSONDecoder().decode(Configuration.self, from: Data(contentsOf: store.url)).schemaVersion == Configuration.currentSchemaVersion)
        #expect(try store.load() == configuration)
    }

    @Test(arguments: ScrollDirection.allCases)
    func wheelRulesRoundTripWithCurrentVersion(_ direction: ScrollDirection) throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allMice, trigger: .scroll(direction), modifiers: [.control, .option],
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        let configuration = Configuration(isEnabled: true, bindings: [binding])
        try store.save(configuration)
        #expect(try store.load() == configuration)
    }

    @Test func futureVersionAndDisguisedWheelDataAreRejected() {
        #expect(throws: ConfigurationError.incompatible) { try Configuration(schemaVersion: Configuration.currentSchemaVersion + 1).migrated() }
        let binding = rebind.Binding(scope: .allMice, trigger: .scroll(.up), modifiers: [],
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        #expect(throws: ConfigurationError.invalid) { try Configuration(schemaVersion: 1, bindings: [binding]).migrated() }
    }

    @Test func wheelConflictsAndWrongScopesCannotReplaceSavedRules() throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let original = Configuration()
        try store.save(original)
        let binding = rebind.Binding(scope: .allMice, trigger: .scroll(.up), modifiers: .control,
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        var duplicate = binding
        duplicate.id = UUID()
        #expect(throws: ConfigurationError.conflict) { try store.save(Configuration(bindings: [binding, duplicate])) }
        var wrongScope = binding
        wrongScope.scope = .allKeyboards
        #expect(throws: ConfigurationError.invalid) { try store.save(Configuration(bindings: [wrongScope])) }
        #expect(try store.load() == original)
    }
}
