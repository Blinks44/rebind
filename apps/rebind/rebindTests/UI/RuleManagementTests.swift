import Foundation
import Testing
@testable import rebind

@MainActor struct RuleManagementTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)

    private func binding() -> rebind.Binding {
        rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .shortcut(output))
    }

    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindRules-\(UUID())").appending(path: "config.json"))
    }

    @Test func aNoteIsTrimmedBoundedSearchableAndPersists() throws {
        var draft = BindingEditorDraft(scope: .allMice, existing: binding())
        draft.note = "  " + String(repeating: "n", count: 100) + "  "
        let saved = try #require(draft.binding(scope: .allMice, action: .shortcut(output), existing: nil))
        #expect(saved.note == String(repeating: "n", count: 80) && saved.isValid)
        draft.note = "   "
        #expect(draft.binding(scope: .allMice, action: .shortcut(output), existing: nil)?.note == nil)
        var noted = binding()
        noted.note = "Close tab in Safari"
        #expect(BindingList.matches(noted, search: "safari"))
        let configuration = Configuration(bindings: [noted])
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
        noted.note = " padded"
        #expect(noted.isValid == false)
        var old = configuration
        old.schemaVersion = 33
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }

    @Test func copyingToAnotherProfileKeepsTheSourceAndSwitchesOffAConflictingCopy() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration(bindings: [binding()]))
        let model = AppModel(store: store)
        let source = try #require(model.configuration.bindings.first)
        #expect(model.createProfile(name: "Second"))
        let second = model.configuration.selectedProfileID
        #expect(model.selectProfile(RuleProfile.defaultID))
        #expect(model.copyBinding(source, toProfile: second))
        #expect(model.copyBinding(source, toProfile: second))
        let copies = try #require(model.configuration.profiles.first { $0.id == second }).bindings
        #expect(copies.map(\.isEnabled) == [true, false])
        #expect(Set(copies.map(\.id) + [source.id]).count == 3)
        #expect(model.configuration.bindings == [source])
        #expect(model.copyBinding(source, toProfile: UUID()) == false)
        #expect(try store.load() == model.configuration)
    }

    @Test func gestureDistanceChangesTheRecognitionThresholdAndPersists() throws {
        let gesture = rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: 3, direction: .right), modifiers: [],
                                     action: .shortcut(output))
        var configuration = Configuration(isEnabled: true, bindings: [gesture])
        func fires(after distance: Int64) -> Bool {
            let mailbox = EngineMailbox()
            mailbox.configure(configuration)
            mailbox.state.withLock { $0.status = .active }
            _ = mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down, receivedAt: 0), secureInput: false)
            _ = mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .drag, receivedAt: 1,
                                          motion: PointerMotion(deltaX: distance, deltaY: 0)), secureInput: false)
            return mailbox.state.withLock { $0.pending } == [.shortcut(output)]
        }
        #expect(fires(after: 49) == false && fires(after: 50))
        configuration.pointerGestureDistance = .short
        #expect(fires(after: 29) == false && fires(after: 30))
        configuration.pointerGestureDistance = .long
        #expect(fires(after: 89) == false && fires(after: 90))
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
        configuration.schemaVersion = 33
        #expect(throws: ConfigurationError.invalid) { try configuration.migrated() }
    }
}
