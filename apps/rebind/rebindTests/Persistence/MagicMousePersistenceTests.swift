import Foundation
import Testing

@testable import rebind

struct MagicMousePersistenceTests {
    @Test(arguments: 1...3)
    func categoryAndModifiersRoundTripInTheirIntroducedSchema(_ fingers: Int) throws {
        let rule = rebind.Binding(
            scope: .magicMouse, trigger: .magicMouseTap(fingers: fingers), modifiers: .option,
            action: .shortcut(.init(keyCode: 13, modifiers: .command)))
        let configuration = Configuration(isEnabled: true, bindings: [rule])
        try configuration.validate()
        let copy = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(copy == configuration)
        var old = configuration
        old.schemaVersion = fingers == 3 ? 42 : 41
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

    @Test(arguments: [0, 4, 5])
    func unverifiedFingerCountsAreRejected(_ fingers: Int) {
        let rule = rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: fingers), modifiers: [], action: .doNothing)
        #expect(rule.isValid == false)
    }

    @Test(arguments: [InputTrigger.magicMouseClick(fingers: 3), .magicMouseScroll(.up), .magicMouseScroll(.down)])
    func nativeGesturesRequireSchema44(_ trigger: InputTrigger) throws {
        let rule = rebind.Binding(scope: .magicMouse, trigger: trigger, modifiers: .option, action: .doNothing)
        let configuration = Configuration(isEnabled: true, bindings: [rule])
        try configuration.validate()
        let data = try JSONEncoder().encode(configuration)
        #expect(try JSONDecoder().decode(Configuration.self, from: data) == configuration)
        var old = configuration
        old.schemaVersion = 43
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }

    @Test(arguments: MagicMouseSide.allCases)
    func sideTapsRequireSchema49(_ side: MagicMouseSide) throws {
        let rule = rebind.Binding(scope: .magicMouse, trigger: .magicMouseSideTap(side), modifiers: .option, action: .doNothing)
        let configuration = Configuration(isEnabled: true, bindings: [rule])
        try configuration.validate()
        let data = try JSONEncoder().encode(configuration)
        #expect(try JSONDecoder().decode(Configuration.self, from: data) == configuration)
        var old = configuration
        old.schemaVersion = 48
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
        var invalid = rule
        invalid.scope = .builtInTrackpad
        #expect(invalid.isValid == false)
    }

    @Test(arguments: [
        InputTrigger.magicMouseClick(fingers: 1), .magicMouseClick(fingers: 4), .magicMouseScroll(.left), .magicMouseScroll(.right),
    ])
    func unsupportedNativeGesturesAreRejected(_ trigger: InputTrigger) {
        #expect(trigger.isSupported == false)
    }

    @Test func twoFingerClickRequiresSchema51AndPreservesExistingRules() throws {
        let click = rebind.Binding(scope: .magicMouse, trigger: .magicMouseClick(fingers: 2), modifiers: .option, action: .doNothing)
        let configuration = Configuration(isEnabled: true, bindings: [click])
        try configuration.validate()
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
        var old = configuration
        old.schemaVersion = 50
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
        let existing = rebind.Binding(scope: .magicMouse, trigger: .magicMouseClick(fingers: 3), modifiers: [], action: .doNothing)
        let migrated = try Configuration(schemaVersion: 50, bindings: [existing]).migrated()
        #expect(migrated.bindings == [existing])
    }

    @Test(arguments: [ScrollDirection.up, .down])
    func threeFingerScrollRequiresSchema52AndPreservesTwoFingerIdentity(_ direction: ScrollDirection) throws {
        let rule = rebind.Binding(
            scope: .magicMouse, trigger: .magicMouseThreeFingerScroll(direction), modifiers: .option, action: .doNothing)
        let configuration = Configuration(bindings: [rule])
        try configuration.validate()
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
        var old = configuration
        old.schemaVersion = 51
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
        let twoFinger = rebind.Binding(scope: .magicMouse, trigger: .magicMouseScroll(direction), modifiers: [], action: .doNothing)
        let migrated = try Configuration(schemaVersion: 51, bindings: [twoFinger]).migrated()
        #expect(migrated.bindings == [twoFinger])
        #expect(twoFinger.trigger != rule.trigger)
        #expect(InputTrigger.magicMouseThreeFingerScroll(.left).isSupported == false)
        #expect(InputTrigger.magicMouseThreeFingerScroll(.right).isSupported == false)
    }

    @Test func schema42PreservesExistingMouseTaps() throws {
        let rule = rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: 2), modifiers: .option, action: .doNothing)
        let old = Configuration(schemaVersion: 42, isEnabled: true, bindings: [rule])
        let migrated = try old.migrated()
        #expect(migrated.bindings == [rule] && migrated.schemaVersion == Configuration.currentSchemaVersion)
    }

    @Test func oldTrackpadAndMouseRulesMigrateWithoutChangingTheirCategories() throws {
        let rules = [
            rebind.Binding(scope: .builtInTrackpad, trigger: .threeFingerTap, modifiers: [], action: .doNothing),
            .init(scope: .magicTrackpad, trigger: .threeFingerTap, modifiers: [], action: .doNothing),
            .init(scope: .allMice, trigger: .mouseButton(2), modifiers: [], action: .doNothing),
        ]
        var old = Configuration(isEnabled: true, bindings: rules)
        old.schemaVersion = 41
        let migrated = try old.migrated()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion && migrated.bindings == rules && migrated.isEnabled)
    }
}
