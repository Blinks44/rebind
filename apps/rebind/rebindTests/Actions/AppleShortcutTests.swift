import Foundation
import Synchronization
import Testing
@testable import rebind

struct AppleShortcutTests {
    private let id = UUID()

    @Test func parsesUnicodeAndParenthesesNamesWithStableIdentifiers() throws {
        let id = id
        let other = UUID()
        let data = Data("Команда (тест) & $(text) (\(id))\nSame name (\(other))\n".utf8)
        let targets = try AppleShortcutTarget.parseList(data)
        #expect(targets.map(\.id) == [id, other])
        #expect(targets[0].name == "Команда (тест) & $(text)")
        #expect(try AppleShortcutTarget.parseList(Data()).isEmpty)
    }

    @Test(arguments: ["missing identifier", "Name (not-a-uuid)", " (11111111-1111-1111-1111-111111111111)", "A\tB (11111111-1111-1111-1111-111111111111)"])
    func rejectsAmbiguousOrMalformedListing(_ line: String) {
        #expect(throws: AppleShortcutTarget.ListError.self) { try AppleShortcutTarget.parseList(Data(line.utf8)) }
    }

    @Test func rejectsDuplicateIDsInvalidUTF8AndOversizedListing() {
        let row = "Name (\(id))\n"
        #expect(throws: AppleShortcutTarget.ListError.self) { try AppleShortcutTarget.parseList(Data((row + row).utf8)) }
        #expect(throws: AppleShortcutTarget.ListError.self) { try AppleShortcutTarget.parseList(Data([0xFF])) }
        #expect(throws: AppleShortcutTarget.ListError.self) { try AppleShortcutTarget.parseList(Data(repeating: 65, count: 262_145)) }
    }

    @Test func requiresValidSelectionAndRoundTripsIndependentOfAudio() throws {
        let target = AppleShortcutTarget(id: id, name: "Selected")
        let action = RebindAction.appleShortcut(target)
        #expect(ActionKind.runAppleShortcut.configuredAction(shortcut: nil) == nil)
        #expect(ActionKind.runAppleShortcut.configuredAction(shortcut: nil, appleShortcut: target) == action)
        #expect(ActionKind(action: action).category == .automation)
        #expect(AudioOutputCapabilities().supports(action))
        #expect(ActionKind.runAppleShortcut.configuredAction(shortcut: nil, appleShortcut: .init(id: id, name: "\n")) == nil)
        #expect(AppleShortcutTarget(id: id, name: String(repeating: "a", count: 513)).isSupported == false)
        let encoded = try JSONEncoder().encode(action)
        #expect(try JSONDecoder().decode(RebindAction.self, from: encoded) == action)
    }

    @Test(arguments: [InputTrigger.key(0), .mouseButton(99), .scroll(.right)])
    func matchesAllCurrentInputCategoriesWithoutConvertingToKeys(_ trigger: InputTrigger) {
        let action = RebindAction.appleShortcut(.init(id: id, name: "Selected"))
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: action)
        var matcher = InputMatcher()
        let result = matcher.handle(InputEvent(trigger: trigger, modifiers: .control, phase: trigger.isScroll ? .scroll : .down),
                                    rules: InputMatcher.compile([binding]), enabled: true)
        #expect(result.suppress && result.action == action && result.shortcut == nil)
    }

    @Test func schemaNineMigrationPreservesBytesUntilSuccessfulSave() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindShortcuts-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: folder.appending(path: "config.json"))
        let url = try #require(URL(string: "https://example.com"))
        var old = Configuration(isEnabled: true, bindings: [rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
            action: .workspace(.openURL(url)))])
        try old.createProfile(name: "Second", copying: old.selectedProfileID)
        old.schemaVersion = 9
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var loaded = try store.load()
        #expect(loaded.schemaVersion == Configuration.currentSchemaVersion)
        #expect(loaded.profiles == old.profiles && loaded.selectedProfileID == old.selectedProfileID && loaded.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        loaded.bindings.append(rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: [],
                                              action: .appleShortcut(.init(id: id, name: "Selected"))))
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }

    @Test(arguments: 1...9)
    func newActionCannotMasqueradeInOlderSchemas(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .appleShortcut(.init(id: id, name: "Selected")))
        let config = Configuration(schemaVersion: version, bindings: [binding])
        let data = try JSONEncoder().encode(config)
        #expect(throws: ConfigurationError.invalid) { try JSONDecoder().decode(Configuration.self, from: data).migrated() }
    }

    @Test func runsOnlyUUIDWithoutNameOptionsOrInputsAndReportsNativeErrors() async {
        let target = AppleShortcutTarget(id: id, name: "-i $(ignored) ; example")
        let calls = Mutex(0)
        let result = await AppleShortcuts.run(target, canPerform: { true }, execute: { arguments, allowed in
            calls.withLock { $0 += 1 }
            #expect(arguments == ["run", target.id.uuidString] && allowed())
        })
        #expect(result == .performed)
        #expect(await AppleShortcuts.run(target, canPerform: { false }, execute: { _, _ in calls.withLock { $0 += 1 } }) == .cancelled)
        #expect(calls.withLock { $0 } == 1)
        #expect(await AppleShortcuts.run(target, canPerform: { true }, execute: { _, _ in throw ShortcutsProcess.Failure.failed }) == .failed)
        #expect(await AppleShortcuts.run(target, canPerform: { true }, execute: { _, _ in throw ShortcutsProcess.Failure.cancelled }) == .cancelled)
    }
}
