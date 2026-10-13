import Foundation
import Testing
@testable import rebind

struct ProfileConfigurationTests {
    private func rule() -> rebind.Binding {
        rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: .control,
                       action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))
    }

    @Test(arguments: 1...5)
    func legacyRulesMigrateIntoStableDefaultProfileWithoutDataLoss(_ version: Int) throws {
        var binding = rule()
        if version == 4 { binding.activation = .hold; binding.holdDurationMilliseconds = 1000 }
        if version == 5 { binding.trigger = .mouseGesture(button: 99, direction: .left) }
        let legacy = Configuration(schemaVersion: version, isEnabled: true, bindings: [binding])
        let bytes = try JSONEncoder().encode(legacy)
        let decoded = try JSONDecoder().decode(Configuration.self, from: bytes)
        let migrated = try decoded.migrated()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion)
        #expect(migrated.isEnabled)
        #expect(migrated.selectedProfileID == RuleProfile.defaultID)
        #expect(migrated.profiles.count == 1)
        #expect(migrated.profiles.first?.name == nil)
        #expect(migrated.bindings == [binding])
        #expect(try JSONDecoder().decode(Configuration.self, from: bytes).migrated() == migrated)
    }

    @Test func loadingLegacyFileNeverWritesMigrationUntilExplicitSave() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindProfiles-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: directory.appending(path: "config.json"))
        let original = try JSONEncoder().encode(Configuration(schemaVersion: 5, bindings: [rule()]))
        try original.write(to: store.url)
        var configuration = try store.load()
        #expect(try Data(contentsOf: store.url) == original)
        try configuration.createProfile(name: "Travel", copying: configuration.selectedProfileID)
        configuration.isEnabled = true
        try store.save(configuration)
        #expect(try store.load() == configuration)
        let json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: store.url)) as? [String: Any])
        #expect(json["bindings"] == nil)
        #expect((json["profiles"] as? [Any])?.count == 2)
    }

    @Test func emptyProfileSwitchAndEditingLeaveOtherRulesIntact() throws {
        let binding = rule()
        var configuration = Configuration(isEnabled: true, bindings: [binding])
        let originalID = configuration.selectedProfileID
        try configuration.createProfile(name: "  Work  ")
        let workID = configuration.selectedProfileID
        #expect(configuration.selectedProfile?.name == "Work")
        #expect(configuration.bindings.isEmpty)
        configuration.bindings = [rule()]
        let workRules = configuration.bindings
        try configuration.selectProfile(originalID)
        #expect(configuration.bindings == [binding])
        try configuration.selectProfile(workID)
        #expect(configuration.bindings == workRules)
        #expect(configuration.isEnabled)
    }

    @Test func copyingAssignsNewRuleIDsAndRetainsTriggerActionAndFlags() throws {
        var binding = rule()
        binding.isEnabled = false
        binding.activation = .hold
        binding.holdDurationMilliseconds = 1200
        var configuration = Configuration(bindings: [binding])
        try configuration.createProfile(name: "Mouse B", copying: configuration.selectedProfileID)
        var copied = try #require(configuration.bindings.first)
        #expect(copied.id != binding.id)
        copied.id = binding.id
        #expect(copied == binding)
        #expect(configuration.profiles.first?.bindings == [binding])
        try configuration.validate()
    }

    @Test func sameTriggerInDifferentProfilesIsValidButInactiveConflictsAreRejected() throws {
        var configuration = Configuration(bindings: [rule()])
        try configuration.createProfile(name: "Second", copying: configuration.selectedProfileID)
        try configuration.validate()
        var duplicate = try #require(configuration.profiles[0].bindings.first)
        duplicate.id = UUID()
        configuration.profiles[0].bindings.append(duplicate)
        #expect(throws: ConfigurationError.conflict) { try configuration.validate() }
    }

    @Test(arguments: ["", "   ", "bad\nname", String(repeating: "a", count: 81)])
    func invalidNamesCannotPartiallyMutateProfiles(_ name: String) {
        var configuration = Configuration()
        let original = configuration
        #expect(throws: ConfigurationError.profileInvalid) { try configuration.createProfile(name: name) }
        #expect(configuration == original)
        #expect(throws: ConfigurationError.profileInvalid) { try configuration.renameProfile(configuration.selectedProfileID, name: name) }
        #expect(configuration == original)
    }

    @Test func namesAreUniqueWithoutCaseOrAccentAndIDsAreValidated() throws {
        var configuration = Configuration()
        try configuration.createProfile(name: "Café")
        let original = configuration
        #expect(throws: ConfigurationError.profileInvalid) { try configuration.createProfile(name: "CAFE") }
        #expect(configuration == original)
        #expect(throws: ConfigurationError.profileInvalid) { try configuration.selectProfile(UUID()) }
        #expect(configuration == original)
        configuration.profiles[1].id = configuration.profiles[0].id
        #expect(throws: ConfigurationError.profileInvalid) { try configuration.validate() }
    }

    @Test func boundedProfileCountAndFinalProfileCannotBeRemoved() throws {
        var configuration = Configuration()
        #expect(throws: ConfigurationError.lastProfile) { try configuration.deleteProfile(configuration.selectedProfileID) }
        for index in 1..<Configuration.maximumProfiles { try configuration.createProfile(name: "Profile \(index)") }
        let full = configuration
        #expect(throws: ConfigurationError.profileLimit) { try configuration.createProfile(name: "Overflow") }
        #expect(configuration == full)
        try configuration.deleteProfile(configuration.selectedProfileID)
        #expect(configuration.profiles.count == Configuration.maximumProfiles - 1)
        #expect(configuration.selectedProfileID == RuleProfile.defaultID)
        #expect(configuration.isEnabled == false)
    }

    @Test func deletingInactiveAndRenamingPreserveSelectionAndEnabledState() throws {
        var configuration = Configuration(isEnabled: true, bindings: [rule()])
        let originalID = configuration.selectedProfileID
        try configuration.createProfile(name: "Other")
        let active = configuration.selectedProfileID
        try configuration.renameProfile(active, name: "Renamed")
        try configuration.deleteProfile(originalID)
        #expect(configuration.selectedProfileID == active)
        #expect(configuration.selectedProfile?.name == "Renamed")
        #expect(configuration.isEnabled)
    }

    @Test func malformedSelectionAndMixedSchemasDoNotReplaceSavedRules() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindProfileCorrupt-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "config.json"))
        let configuration = Configuration(bindings: [rule()])
        try store.save(configuration)
        let bytes = try Data(contentsOf: store.url)
        var invalid = configuration
        invalid.selectedProfileID = UUID()
        #expect(throws: ConfigurationError.profileInvalid) { try store.save(invalid) }
        #expect(try Data(contentsOf: store.url) == bytes)
        var json = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        json["bindings"] = []
        #expect(throws: ConfigurationError.invalid) { try JSONDecoder().decode(Configuration.self, from: JSONSerialization.data(withJSONObject: json)) }
        json.removeValue(forKey: "bindings")
        json["schemaVersion"] = 5
        json["bindings"] = []
        #expect(throws: ConfigurationError.invalid) { try JSONDecoder().decode(Configuration.self, from: JSONSerialization.data(withJSONObject: json)) }
    }
}
