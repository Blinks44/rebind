import Foundation
import Testing
@testable import rebind

struct PointerGesturePersistenceTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private func binding(_ direction: PointerDirection = .left, button: UInt32 = 3) -> rebind.Binding {
        rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: button, direction: direction),
                       modifiers: .control, action: .shortcut(output))
    }
    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindPointer-\(UUID())", directoryHint: .isDirectory).appending(path: "configuration.json"))
    }

    @Test(arguments: PointerDirection.allCases)
    func gestureRoundTripsWithDirectionIdentityAndEnabledState(_ direction: PointerDirection) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var rule = binding(direction, button: 99)
        rule.isEnabled = false
        let configuration = Configuration(isEnabled: true, bindings: [rule])
        try store.save(configuration)
        #expect(try store.load() == configuration)
        #expect(configuration.schemaVersion == Configuration.currentSchemaVersion)
    }

    @Test func version4UserHoldConfigurationMigratesWithoutRewriting() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let bytes = Data(#"{"isEnabled":true,"schemaVersion":4,"bindings":[{"isEnabled":true,"scope":"allMice","id":"00000000-0000-0000-0000-000000000005","activation":"hold","modifiers":0,"holdDurationMilliseconds":1000,"trigger":{"mouseButton":{"_0":4}},"action":{"shortcut":{"_0":{"keyCode":0,"modifiers":1}}}}]}"#.utf8)
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: store.url)
        let migrated = try store.load()
        let rule = try #require(migrated.bindings.first)
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion && migrated.isEnabled)
        #expect(rule.id.uuidString == "00000000-0000-0000-0000-000000000005")
        #expect(rule.activation == .hold && rule.holdDurationMilliseconds == 1000)
        #expect(rule.trigger == .mouseButton(4) && rule.modifiers.isEmpty && rule.action.shortcut == output)
        #expect(try Data(contentsOf: store.url) == bytes)
        try store.save(migrated)
        #expect(try store.load() == migrated)
    }

    @Test func fourDirectionsCanShareButtonButDuplicatesConflict() throws {
        let rules = PointerDirection.allCases.map { binding($0) }
        try Configuration(bindings: rules).validate()
        #expect(InputMatcher.compile(rules).count == 4)
        var duplicate = binding()
        duplicate.id = UUID()
        #expect(throws: ConfigurationError.conflict) { try Configuration(bindings: rules + [duplicate]).validate() }
    }

    /// A plain press shares the button with its gestures; see GestureButtonClickTests.
    @Test(arguments: [PressActivation.hold, .doublePress])
    func pressModesConflictWithGestureFamilyAndCompileFailOpen(_ activation: PressActivation) {
        let rules = PointerDirection.allCases.map { binding($0) }
        let ordinary = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
                                      action: .shortcut(output), activation: activation)
        #expect(throws: ConfigurationError.conflict) { try Configuration(bindings: rules + [ordinary]).validate() }
        #expect(InputMatcher.compile(rules + [ordinary]).isEmpty)
    }

    @Test func differentModifiersAndDisabledRulesDoNotConflict() throws {
        let gesture = binding()
        var ordinary = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .shortcut(output))
        try Configuration(bindings: [gesture, ordinary]).validate()
        #expect(InputMatcher.compile([gesture, ordinary]).count == 2)
        ordinary.modifiers = .control
        ordinary.isEnabled = false
        try Configuration(bindings: [gesture, ordinary]).validate()
        #expect(InputMatcher.compile([gesture, ordinary]).count == 1)
    }

    @Test func invalidPrimaryButtonsTemporalModesScopesAndLegacyGesturesCannotOverwriteData() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration())
        let bytes = try Data(contentsOf: store.url)
        for button in UInt32(0)...1 {
            #expect(throws: ConfigurationError.invalid) { try store.save(Configuration(bindings: [binding(button: button)])) }
        }
        for activation in [PressActivation.hold, .doublePress] {
            var invalid = binding()
            invalid.activation = activation
            #expect(throws: ConfigurationError.invalid) { try store.save(Configuration(bindings: [invalid])) }
        }
        var wrongScope = binding()
        wrongScope.scope = .allKeyboards
        #expect(throws: ConfigurationError.invalid) { try store.save(Configuration(bindings: [wrongScope])) }
        for version in 1...4 {
            #expect(throws: ConfigurationError.invalid) { try Configuration(schemaVersion: version, bindings: [binding()]).migrated() }
        }
        #expect(throws: ConfigurationError.incompatible) { try Configuration(schemaVersion: Configuration.currentSchemaVersion + 1).migrated() }
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test(arguments: ["diagonal", "unknown"])
    func unknownDirectionsRejectRatherThanDefault(_ direction: String) throws {
        let data = try JSONEncoder().encode(binding())
        let text = String(decoding: data, as: UTF8.self).replacingOccurrences(of: "\"left\"", with: "\"\(direction)\"")
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(rebind.Binding.self, from: Data(text.utf8)) }
    }
}
