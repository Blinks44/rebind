import Foundation

nonisolated enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case en, ru, de, fr

    var locale: Locale { Locale(identifier: rawValue) }

    var autonym: String {
        switch self {
        case .en: "English"
        case .ru: "Русский"
        case .de: "Deutsch"
        case .fr: "Français"
        }
    }

    static func resolve(preferredLanguages: [String]) -> Self {
        for identifier in preferredLanguages {
            if let code = Locale(identifier: identifier).language.languageCode?.identifier,
               let supported = Self(rawValue: code) { return supported }
        }
        return .en
    }
}

nonisolated enum AppLanguagePreference: String, Codable, CaseIterable, Sendable {
    case system, en, ru, de, fr

    func resolved(preferredLanguages: [String]) -> AppLanguage {
        switch self {
        case .system: AppLanguage.resolve(preferredLanguages: preferredLanguages)
        case .en: .en
        case .ru: .ru
        case .de: .de
        case .fr: .fr
        }
    }
}
