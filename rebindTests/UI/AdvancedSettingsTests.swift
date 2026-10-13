import Foundation
import Testing
@testable import rebind

@MainActor struct AdvancedSettingsTests {
    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindAdvanced-\(UUID())/configuration.json"))
    }

    private func fixture(_ store: ConfigurationStore,
                         projection: @escaping (AppLanguagePreference) -> Void = { _ in }) -> AppModel {
        AppModel(store: store, sessionAllowsInput: { true },
                 readPermissions: { InputPermissions(accessibility: true, posting: true) },
                 loginItem: LoginItemModel(service: LoginItemServiceStub()), preferredLanguages: ["en"],
                 languagePreferenceSaved: projection)
    }

    @Test func importIsReviewedThenCommittedPausedWithLanguageAndReleaseOwnership() async throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: [],
            action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))
        var original = Configuration(isEnabled: true, bindings: [binding])
        original.hasCompletedSetup = true
        try store.save(original)
        var projected: [AppLanguagePreference] = []
        let app = fixture(store, projection: { projected.append($0) })
        app.mailbox.configure(original)
        #expect(app.mailbox.handle(InputEvent(trigger: .mouseButton(99), phase: .down), secureInput: false))
        var imported = original
        imported.languagePreference = .fr
        try imported.createProfile(name: "Français Русский", copying: original.selectedProfileID)
        imported.selectedProfileID = original.selectedProfileID
        let url = store.url.deletingLastPathComponent().appending(path: "backup.json")
        let backupBytes = try ConfigurationBackup(configuration: imported).encoded()
        try backupBytes.write(to: url)
        let bytes = try Data(contentsOf: store.url)
        let page = AdvancedSettingsModel(app: app)
        await page.validateImport(at: url)
        #expect(page.review?.profileCount == 2 && page.review?.bindingCount == 2)
        #expect(app.configuration == original && projected.isEmpty)
        #expect(try Data(contentsOf: store.url) == bytes)
        let recorder = RecordingRequest(target: .output)
        app.recording = recorder
        app.mailbox.record(recorder)
        app.mailbox.startDiagnostics(at: 1)
        let revision = app.mailbox.state.withLock { $0.actionRevision }
        page.confirmReplacement()
        imported.isEnabled = false
        #expect(app.configuration == imported)
        #expect(try store.load() == imported)
        #expect(app.recording == nil && app.lastRecording == nil && page.review == nil)
        #expect(app.configurationReplacementRevision == 1 && app.activeLanguage == .en && app.requiresLanguageReopen)
        #expect(projected == [.fr])
        #expect(app.mailbox.state.withLock {
            !$0.enabled && $0.actionRevision > revision && $0.pending.isEmpty && $0.recording == nil
        })
        #expect(!app.diagnostics.isRunning)
        #expect(app.mailbox.handle(InputEvent(trigger: .mouseButton(99), phase: .up), secureInput: false))
        #expect(try Data(contentsOf: url) == backupBytes)
    }

    @Test func cancelImportAndResetAreSideEffectFree() async throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration(isEnabled: true))
        let app = fixture(store)
        app.mailbox.configure(app.configuration)
        let revision = app.mailbox.state.withLock { $0.actionRevision }
        let bytes = try Data(contentsOf: store.url)
        let page = AdvancedSettingsModel(app: app)
        await page.validateImport(at: store.url)
        page.cancelReview()
        page.confirmReplacement()
        page.reviewReset()
        page.cancelReview()
        page.confirmReplacement()
        #expect(try Data(contentsOf: store.url) == bytes)
        #expect(app.configuration.isEnabled && app.configurationReplacementRevision == 0)
        #expect(app.mailbox.state.withLock { $0.actionRevision == revision })
    }

    @Test func resetRestoresStoredPreferencesButDoesNotChangeLoginOrGrants() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var original = Configuration(isEnabled: true)
        original.hasCompletedSetup = true
        original.languagePreference = .de
        try original.createProfile(name: "Extra")
        try store.save(original)
        let service = LoginItemServiceStub(status: .enabled)
        var projected: [AppLanguagePreference] = []
        let app = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) },
            loginItem: LoginItemModel(service: service), preferredLanguages: ["en"],
            languagePreferenceSaved: { projected.append($0) })
        let page = AdvancedSettingsModel(app: app)
        page.reviewReset()
        page.confirmReplacement()
        var expected = Configuration()
        expected.hasCompletedSetup = true
        #expect(app.configuration == expected)
        #expect(try store.load() == expected)
        #expect(app.activeLanguage == .de && app.requiresLanguageReopen && projected == [.system])
        #expect(service.status == .enabled && app.permissions.allowsRemapping)
    }

    @Test(arguments: [false, true])
    func writeFailurePreservesRuntimeAndReviewThenRetry(isReset: Bool) async throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration(isEnabled: true))
        let app = fixture(store)
        app.mailbox.configure(app.configuration)
        let page = AdvancedSettingsModel(app: app)
        if isReset { page.reviewReset() } else { await page.validateImport(at: store.url) }
        let original = app.configuration
        let revision = app.mailbox.state.withLock { $0.actionRevision }
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        page.confirmReplacement()
        #expect(app.configuration == original && app.configurationReplacementRevision == 0)
        #expect(app.mailbox.state.withLock { $0.actionRevision == revision && $0.enabled })
        #expect(page.review != nil)
        if case .writeFailed = page.feedback { } else { Issue.record("Expected a save failure") }
        try FileManager.default.removeItem(at: store.url)
        try store.save(original)
        page.confirmReplacement()
        #expect(!app.configuration.isEnabled && app.configurationReplacementRevision == 1,
                "Review: \(String(describing: page.review)), feedback: \(String(describing: page.feedback))")
    }

    @Test(arguments: [false, true])
    func staleReviewCannotOverwriteAnotherWindowOrSameIDs(isReset: Bool) async throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration())
        let app = fixture(store)
        let page = AdvancedSettingsModel(app: app)
        if isReset { page.reviewReset() } else { await page.validateImport(at: store.url) }
        try app.saveLanguagePreference(.ru)
        let bytes = try Data(contentsOf: store.url)
        page.confirmReplacement()
        #expect(app.configuration.languagePreference == .ru && page.review == nil)
        #expect(try Data(contentsOf: store.url) == bytes)
        if case .staleReview = page.feedback { } else { Issue.record("Expected stale review rejection") }
        page.reviewReset()
        let expected = app.configuration
        let revision = app.configurationReplacementRevision
        try app.replaceConfiguration(with: expected, expected: expected, revision: revision)
        page.confirmReplacement()
        #expect(app.configurationReplacementRevision == 1)
    }

    @Test(arguments: [Data("broken".utf8), Data("{\"schemaVersion\":999}".utf8)])
    func protectedOriginalRejectsReplacementAndExportsExactBytes(bytes: Data) async throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: store.url)
        let app = fixture(store)
        let page = AdvancedSettingsModel(app: app)
        #expect(app.storageLocked && !app.canStartDiagnostics)
        page.reviewReset()
        await page.validateImport(at: store.url)
        #expect(page.review == nil)
        #expect(throws: ConfigurationReplacementError.self) {
            try app.replaceConfiguration(with: Configuration(), expected: app.configuration, revision: 0)
        }
        let destination = store.url.deletingLastPathComponent().appending(path: "original-copy.json")
        await page.export(to: destination)
        #expect(try Data(contentsOf: destination) == bytes)
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test func cancellationAndInvalidBackupNeverMutateTheConfiguration() async throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration(isEnabled: true))
        let bytes = try Data(contentsOf: store.url)
        let app = fixture(store)
        let page = AdvancedSettingsModel(app: app)
        let task = Task { await page.validateImport(at: store.url) }
        task.cancel()
        await task.value
        #expect(page.review == nil && page.feedback == nil && !page.isValidating)
        let invalid = store.url.deletingLastPathComponent().appending(path: "invalid.json")
        try Data("invalid".utf8).write(to: invalid)
        await page.validateImport(at: invalid)
        #expect(page.review == nil)
        if case .invalidBackup = page.feedback { } else { Issue.record("Expected invalid backup") }
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test(arguments: [Data("broken".utf8), Data("{\"schemaVersion\":999}".utf8)])
    func externallyChangedOriginalCannotBeOverwritten(bytes: Data) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration(isEnabled: true))
        let app = fixture(store)
        let page = AdvancedSettingsModel(app: app)
        page.reviewReset()
        try bytes.write(to: store.url, options: .atomic)
        page.confirmReplacement()
        #expect(app.configuration.isEnabled && app.configurationReplacementRevision == 0)
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test(arguments: [AppLanguage.en, .de, .fr, .ru])
    func localizedCountsHaveIndependentPluralForms(language: AppLanguage) {
        let singular = AppLocalization.string(.advancedImportBody(count1: 1, count2: 1), language: language)
        let mixed = AppLocalization.string(.advancedImportBody(count1: 2, count2: 1), language: language)
        let plural = AppLocalization.string(.advancedImportSuccessDescription(count1: 2, count2: 5), language: language)
        #expect(!singular.contains("%") && !mixed.contains("%") && !plural.contains("%"))
        if language == .en {
            #expect(singular.contains("1 profile, 1 binding"))
            #expect(mixed.contains("2 profiles, 1 binding"))
            #expect(plural.contains("2 profiles and 5 bindings imported"))
        }
        if language == .de { #expect(singular.contains("1 Profil, 1 Belegung")) }
        if language == .fr { #expect(singular.contains("1 profil, 1 règle")) }
        if language == .ru { #expect(singular.contains("профилей — 1, правил — 1")) }
    }

    @Test(arguments: AppLanguage.allCases, [false, true])
    func nativeConfirmationHasSafeDefaultAndLocalizedCounts(language: AppLanguage, isReset: Bool) throws {
        let review = AdvancedSettingsModel.Review(replacement: Configuration(), expected: Configuration(),
                                                  revision: 0, isReset: isReset)
        let alert = AdvancedConfirmationAlert.make(for: review, language: language)
        let cancel = try #require(alert.buttons.first)
        #expect(cancel.title == AppLocalization.string(.cancel, language: language))
        #expect(cancel.keyEquivalent == "\r")
        #expect(alert.window.defaultButtonCell === cancel.cell)
        #expect(alert.buttons[1].hasDestructiveAction && alert.buttons[1].keyEquivalent.isEmpty)
        #expect(!alert.messageText.isEmpty && !alert.informativeText.contains("%"))
    }

    @Test(arguments: [(EngineStatus.paused, true), (.active, true), (.outputFailed, true),
                      (.secureInput, false), (.tapFailed, false), (.interrupted, false), (.permissionRequired, false)])
    func diagnosticStartRequiresAnAvailableCapture(_ sample: (EngineStatus, Bool)) {
        let app = fixture(store())
        app.mailbox.state.withLock { $0.status = sample.0 }
        app.refresh()
        #expect(app.canStartDiagnostics == sample.1)
    }
}
