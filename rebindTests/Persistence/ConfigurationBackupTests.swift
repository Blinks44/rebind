import Foundation
import Testing
@testable import rebind

struct ConfigurationBackupTests {
    @Test func roundtripPreservesAllProfilesRulesAndPreferences() throws {
        var rule = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: [.control, .option],
            action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: [.command, .shift])))
        rule.activation = .hold
        rule.holdDurationMilliseconds = 575
        var configuration = Configuration(isEnabled: true, bindings: [rule])
        configuration.hasCompletedSetup = true
        configuration.languagePreference = .de
        try configuration.createProfile(name: "Travail — Arbeit", copying: configuration.selectedProfileID)
        configuration.bindings[0].isEnabled = false
        let backup = try ConfigurationBackup(configuration: configuration)
        let decoded = try ConfigurationBackup(data: backup.encoded())
        #expect(decoded.configuration == configuration)
        #expect(decoded.profileCount == 2)
        #expect(decoded.bindingCount == 2)
    }

    @Test(arguments: 1..<Configuration.currentSchemaVersion)
    func legacyBackupsMigrateInMemoryAndKeepSourceUnchanged(_ version: Int) throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "legacy.json")
        let legacy = Configuration(schemaVersion: version, isEnabled: true)
        let original = try JSONEncoder().encode(legacy)
        try original.write(to: url)
        let backup = try ConfigurationBackup(contentsOf: url)
        #expect(backup.configuration.schemaVersion == Configuration.currentSchemaVersion)
        #expect(backup.configuration.isEnabled)
        #expect(backup.configuration.selectedProfileID == legacy.selectedProfileID)
        #expect(try Data(contentsOf: url) == original)
    }

    @Test(arguments: [0, Configuration.currentSchemaVersion + 1])
    func unsupportedSchemaIsRejectedWithoutChangingEitherFile(_ version: Int) throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appending(path: "unsupported.json")
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        try store.save(Configuration())
        let current = try Data(contentsOf: store.url)
        let original = try JSONEncoder().encode(Configuration(schemaVersion: version))
        try original.write(to: source)
        #expect(throws: ConfigurationError.incompatible) { try ConfigurationBackup(contentsOf: source) }
        #expect(try Data(contentsOf: source) == original)
        #expect(try Data(contentsOf: store.url) == current)
    }

    @Test func conflictingRulesCannotBeStagedOrExported() throws {
        let rule = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: [],
            action: .shortcut(KeyboardShortcut(keyCode: 1, modifiers: .command)))
        var duplicate = rule
        duplicate.id = UUID()
        let configuration = Configuration(bindings: [rule, duplicate])
        let data = try JSONEncoder().encode(configuration)
        #expect(throws: ConfigurationError.conflict) { try ConfigurationBackup(data: data) }
        #expect(throws: ConfigurationError.conflict) { try ConfigurationBackup(configuration: configuration) }
    }

    @Test func invalidProfileSelectionIsRejected() throws {
        var configuration = Configuration()
        configuration.selectedProfileID = UUID()
        #expect(throws: ConfigurationError.profileInvalid) {
            try ConfigurationBackup(data: JSONEncoder().encode(configuration))
        }
    }

    @Test func duplicateRuleIdentitiesAreRejectedAcrossProfiles() throws {
        let rule = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: [],
            action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))
        var configuration = Configuration(bindings: [rule])
        try configuration.createProfile(name: "Other")
        configuration.bindings = [rule]
        #expect(throws: ConfigurationError.invalid) {
            try ConfigurationBackup(data: JSONEncoder().encode(configuration))
        }
    }

    @Test(arguments: [false, true])
    func fileSizeLimitIsEnforcedBeforeDecoding(_ oversized: Bool) throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "backup.json")
        var data = try JSONEncoder().encode(Configuration())
        data.append(Data(repeating: 0x20,
            count: ConfigurationStore.maximumBytes + (oversized ? 1 : 0) - data.count))
        try data.write(to: url)
        if oversized {
            #expect(throws: ConfigurationError.invalid) { try ConfigurationBackup(contentsOf: url) }
        } else {
            #expect(try ConfigurationBackup(contentsOf: url).profileCount == 1)
        }
        #expect(try Data(contentsOf: url) == data)
    }

    @Test func nonRegularFilesAndRemoteURLsAreRejected() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        #expect(throws: ConfigurationError.invalid) { try ConfigurationBackup(contentsOf: directory) }
        let remote = try #require(URL(string: "https://example.invalid/backup.json"))
        #expect(throws: ConfigurationError.invalid) { try ConfigurationBackup(contentsOf: remote) }
    }

    @Test func corruptLocalStorageRemainsProtectedWithSharedCodec() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        let corrupt = Data("{broken".utf8)
        try corrupt.write(to: store.url)
        #expect(throws: DecodingError.self) { try store.load() }
        #expect(try Data(contentsOf: store.url) == corrupt)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindBackup-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
