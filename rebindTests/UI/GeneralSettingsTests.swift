import Foundation
import Testing
@testable import rebind

@MainActor struct GeneralSettingsTests {
    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindGeneral-\(UUID())/configuration.json"))
    }

    @Test(arguments: [true, false])
    func loginChangesPreserveProfileRulesPauseAndConfigurationBytes(enabled: Bool) async throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var configuration = Configuration(isEnabled: enabled)
        try configuration.createProfile(name: "Test")
        configuration.bindings = [rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
            action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))]
        try store.save(configuration)
        let bytes = try Data(contentsOf: store.url)
        let service = LoginItemServiceStub()
        let model = AppModel(store: store, loginItem: LoginItemModel(service: service))
        model.mailbox.configure(configuration)
        let revision = model.mailbox.state.withLock { $0.actionRevision }
        await model.loginItem.setEnabled(true)
        await model.loginItem.setEnabled(false)
        #expect(model.configuration == configuration)
        #expect(try Data(contentsOf: store.url) == bytes)
        #expect(model.mailbox.state.withLock { $0.enabled == enabled && $0.actionRevision == revision })
    }

    @Test func busyLoginRemovalDoesNotBlockEmergencyPause() async throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration(isEnabled: true))
        let service = LoginItemServiceStub(status: .enabled)
        let model = AppModel(store: store, loginItem: LoginItemModel(service: service))
        model.mailbox.configure(model.configuration)
        service.onRemoval = {
            model.setEnabled(false)
            #expect(model.loginItem.operation == .disable)
            #expect(model.configuration.isEnabled == false)
            #expect(model.mailbox.state.withLock { $0.enabled == false })
        }
        await model.loginItem.setEnabled(false)
        #expect(try store.load().isEnabled == false)
    }

    @Test func failedResumePreservesPause() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: true)
        let model = AppModel(store: store, loadConfiguration: false,
            loginItem: LoginItemModel(service: LoginItemServiceStub()))
        model.mailbox.configure(Configuration())
        model.setEnabled(true)
        #expect(model.configuration.isEnabled == false && model.error != nil)
        #expect(model.mailbox.state.withLock { $0.enabled == false })
    }

    @Test func failedPauseStillCancelsOutputAndRetainsSuppressedReleaseOwnership() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
            action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))
        try store.save(Configuration(isEnabled: true, bindings: [binding]))
        let model = AppModel(store: store, loginItem: LoginItemModel(service: LoginItemServiceStub()))
        model.mailbox.configure(model.configuration)
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        #expect(model.mailbox.state.withLock { $0.pending.isEmpty == false })
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        // Safety takes precedence over persistence rollback for an explicit pause.
        model.setEnabled(false)
        #expect(model.configuration.isEnabled == false && model.error != nil)
        #expect(model.mailbox.state.withLock { $0.enabled == false && $0.pending.isEmpty })
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false) == false)
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false) == false)
    }

    @Test func explicitRetryChangesOnlyCaptureRetryAndNeverResumesPause() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration(isEnabled: true))
        let model = AppModel(store: store, sessionAllowsInput: { true },
            readPermissions: { InputPermissions(accessibility: true, posting: true) },
            loginItem: LoginItemModel(service: LoginItemServiceStub()))
        model.mailbox.configure(model.configuration)
        model.mailbox.state.withLock { $0.status = .tapFailed }
        model.refresh()
        #expect(model.generalRuntime == .engineError)
        let bytes = try Data(contentsOf: store.url)
        let retry = model.mailbox.state.withLock { $0.retryID }
        let revision = model.mailbox.state.withLock { $0.actionRevision }
        model.retryRemapping()
        #expect(model.mailbox.state.withLock { $0.retryID == retry + 1 && $0.actionRevision == revision })
        #expect(try Data(contentsOf: store.url) == bytes)
        model.setEnabled(false)
        let pausedRetry = model.mailbox.state.withLock { $0.retryID }
        model.retryRemapping()
        #expect(model.mailbox.state.withLock { $0.retryID == pausedRetry && $0.enabled == false })
    }

    @Test(arguments: [InputPermissions(), InputPermissions(accessibility: true, posting: true)])
    func retryCannotBypassMissingAccessOrSuspension(permissions: InputPermissions) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration(isEnabled: true))
        let model = AppModel(store: store, readPermissions: { permissions },
            loginItem: LoginItemModel(service: LoginItemServiceStub()))
        model.mailbox.configure(model.configuration)
        model.mailbox.state.withLock { $0.status = .tapFailed; $0.suspended = permissions.allowsRemapping }
        let retry = model.mailbox.state.withLock { $0.retryID }
        model.retryRemapping()
        #expect(model.mailbox.state.withLock { $0.retryID == retry })
    }
}
