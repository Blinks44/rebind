import Foundation
import Testing
@testable import rebind

struct TrackpadDoubleTapPersistenceTests {
    private let doubles: [InputTrigger] = [.threeFingerDoubleTap, .fourFingerDoubleTap, .twoFingerDoubleTap]

    private func binding(_ trigger: InputTrigger) -> rebind.Binding {
        .init(scope: .builtInTrackpad, trigger: trigger, modifiers: [],
              action: .shortcut(.init(keyCode: 13, modifiers: .command)))
    }

    @Test func allDoubleRulesRoundTripWithoutColliding() throws {
        let triggers: [InputTrigger] = [.threeFingerTap, .fourFingerTap] + doubles
        var config = Configuration(isEnabled: true, bindings: triggers.map(binding))
        config.hasCompletedSetup = true
        config.languagePreference = .ru
        try config.createProfile(name: "Other", copying: config.selectedProfileID)
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(config)).migrated()
        #expect(decoded == config)
        try decoded.validate()
        for trigger in doubles {
            var invalid = config
            invalid.bindings.append(binding(trigger))
            #expect(throws: ConfigurationError.conflict) { try invalid.validate() }
        }
    }

    @Test func schema25MigrationPreservesSingleRulesProfilesPreferencesAndPause() throws {
        var old = Configuration(isEnabled: false, bindings: [.threeFingerTap, .fourFingerTap].map(binding))
        old.hasCompletedSetup = true
        old.languagePreference = .de
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 25
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old)).migrated()
        var expected = old
        expected.schemaVersion = Configuration.currentSchemaVersion
        #expect(decoded == expected)
    }

    @Test func schema26MigrationPreservesDoubleRulesAndRejectsTwoFingerDouble() throws {
        var old = Configuration(isEnabled: false, bindings: [.threeFingerDoubleTap, .fourFingerDoubleTap].map(binding))
        old.hasCompletedSetup = true
        old.languagePreference = .de
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 26
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old)).migrated()
        var expected = old
        expected.schemaVersion = Configuration.currentSchemaVersion
        #expect(decoded == expected)
        old.profiles.append(RuleProfile(name: "Future", bindings: [binding(.twoFingerDoubleTap)]))
        let rejected = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try rejected.migrated() }
    }

    @Test(arguments: [.threeFingerDoubleTap, .fourFingerDoubleTap] as [InputTrigger], 1...25)
    func oldSchemasRejectNewPayloadEvenInInactiveProfile(_ trigger: InputTrigger, _ version: Int) throws {
        var old = Configuration(schemaVersion: version, bindings: version < 6 ? [binding(trigger)] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding(trigger)])) }
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test(arguments: [.twoFingerDoubleTap] as [InputTrigger], 1...26)
    func oldSchemasRejectTwoFingerDoublePayload(_ trigger: InputTrigger, _ version: Int) throws {
        var old = Configuration(schemaVersion: version, bindings: version < 6 ? [binding(trigger)] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding(trigger)])) }
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test(arguments: [.threeFingerDoubleTap, .fourFingerDoubleTap, .twoFingerDoubleTap] as [InputTrigger], 0...4)
    func unsupportedModifiersActionsAndActivationStayInvalid(_ trigger: InputTrigger, _ variant: Int) {
        var invalid = binding(trigger)
        switch variant {
        case 0: invalid.modifiers = .option
        case 1: invalid.activation = .doublePress
        case 2: invalid.activation = .hold
        case 3: invalid.action = .lockScreen
        default: invalid.scope = .allMice
        }
        #expect(invalid.isValid == false)
    }

    @Test func corruptOrFutureDoublePayloadCannotMigrate() throws {
        let config = Configuration(bindings: doubles.map(binding))
        let data = try JSONEncoder().encode(config)
        let text = try #require(String(data: data, encoding: .utf8))
        let corrupt = text.replacingOccurrences(of: "threeFingerDoubleTap", with: "fiveFingerDoubleTap")
        #expect(throws: (any Error).self) { _ = try JSONDecoder().decode(Configuration.self, from: Data(corrupt.utf8)) }
        var future = config
        future.schemaVersion = 28
        let encoded = try JSONEncoder().encode(future)
        #expect(throws: ConfigurationError.incompatible) { _ = try JSONDecoder().decode(Configuration.self, from: encoded) }
    }
}
