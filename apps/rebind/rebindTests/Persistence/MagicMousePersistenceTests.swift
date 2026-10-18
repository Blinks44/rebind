import Foundation
import Testing
@testable import rebind

struct MagicMousePersistenceTests {
    @Test(arguments: 1...2)
    func categoryAndModifiersRoundTripOnlyInSchema42(_ fingers: Int) throws {
        let rule = rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: fingers), modifiers: .option,
                                  action: .shortcut(.init(keyCode: 13, modifiers: .command)))
        let configuration = Configuration(isEnabled: true, bindings: [rule])
        try configuration.validate()
        let copy = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(copy == configuration)
        var old = configuration
        old.schemaVersion = 41
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
        var invalid = rule
        invalid.scope = .allMice
        #expect(invalid.isValid == false)
        invalid = rule
        invalid.modifiers = [.command, .shift]
        #expect(invalid.isValid == false)
        invalid = rule
        invalid.activation = .doublePress
        #expect(invalid.isValid == false)
        invalid = rule
        invalid.holdsOutput = true
        #expect(invalid.isValid == false)
    }

    @Test(arguments: [0, 3, 4, 5])
    func unverifiedFingerCountsAreRejected(_ fingers: Int) {
        let rule = rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: fingers), modifiers: [], action: .doNothing)
        #expect(rule.isValid == false)
    }

    @Test func oldTrackpadAndMouseRulesMigrateWithoutChangingTheirCategories() throws {
        let rules = [rebind.Binding(scope: .builtInTrackpad, trigger: .threeFingerTap, modifiers: [], action: .doNothing),
                     .init(scope: .magicTrackpad, trigger: .threeFingerTap, modifiers: [], action: .doNothing),
                     .init(scope: .allMice, trigger: .mouseButton(2), modifiers: [], action: .doNothing)]
        var old = Configuration(isEnabled: true, bindings: rules)
        old.schemaVersion = 41
        let migrated = try old.migrated()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion && migrated.bindings == rules && migrated.isEnabled)
    }
}
