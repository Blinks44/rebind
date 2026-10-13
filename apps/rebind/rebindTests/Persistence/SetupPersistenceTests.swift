import Foundation
import Testing
@testable import rebind

struct SetupPersistenceTests {
    @Test(arguments: 1...22)
    func existingSchemasAreAcknowledgedWithoutChangingRulesOrIntent(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: .option,
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        let legacy = Configuration(schemaVersion: version, isEnabled: true, bindings: [binding])
        let data = try JSONEncoder().encode(legacy)
        let decoded = try JSONDecoder().decode(Configuration.self, from: data)
        let migrated = try decoded.migrated()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion)
        #expect(migrated.hasCompletedSetup)
        #expect(migrated.bindings == legacy.bindings)
        #expect(migrated.selectedProfileID == legacy.selectedProfileID)
        #expect(migrated.isEnabled == legacy.isEnabled)
    }

    @Test(arguments: [false, true])
    func currentSchemaRoundTripsSetupAcknowledgement(_ completed: Bool) throws {
        var configuration = Configuration()
        configuration.hasCompletedSetup = completed
        let data = try JSONEncoder().encode(configuration)
        #expect(try JSONDecoder().decode(Configuration.self, from: data).migrated() == configuration)
    }

    @Test func currentSchemaRequiresValidSetupField() throws {
        let data = try JSONEncoder().encode(Configuration())
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "hasCompletedSetup")
        let missing = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(Configuration.self, from: missing) }
        object["hasCompletedSetup"] = "true"
        let wrongType = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(Configuration.self, from: wrongType) }
    }

    @Test func schema22TrackpadRulesMigrateWithoutAWrite() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindSetupMigration-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: directory.appending(path: "config.json"))
        let binding = rebind.Binding(scope: .builtInTrackpad, trigger: .fourFingerTap, modifiers: [],
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        let legacy = Configuration(schemaVersion: 22, isEnabled: true, bindings: [binding])
        let bytes = try JSONEncoder().encode(legacy)
        try bytes.write(to: store.url)
        let migrated = try store.load()
        #expect(migrated.hasCompletedSetup)
        #expect(migrated.bindings == [binding])
        #expect(migrated.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
    }
}
