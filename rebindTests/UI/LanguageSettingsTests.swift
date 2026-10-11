import Foundation
import Testing
@testable import rebind

@MainActor struct LanguageSettingsTests {
    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindLanguage-\(UUID())/configuration.json"))
    }

    @Test(arguments: [(["es-MX", "de-CH", "ru"], AppLanguage.de),
                      (["ru-RU", "en"], .ru), (["fr_CA", "de"], .fr),
                      (["ja", "zh-Hans"], .en), ([], .en)])
    func orderedSystemResolution(_ sample: ([String], AppLanguage)) {
        #expect(AppLanguage.resolve(preferredLanguages: sample.0) == sample.1)
        #expect(AppLanguagePreference.system.resolved(preferredLanguages: sample.0) == sample.1)
    }

    @Test(arguments: AppLanguagePreference.allCases)
    func roundTripAndNextLaunchActivation(_ preference: AppLanguagePreference) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let model = AppModel(store: store, preferredLanguages: ["de-AT"])
        #expect(model.activeLanguage == .de)
        try model.saveLanguagePreference(preference)
        #expect(model.activeLanguage == .de)
        #expect(model.requiresLanguageReopen == (preference.resolved(preferredLanguages: ["de"]) != .de))
        let relaunched = AppModel(store: store, preferredLanguages: ["de-AT"])
        #expect(relaunched.configuration.languagePreference == preference)
        #expect(relaunched.activeLanguage == preference.resolved(preferredLanguages: ["de-AT"]))
        #expect(!relaunched.requiresLanguageReopen)
    }

    @Test func languageSavePreservesPendingInputProfilesAndRecorder() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: [],
            action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)), activation: .hold)
        var configuration = Configuration(isEnabled: true, bindings: [binding])
        configuration.hasCompletedSetup = true
        try configuration.createProfile(name: "Profil Русский Français", copying: configuration.selectedProfileID)
        try store.save(configuration)
        let model = AppModel(store: store, preferredLanguages: ["en"])
        model.mailbox.configure(configuration)
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(99), phase: .down), secureInput: false))
        let revision = model.mailbox.state.withLock { $0.actionRevision }
        let recorder = RecordingRequest(target: .output)
        model.recording = recorder
        try model.saveLanguagePreference(.fr)
        var expected = configuration
        expected.languagePreference = .fr
        #expect(model.configuration == expected)
        #expect(try store.load() == expected)
        #expect(model.recording == recorder)
        #expect(model.mailbox.state.withLock { $0.actionRevision == revision && $0.enabled })
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(99), phase: .up), secureInput: false))
    }

    @Test func draftDiscardNoOpAndFailureRetry() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration())
        var projected: [AppLanguagePreference] = []
        let model = AppModel(store: store, preferredLanguages: ["en"],
            languagePreferenceSaved: { projected.append($0) })
        let page = LanguageSettingsModel(app: model)
        let original = try Data(contentsOf: store.url)
        page.apply()
        #expect(try Data(contentsOf: store.url) == original)
        #expect(projected.isEmpty)
        page.draft = .ru
        #expect(LanguageSettingsModel(app: model).draft == .system)
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        page.apply()
        #expect(page.saveFailed && page.draft == .ru && page.hasChanges && !page.isSaving)
        #expect(model.configuration.languagePreference == .system && model.activeLanguage == .en)
        #expect(projected.isEmpty)
        try FileManager.default.removeItem(at: store.url)
        page.apply()
        #expect(!page.saveFailed && !page.hasChanges)
        #expect(try store.load().languagePreference == .ru)
        #expect(projected == [.ru])
        #expect(model.activeLanguage == .en && model.requiresLanguageReopen)
        try model.saveLanguagePreference(.en)
        #expect(!model.requiresLanguageReopen)
    }

    @Test func cocoaProjectionIsAppScopedAndSystemRemovesManualOverride() throws {
        let domain = "RebindLanguageTest-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let projection = AppLanguageDefaults(defaults: defaults)
        projection.apply(.fr)
        #expect(defaults.persistentDomain(forName: domain)?["AppleLanguages"] as? [String] == ["fr"])
        projection.apply(.system)
        #expect(defaults.persistentDomain(forName: domain)?["AppleLanguages"] == nil)
    }

    @Test(arguments: [Data("broken".utf8), Data("{\"schemaVersion\":999}".utf8)])
    func protectedStorageCannotBeOverwritten(_ bytes: Data) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: store.url)
        let model = AppModel(store: store, preferredLanguages: ["fr"])
        #expect(model.storageLocked)
        let page = LanguageSettingsModel(app: model)
        page.draft = .ru
        page.apply()
        #expect(throws: ConfigurationError.incompatible) { try model.saveLanguagePreference(.ru) }
        #expect(try Data(contentsOf: store.url) == bytes)
        #expect(model.configuration.languagePreference == .system && model.activeLanguage == .fr)
    }

    @Test(arguments: 1...23)
    func legacyConfigurationsDefaultToSystemWithoutRewriting(_ version: Int) throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var legacy = Configuration(schemaVersion: version)
        legacy.hasCompletedSetup = version != 23
        let bytes = try JSONEncoder().encode(legacy)
        try bytes.write(to: store.url)
        let loaded = try store.load()
        #expect(loaded.schemaVersion == Configuration.currentSchemaVersion && loaded.languagePreference == .system)
        #expect(loaded.hasCompletedSetup == (version != 23))
        #expect(try Data(contentsOf: store.url) == bytes)
    }

    @Test(arguments: ["null", "7", "\"es\"", "{}"])
    func malformedCurrentPreferenceIsRejected(_ raw: String) throws {
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(Configuration())) as? [String: Any])
        object["languagePreference"] = try JSONSerialization.jsonObject(with: Data(raw.utf8), options: .fragmentsAllowed)
        let bytes = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Configuration.self, from: bytes) }
        object.removeValue(forKey: "languagePreference")
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Configuration.self, from: JSONSerialization.data(withJSONObject: object))
        }
    }

    @Test(arguments: [(AppLanguage.en, "Settings"), (.ru, "Настройки"),
                      (.de, "Einstellungen"), (.fr, "Réglages")])
    func resolvedFoundationStringsUseExplicitLanguage(_ sample: (AppLanguage, String)) {
        #expect(AppLocalization.string(.settingsTitle, language: sample.0) == sample.1)
    }
}
