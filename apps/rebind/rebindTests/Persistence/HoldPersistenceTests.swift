import Foundation
import Testing
@testable import rebind

struct HoldPersistenceTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindHold-\(UUID())", directoryHint: .isDirectory).appending(path: "configuration.json"))
    }

    @Test func schema3DoublePressMigratesWithoutRewritingAndDefaultsThreshold() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let bytes = Data(#"{"schemaVersion":3,"isEnabled":true,"bindings":[{"id":"00000000-0000-0000-0000-000000000004","scope":"allMice","trigger":{"mouseButton":{"_0":3}},"modifiers":2,"action":{"shortcut":{"_0":{"keyCode":0,"modifiers":1}}},"isEnabled":true,"activation":"doublePress"}]}"#.utf8)
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: store.url)
        let migrated = try store.load()
        let binding = try #require(migrated.bindings.first)
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion && migrated.isEnabled)
        #expect(binding.id.uuidString == "00000000-0000-0000-0000-000000000004")
        #expect(binding.activation == .doublePress && binding.holdDurationMilliseconds == 500)
        #expect(binding.action.shortcut == output && binding.modifiers == .control)
        #expect(try Data(contentsOf: store.url) == bytes)
        try store.save(migrated)
        #expect(try store.load() == migrated)
    }

    @Test(arguments: [InputTrigger.key(1), .mouseButton(99)])
    func holdRulesRoundTripWithThresholdAndIdentity(_ trigger: InputTrigger) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control,
                                     action: .shortcut(output), activation: .hold, holdDurationMilliseconds: 700)
        let configuration = Configuration(isEnabled: true, bindings: [binding])
        try store.save(configuration)
        #expect(try store.load() == configuration)
    }

    @Test func invalidThresholdsLegacyHoldsAndWheelHoldCannotOverwriteData() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration())
        let bytes = try Data(contentsOf: store.url)
        let hold = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
                                  action: .shortcut(output), activation: .hold)
        for duration in [UInt32(0), 99, 5001, .max] {
            var invalid = hold
            invalid.holdDurationMilliseconds = duration
            #expect(throws: ConfigurationError.invalid) { try store.save(Configuration(bindings: [invalid])) }
        }
        for version in 1...3 {
            #expect(throws: ConfigurationError.invalid) { try Configuration(schemaVersion: version, bindings: [hold]).migrated() }
        }
        var wheel = hold
        wheel.trigger = .scroll(.up)
        #expect(throws: ConfigurationError.invalid) { try Configuration(bindings: [wheel]).validate() }
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test(arguments: [PressActivation.press, .doublePress])
    func sameChordDifferentActivationIsAnExplicitConflict(_ activation: PressActivation) {
        let hold = rebind.Binding(scope: .allKeyboards, trigger: .key(1), modifiers: .control,
                                  action: .shortcut(output), activation: .hold)
        var other = hold
        other.id = UUID()
        other.activation = activation
        #expect(throws: ConfigurationError.conflict) { try Configuration(bindings: [hold, other]).validate() }
        #expect(InputMatcher.compile([hold, other]).isEmpty)
    }

    @Test(arguments: ["null", "-1", "1.5", "\"500\""])
    func malformedThresholdDoesNotSilentlyDefault(_ value: String) throws {
        let binding = rebind.Binding(scope: .allKeyboards, trigger: .key(1), modifiers: [], action: .shortcut(output))
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(binding)) as? [String: Any])
        object["holdDurationMilliseconds"] = try JSONSerialization.jsonObject(with: Data(value.utf8), options: .fragmentsAllowed)
        let invalid = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(rebind.Binding.self, from: invalid) }
    }
}
