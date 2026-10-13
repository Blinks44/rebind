import Foundation
import Testing
@testable import rebind

struct ConfigurationTests {
    private func temporaryStore() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory.appending(path: "RebindTests-\(UUID())", directoryHint: .isDirectory).appending(path: "configuration.json"))
    }

    @Test func roundTripPreservesPhysicalIdentityAndEnabledState() throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: [.control, .option],
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: [.command, .shift])))
        let original = Configuration(isEnabled: true, bindings: [binding])
        try store.save(original)
        #expect(try store.load() == original)
        var updated = original
        updated.isEnabled = false
        try store.save(updated)
        #expect(try store.load() == updated)
    }

    @Test func missingConfigurationStartsPaused() throws {
        #expect(try temporaryStore().load() == Configuration())
    }

    @Test @MainActor func unreadableConfigurationLocksEditingWithoutOverwriting() throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let bytes = Data("{broken".utf8)
        try bytes.write(to: store.url)
        let model = AppModel(store: store)
        #expect(model.storageLocked)
        #expect(model.configuration.isEnabled == false)
        let binding = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: [],
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        #expect(model.saveBinding(binding) == false)
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test(arguments: ["{broken", "{\"schemaVersion\":99,\"isEnabled\":true,\"bindings\":[]}"])
    func unreadableFilesRemainUntouched(_ text: String) throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let bytes = Data(text.utf8)
        try bytes.write(to: store.url)
        #expect(throws: (any Error).self) { try store.load() }
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test func conflictingSaveDoesNotReplaceValidConfiguration() throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: [],
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        let original = Configuration(bindings: [binding])
        try store.save(original)
        var duplicate = binding
        duplicate.id = UUID()
        #expect(throws: ConfigurationError.conflict) { try store.save(Configuration(bindings: [binding, duplicate])) }
        #expect(try store.load() == original)
    }

    @Test(arguments: [UInt16(54), 55, 57, 63, 128, .max])
    func unsupportedKeysCannotBeStored(_ key: UInt16) {
        let invalid = rebind.Binding(scope: .allKeyboards, trigger: .key(key), modifiers: [],
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        #expect(throws: ConfigurationError.invalid) { try Configuration(bindings: [invalid]).validate() }
    }
}
