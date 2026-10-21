import Foundation
import Testing
@testable import rebind

@MainActor struct AppModelPermissionSetupTests {
    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindSetup-\(UUID())").appending(path: "configuration.json"))
    }

    @Test(arguments: [
        InputPermissions(),
        InputPermissions(accessibility: true),
        InputPermissions(accessibility: true, posting: true)
    ])
    func newInstallationShowsFirstRunGuidanceWithAnyGrants(_ grants: InputPermissions) {
        let model = AppModel(loadConfiguration: false, readPermissions: { grants })
        #expect(model.needsFirstRunSetup)
        #expect(model.configuration.isEnabled == false)
    }

    @Test(arguments: [false, true])
    func deferralSurvivesRelaunchWithoutChangingRulesOrPause(enabled: Bool) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: .control,
                                     action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))
        var original = Configuration(isEnabled: enabled, bindings: [binding])
        try original.createProfile(name: "Desk", copying: RuleProfile.defaultID)
        try store.save(original)
        let model = AppModel(store: store, readPermissions: { InputPermissions() })
        model.mailbox.configure(original)
        model.mailbox.state.withLock { $0.pending = [binding.action] }
        #expect(model.needsFirstRunSetup)
        #expect(model.completePermissionSetup())
        var expected = original
        expected.hasCompletedSetup = true
        #expect(model.configuration == expected)
        #expect(model.mailbox.state.withLock { $0.enabled == enabled && $0.profileID == original.selectedProfileID })
        #expect(model.mailbox.state.withLock { $0.pending == [binding.action] })
        let reopened = AppModel(store: store, readPermissions: { InputPermissions() })
        #expect(reopened.needsFirstRunSetup == false)
        #expect(reopened.configuration == expected)
        #expect(reopened.permissions.requirement == .accessibility)
    }

    @Test func failedAcknowledgementKeepsSetupAndRuntimeUnchanged() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: true)
        let model = AppModel(store: store, loadConfiguration: false, readPermissions: { InputPermissions() })
        model.mailbox.configure(Configuration())
        #expect(model.completePermissionSetup() == false)
        #expect(model.needsFirstRunSetup)
        #expect(model.configuration.hasCompletedSetup == false)
        #expect(model.mailbox.state.withLock { $0.enabled == false })
        #expect(model.error != nil)
    }

    @Test(arguments: ["{broken", "{\"schemaVersion\":99}"])
    func unreadableConfigurationCannotBeAcknowledgedOrOverwritten(_ contents: String) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let bytes = Data(contents.utf8)
        try bytes.write(to: store.url)
        let model = AppModel(store: store, readPermissions: { InputPermissions() })
        #expect(model.needsFirstRunSetup == false)
        #expect(model.completePermissionSetup() == false)
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test(arguments: [false, true])
    func grantRecheckAndRevocationCancelRecordingAndPreserveSavedIntent(enabled: Bool) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var grants = InputPermissions()
        let configuration = Configuration(isEnabled: enabled)
        try store.save(configuration)
        let model = AppModel(store: store, sessionAllowsInput: { true }, readPermissions: { grants })
        #expect(model.permissions.requirement == .accessibility)
        grants.accessibility = true
        model.refreshPermissions()
        #expect(model.permissions.requirement == .eventPosting)
        #expect(model.canRecord == false)
        grants.posting = true
        model.refreshPermissions()
        #expect(model.permissions.allowsRemapping)
        #expect(model.configuration.isEnabled == enabled)
        let request = RecordingRequest(target: .mouseTrigger)
        model.recording = request
        model.mailbox.record(request)
        grants.accessibility = false
        model.refreshPermissions()
        #expect(model.recording == nil)
        #expect(model.mailbox.state.withLock { $0.recording == nil })
        #expect(model.permissions.requirement == .accessibility)
        #expect(model.canRecord == false)
        #expect(model.configuration == configuration)
        #expect(try store.load() == configuration)
    }

    @Test func requiredGrantsDoNotClaimEngineSuccessOrChangePause() {
        let grants = InputPermissions(accessibility: true, posting: true)
        let model = AppModel(loadConfiguration: false, sessionAllowsInput: { true }, readPermissions: { grants })
        model.mailbox.state.withLock { $0.status = .tapFailed }
        model.refreshPermissions()
        #expect(model.permissions.allowsRemapping)
        #expect(model.status == .tapFailed)
        #expect(model.statusText == EngineStatus.tapFailed.text)
        #expect(model.configuration.isEnabled == false)
    }
}
