import Foundation

/// Projects the authoritative JSON preference into Cocoa's app-specific launch language.
/// Native menus load before a later SwiftUI locale change; no global defaults are written.
@MainActor struct AppLanguageDefaults {
    let defaults: UserDefaults

    func apply(_ preference: AppLanguagePreference) {
        if preference == .system {
            defaults.removeObject(forKey: "AppleLanguages")
        } else {
            defaults.set([preference.rawValue], forKey: "AppleLanguages")
        }
    }

    static var systemPreferredLanguages: [String] {
        // Locale.preferredLanguages also reflects this app's manual Cocoa override.
        // System Default must instead resolve the unchanged global language order.
        UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleLanguages"] as? [String]
            ?? Locale.preferredLanguages
    }
}
