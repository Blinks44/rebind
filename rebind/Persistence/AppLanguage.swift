import Foundation

nonisolated enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case en, ru, de, fr, es
    case zhHans = "zh-Hans"

    var locale: Locale { Locale(identifier: rawValue) }

    var autonym: String {
        switch self {
        case .en: "English"
        case .ru: "Русский"
        case .de: "Deutsch"
        case .fr: "Français"
        case .es: "Español"
        case .zhHans: "简体中文"
        }
    }

    static func resolve(preferredLanguages: [String]) -> Self {
        for identifier in preferredLanguages {
            let language = Locale(identifier: identifier).language
            guard let code = language.languageCode?.identifier else { continue }
            if code == "zh" {
                // Only Simplified Chinese is translated; Traditional falls through to the next preference.
                let script = language.script?.identifier ?? Locale.Language(identifier: identifier).maximalIdentifier
                if script.contains("Hans") { return .zhHans }
                continue
            }
            if let supported = Self(rawValue: code) { return supported }
        }
        return .en
    }
}

nonisolated enum AppLanguagePreference: String, Codable, CaseIterable, Sendable {
    case system, en, ru, de, fr, es
    case zhHans = "zh-Hans"

    func resolved(preferredLanguages: [String]) -> AppLanguage {
        switch self {
        case .system: AppLanguage.resolve(preferredLanguages: preferredLanguages)
        case .en: .en
        case .ru: .ru
        case .de: .de
        case .fr: .fr
        case .es: .es
        case .zhHans: .zhHans
        }
    }
}
