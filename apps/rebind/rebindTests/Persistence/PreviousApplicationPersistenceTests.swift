import Foundation
import Testing
@testable import rebind

struct PreviousApplicationPersistenceTests {
    @Test(arguments: 1...20) func earlierSchemasRejectSwitchingInEveryProfile(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .workspace(.previousApplication))
        var old = Configuration(bindings: version < 6 ? [binding] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding])) }
        old.schemaVersion = version
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func schema20RetainsProfilesAndDoesNotRewriteUntilExplicitSave() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindAppSwitchStore-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: directory.appending(path: "config.json"))
        var old = Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
            action: .windowCycle(.next), activation: .hold, holdDurationMilliseconds: 1000)])
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.bindings[0].action = .lockScreen
        old.schemaVersion = 20
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var loaded = try store.load()
        #expect(loaded.profiles == old.profiles && loaded.selectedProfileID == old.selectedProfileID && loaded.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        loaded.bindings[0].action = .workspace(.previousApplication)
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }
}
