import Foundation
import Testing
@testable import rebind

@MainActor struct AppModelProfileTests {
    @Test func localizedDefaultLabelCannotBeDuplicatedInTheUI() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let model = AppModel(store: store, loadConfiguration: false)
        let defaultProfile = try #require(model.configuration.selectedProfile)
        #expect(model.createProfile(name: defaultProfile.title) == false)
        #expect(model.configuration == Configuration())
        #expect(FileManager.default.fileExists(atPath: store.url.path) == false)
    }

    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindProfileModel-\(UUID())").appending(path: "config.json"))
    }

    @Test func createCopySwitchRenameDeletePersistWithoutChangingPause() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
                                    action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))
        let original = Configuration(bindings: [binding])
        try store.save(original)
        let model = AppModel(store: store)
        #expect(model.createProfile(name: "Second", copying: RuleProfile.defaultID))
        let second = model.configuration.selectedProfileID
        #expect(model.configuration.bindings.count == 1)
        #expect(model.configuration.bindings.first?.id != binding.id)
        #expect(model.renameProfile(second, name: "Desk"))
        #expect(model.selectProfile(RuleProfile.defaultID))
        #expect(model.configuration.bindings == [binding])
        #expect(model.deleteProfile(second))
        #expect(model.configuration.isEnabled == false)
        #expect(model.mailbox.state.withLock { $0.enabled == false })
        #expect(try store.load() == model.configuration)
    }

    @Test func failedDiskCommitLeavesSelectionRulesAndQueuedOutputUntouched() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .shortcut(output))
        var configuration = Configuration(isEnabled: true, bindings: [binding])
        try configuration.createProfile(name: "Second")
        let second = configuration.selectedProfileID
        try configuration.selectProfile(RuleProfile.defaultID)
        try store.save(configuration)
        let model = AppModel(store: store)
        model.mailbox.configure(configuration)
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        #expect(model.selectProfile(second) == false)
        #expect(model.configuration == configuration)
        #expect(model.mailbox.state.withLock { $0.profileID } == RuleProfile.defaultID)
        #expect(model.mailbox.state.withLock { $0.pending } == [.shortcut(output)])
        #expect(model.error != nil)
    }

    @Test func switchingCancelsRecordingAndStaleEditorCannotSaveIntoNewProfile() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let model = AppModel(store: store, loadConfiguration: false)
        let request = RecordingRequest(target: .mouseTrigger)
        model.recording = request
        model.mailbox.record(request)
        #expect(model.createProfile(name: "Second"))
        #expect(model.recording == nil && model.lastRecording == nil)
        #expect(model.mailbox.state.withLock { $0.recording == nil && $0.recorded == nil })
        let bytes = try Data(contentsOf: store.url)
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
                                    action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))
        #expect(model.saveBinding(binding, profileID: RuleProfile.defaultID) == false)
        #expect(model.configuration.bindings.isEmpty)
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test func corruptFileLocksAllProfileChangesWithoutOverwriting() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let bytes = Data("broken".utf8)
        try bytes.write(to: store.url)
        let model = AppModel(store: store)
        #expect(model.storageLocked)
        #expect(model.createProfile(name: "Second") == false)
        #expect(model.renameProfile(RuleProfile.defaultID, name: "Changed") == false)
        #expect(model.configuration == Configuration())
        #expect(try Data(contentsOf: store.url) == bytes)
    }
}
