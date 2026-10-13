import Foundation
import Testing
@testable import rebind

struct ConfigurationStoreProtectionTests {
    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindProtectedSave-\(UUID())/configuration.json"))
    }

    @Test(arguments: [Data("{broken".utf8), Data("{\"schemaVersion\":999}".utf8),
                      Data(repeating: 0x20, count: ConfigurationStore.maximumBytes + 1)])
    func saveCannotReplaceAnOriginalChangedAfterLoad(_ bytes: Data) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration())
        var loaded = try store.load()
        loaded.isEnabled = true
        try bytes.write(to: store.url, options: .atomic)
        #expect(throws: ConfigurationStoreError.protectedOriginal) { try store.save(loaded) }
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test func directoryWriteFailureCanBeRepairedAndRetried() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: true)
        do {
            try store.save(Configuration())
            Issue.record("A directory must not be replaced with a configuration")
        } catch {
            #expect((error as? ConfigurationStoreError) == nil)
        }
        try FileManager.default.removeItem(at: store.url)
        let expected = Configuration(isEnabled: true)
        try store.save(expected)
        #expect(try store.load() == expected)
    }

    @Test(arguments: 1...23)
    func validLegacyOriginalStillAllowsExplicitSave(_ version: Int) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let legacy = Configuration(schemaVersion: version)
        let original = try JSONEncoder().encode(legacy)
        try original.write(to: store.url)
        var loaded = try store.load()
        #expect(try Data(contentsOf: store.url) == original)
        loaded.isEnabled = true
        try store.save(loaded)
        #expect(try store.load() == loaded)
        #expect(loaded.schemaVersion == Configuration.currentSchemaVersion)
    }
}
