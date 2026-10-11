import Foundation
import Synchronization
import Testing
@testable import rebind

@MainActor struct ConfigurationRestorationTests {
    @Test(arguments: PressActivation.allCases, [false, true])
    func exportResetImportResumeRestoresSelectedProfileAndActivation(_ activation: PressActivation, _ initiallyEnabled: Bool) async throws {
        let store = ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindRestore-\(UUID())/configuration.json"))
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let oldOutput = KeyboardShortcut(keyCode: 0, modifiers: .command)
        let selectedOutput = KeyboardShortcut(keyCode: 13, modifiers: .command)
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: [],
            action: .shortcut(oldOutput), activation: activation, holdDurationMilliseconds: 500)
        var original = Configuration(isEnabled: initiallyEnabled, bindings: [binding])
        original.hasCompletedSetup = true
        try original.createProfile(name: "Profil Русский Français", copying: original.selectedProfileID)
        original.bindings[0].action = .shortcut(selectedOutput)
        try store.save(original)
        let app = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) },
            loginItem: LoginItemModel(service: LoginItemServiceStub()))
        app.mailbox.configure(original)
        app.mailbox.state.withLock { $0.status = .active }
        let outputs = Mutex<[KeyboardShortcut]>([])
        let worker = ActionWorker(mailbox: app.mailbox, capabilities: { AudioOutputCapabilities() },
            sendShortcut: { value in outputs.withLock { $0.append(value) }; return true },
            secureInput: { false }, postingAllowed: { true })
        let page = AdvancedSettingsModel(app: app)
        let backup = store.url.deletingLastPathComponent().appending(path: "backup.json")
        await page.export(to: backup)
        #expect(page.feedback == .exported)
        let backupBytes = try Data(contentsOf: backup)
        #expect(try ConfigurationBackup(data: backupBytes).configuration == original)
        _ = app.mailbox.handle(event(.down, at: 0), secureInput: false)
        page.reviewReset()
        page.confirmReplacement()
        #expect(page.feedback == .reset && app.configuration.bindings.isEmpty)
        #expect(app.configuration.isEnabled == false && app.configurationReplacementRevision == 1)
        worker.service(at: 500_000_000)
        #expect(outputs.withLock { $0.isEmpty })
        await page.validateImport(at: backup)
        #expect(page.review?.profileCount == 2 && page.review?.bindingCount == 2)
        page.confirmReplacement()
        var restored = original
        restored.isEnabled = false
        #expect(app.configuration == restored && app.configurationReplacementRevision == 2)
        #expect(try store.load() == restored)
        let release = app.mailbox.handle(event(.up, at: 600_000_000), secureInput: false)
        #expect(release == initiallyEnabled)
        #expect(app.mailbox.handle(event(.down, at: 700_000_000), secureInput: false) == false)
        _ = app.mailbox.handle(event(.up, at: 700_000_001), secureInput: false)
        worker.service(at: 800_000_000)
        #expect(outputs.withLock { $0.isEmpty })
        app.setEnabled(true)
        #expect(app.configuration.isEnabled && app.configuration.selectedProfileID == original.selectedProfileID)
        #expect(app.mailbox.handle(event(.down, at: 1_000_000_000), secureInput: false))
        if activation == .doublePress {
            worker.service(at: 1_000_000_000)
            #expect(outputs.withLock { $0.isEmpty })
            #expect(app.mailbox.handle(event(.up, at: 1_000_000_001), secureInput: false))
            #expect(app.mailbox.handle(event(.down, at: 1_000_000_002), secureInput: false))
        }
        if activation == .hold {
            app.mailbox.pollHold(at: 1_499_999_999, secureInput: false)
            worker.service(at: 1_499_999_999)
            #expect(outputs.withLock { $0.isEmpty })
            app.mailbox.pollHold(at: 1_500_000_000, secureInput: false)
        }
        worker.service(at: 1_500_000_000)
        worker.service(at: 1_500_000_001)
        #expect(outputs.withLock { $0 } == [selectedOutput])
        #expect(app.mailbox.handle(event(.up, at: 1_500_000_002), secureInput: false))
        #expect(app.mailbox.state.withLock { $0.matcher.hasSuppressedInput } == false)
        #expect(try Data(contentsOf: backup) == backupBytes)
        #expect(try store.load() == app.configuration)
        let relaunched = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) },
            loginItem: LoginItemModel(service: LoginItemServiceStub()))
        #expect(relaunched.configuration == app.configuration)
    }

    private func event(_ phase: InputEvent.Phase, at time: UInt64) -> InputEvent {
        InputEvent(trigger: .mouseButton(99), phase: phase, timestamp: time, receivedAt: time)
    }
}
