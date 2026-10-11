import Foundation
import Synchronization
import Testing
@testable import rebind

@MainActor struct AppModelStorageProtectionTests {
    @Test(arguments: 0...4, [Data("{broken".utf8), Data("{\"schemaVersion\":999}".utf8),
                            Data(repeating: 0x20, count: ConfigurationStore.maximumBytes + 1)])
    func ordinarySavesLockChangedOriginalWithoutMutatingRulesOrOutput(_ operation: Int, _ bytes: Data) throws {
        let store = ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindModelProtection-\(UUID())/configuration.json"))
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: [],
            action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))
        var original = Configuration(isEnabled: operation != 4, bindings: [binding])
        try original.createProfile(name: "Second", copying: original.selectedProfileID)
        let second = original.selectedProfileID
        try original.selectProfile(RuleProfile.defaultID)
        try store.save(original)
        var projections: [AppLanguagePreference] = []
        let app = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) },
            loginItem: LoginItemModel(service: LoginItemServiceStub()), preferredLanguages: ["en"],
            languagePreferenceSaved: { projections.append($0) })
        app.mailbox.configure(original)
        app.mailbox.state.withLock { $0.status = .active }
        _ = app.mailbox.handle(InputEvent(trigger: .mouseButton(99), phase: .down), secureInput: false)
        let revision = app.mailbox.state.withLock { $0.actionRevision }
        let pending = app.mailbox.state.withLock { $0.pending }
        try bytes.write(to: store.url, options: .atomic)
        switch operation {
        case 0: #expect(app.selectProfile(second) == false)
        case 1:
            var edited = binding
            edited.action = .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command))
            #expect(app.saveBinding(edited, profileID: original.selectedProfileID) == false)
        case 2: #expect(throws: ConfigurationStoreError.protectedOriginal) { try app.saveLanguagePreference(.fr) }
        case 3: #expect(app.completePermissionSetup() == false)
        default: app.setEnabled(true)
        }
        #expect(app.storageLocked && app.error == .storageUnreadable)
        #expect(app.configuration == original && projections.isEmpty)
        #expect(app.mailbox.state.withLock { $0.actionRevision == revision && $0.pending == pending })
        #expect(try Data(contentsOf: store.url) == bytes)
        // Pause must stay reachable even after storage locks: clear pending
        // output in memory, retain ownership of an already suppressed release.
        app.setEnabled(false)
        #expect(app.configuration.isEnabled == false)
        #expect(app.mailbox.state.withLock { $0.enabled == false && $0.pending.isEmpty })
        let release = app.mailbox.handle(InputEvent(trigger: .mouseButton(99), phase: .up), secureInput: false)
        #expect(release == original.isEnabled)
        #expect(app.mailbox.state.withLock { $0.matcher.hasSuppressedInput } == false)
        #expect(try Data(contentsOf: store.url) == bytes)
    }
}
