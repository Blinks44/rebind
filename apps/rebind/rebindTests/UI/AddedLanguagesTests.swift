import Foundation
import Testing
@testable import rebind

@MainActor struct AddedLanguagesTests {
    @Test func spanishAndSimplifiedChineseResolveFromSystemPreferences() {
        #expect(AppLanguage.resolve(preferredLanguages: ["es-MX", "en-US"]) == .es)
        #expect(AppLanguage.resolve(preferredLanguages: ["zh-Hans-CN"]) == .zhHans)
        #expect(AppLanguage.resolve(preferredLanguages: ["zh-CN"]) == .zhHans)
        // Traditional Chinese is not translated: the next preference, or English, is used.
        #expect(AppLanguage.resolve(preferredLanguages: ["zh-Hant-TW", "de-DE"]) == .de)
        #expect(AppLanguage.resolve(preferredLanguages: ["zh-TW"]) == .en)
        #expect(AppLanguagePreference.zhHans.resolved(preferredLanguages: []) == .zhHans)
    }

    @Test(arguments: [(AppLanguage.es, "Añadir regla", "Ajustes"), (.zhHans, "添加规则", "设置")])
    func catalogStringsAreServedInTheNewLanguages(_ sample: (AppLanguage, String, String)) {
        #expect(AppLocalization.string(.addBinding, language: sample.0) == sample.1)
        #expect(AppLocalization.string(.settingsTitle, language: sample.0) == sample.2)
        #expect(AppLocalization.string(.mouseBindingCount(2), language: sample.0)
                != AppLocalization.string(.mouseBindingCount(2), language: .en))
    }

    @Test func presencePreferencesRoundTripAndOlderFilesGetDefaults() throws {
        var configuration = Configuration(isEnabled: true)
        configuration.showsDockIcon = false
        configuration.opensWindowAtLaunch = false
        configuration.languagePreference = .es
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(decoded == configuration)
        var old = Configuration(schemaVersion: 32, isEnabled: true)
        let migrated = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old)).migrated()
        #expect(migrated.showsDockIcon && migrated.showsMenuBarIcon && migrated.opensWindowAtLaunch)
        old.languagePreference = .zhHans
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }
}
