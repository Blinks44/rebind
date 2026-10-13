import Foundation
import Testing
@testable import rebind

struct TrackpadSingleTapPersistenceTests {
    private func binding(_ tap: TrackpadSingleTap) -> rebind.Binding {
        .init(scope: .builtInTrackpad, trigger: tap.trigger, modifiers: [],
              action: .shortcut(.init(keyCode: 13, modifiers: .command)))
    }

    @Test func bothPresetsRoundTripAndConflictsRemainIndependent() throws {
        var config = Configuration(isEnabled: true, bindings: TrackpadSingleTap.allCases.map(binding))
        config.hasCompletedSetup = true
        config.languagePreference = .de
        try config.createProfile(name: "Other", copying: config.selectedProfileID)
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(config)).migrated()
        #expect(decoded == config)
        try decoded.validate()
        var duplicate = binding(.threeFinger)
        duplicate.id = UUID()
        var invalid = config
        invalid.bindings.append(duplicate)
        #expect(throws: ConfigurationError.conflict) { try invalid.validate() }
    }

    @Test func schema24MigrationPreservesRulesPreferencesSelectionAndPause() throws {
        var old = Configuration(isEnabled: false, bindings: [binding(.fourFinger)])
        old.hasCompletedSetup = true
        old.languagePreference = .fr
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 24
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old)).migrated()
        #expect(decoded.schemaVersion == Configuration.currentSchemaVersion)
        #expect(decoded.profiles == old.profiles)
        #expect(decoded.selectedProfileID == old.selectedProfileID)
        #expect(decoded.isEnabled == false)
        #expect(decoded.hasCompletedSetup == old.hasCompletedSetup)
        #expect(decoded.languagePreference == old.languagePreference)
    }

    @Test(arguments: 1...24)
    func historicalSchemasRejectThreeFingerPayloadEvenInInactiveProfiles(_ version: Int) throws {
        var old = Configuration(schemaVersion: version, bindings: version < 6 ? [binding(.threeFinger)] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding(.threeFinger)])) }
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test(arguments: TrackpadSingleTap.allCases, 0...4)
    func unsupportedTouchVariantsRemainInvalid(_ tap: TrackpadSingleTap, _ variant: Int) {
        var invalid = binding(tap)
        switch variant {
        case 0: invalid.modifiers = [.control, .shift]
        case 1: invalid.activation = .doublePress
        case 2: invalid.activation = .hold
        case 3: invalid.action = .shortcut(.init(keyCode: 57, modifiers: []))
        default: invalid.scope = .allMice
        }
        #expect(invalid.isValid == false)
    }
}
