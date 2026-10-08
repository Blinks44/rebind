import Foundation
import Testing
@testable import rebind

struct PressActivationPersistenceTests {
    private let output = KeyboardShortcut(keyCode: 13, modifiers: .command)
    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindActivation-\(UUID())", directoryHint: .isDirectory).appending(path: "configuration.json"))
    }

    @Test func literalVersion2WheelMigratesWithoutRewriting() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        // Literal shipped schema: enum payloads and raw modifier integers, no activation field.
        let bytes = Data(#"{"schemaVersion":2,"isEnabled":true,"bindings":[{"id":"00000000-0000-0000-0000-000000000003","scope":"allMice","trigger":{"scroll":{"_0":"left"}},"modifiers":2,"action":{"shortcut":{"_0":{"keyCode":13,"modifiers":1}}},"isEnabled":false}]}"#.utf8)
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: store.url)
        let loaded = try store.load()
        let wheel = try #require(loaded.bindings.first)
        #expect(loaded.schemaVersion == Configuration.currentSchemaVersion && loaded.isEnabled)
        #expect(wheel.id.uuidString == "00000000-0000-0000-0000-000000000003")
        #expect(wheel.trigger == .scroll(.left) && wheel.modifiers == .control)
        #expect(wheel.action.shortcut == output && !wheel.isEnabled && wheel.activation == .press)
        #expect(try Data(contentsOf: store.url) == bytes)
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }

    @Test(arguments: [InputTrigger.key(0), .mouseButton(99)])
    func doubleRulesRoundTripAndKeepStableIdentity(_ trigger: InputTrigger) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control,
                                     action: .shortcut(output), activation: .doublePress)
        let original = Configuration(isEnabled: true, bindings: [binding])
        try store.save(original)
        #expect(try store.load() == original)
        let encoded = try JSONSerialization.jsonObject(with: Data(contentsOf: store.url)) as? [String: Any]
        let profiles = try #require(encoded?["profiles"] as? [[String: Any]])
        let encodedBindings = try #require(profiles.first?["bindings"] as? [[String: Any]])
        #expect(encodedBindings.first?["activation"] as? String == "doublePress")
    }

    @Test func conflictingActivationModesCannotOverwriteSavedData() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let press = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: .control, action: .shortcut(output))
        let original = Configuration(bindings: [press])
        try store.save(original)
        var double = press
        double.id = UUID()
        double.activation = .doublePress
        #expect(throws: ConfigurationError.conflict) { try store.save(Configuration(bindings: [press, double])) }
        #expect(try store.load() == original)
        double.isEnabled = false
        #expect(throws: Never.self) { try Configuration(bindings: [press, double]).validate() }
    }

    @Test func wheelDoublePressAndDisguisedLegacyModesAreInvalid() {
        let wheel = rebind.Binding(scope: .allMice, trigger: .scroll(.up), modifiers: [],
                                   action: .shortcut(output), activation: .doublePress)
        #expect(throws: ConfigurationError.invalid) { try Configuration(bindings: [wheel]).validate() }
        let double = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: [],
                                    action: .shortcut(output), activation: .doublePress)
        for version in [1, 2] {
            #expect(throws: ConfigurationError.invalid) { try Configuration(schemaVersion: version, bindings: [double]).migrated() }
        }
    }

    @Test(arguments: ["\"unknown\"", "null", "42"])
    func invalidActivationFieldIsNotSilentlyDowngraded(_ value: String) throws {
        let binding = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: [], action: .shortcut(output))
        let encoded = try JSONEncoder().encode(binding)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["activation"] = try JSONSerialization.jsonObject(with: Data(value.utf8), options: .fragmentsAllowed)
        let invalid = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(rebind.Binding.self, from: invalid) }
    }
}
