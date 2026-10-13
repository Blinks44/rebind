import Foundation
import Testing
@testable import rebind

struct WindowCyclePersistenceTests {
    @Test(arguments: 1...19) func earlierSchemasRejectCycleIncludingInactiveProfiles(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .windowCycle(.next))
        var old = Configuration(bindings: version < 6 ? [binding] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding])) }
        old.schemaVersion = version
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func schema19ProfilesActionsAndFileBytesRemainUntilExplicitSave() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindCycleStore-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: directory.appending(path: "config.json"))
        var old = Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
            action: .lockScreen, activation: .hold, holdDurationMilliseconds: 1000)])
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.bindings[0].action = .sleepSystem
        old.schemaVersion = 19
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var loaded = try store.load()
        #expect(loaded.profiles == old.profiles && loaded.selectedProfileID == old.selectedProfileID && loaded.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        loaded.bindings[0].action = .windowCycle(.previous)
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }
}
