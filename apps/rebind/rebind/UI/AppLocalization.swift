import Foundation

/// One launch-time language for strings resolved outside SwiftUI's locale environment.
/// Saving a preference does not mutate the running application's localization context.
@MainActor enum AppLocalization {
    private(set) static var language = AppLanguage.resolve(preferredLanguages: Locale.preferredLanguages)

    static func configureAtLaunch(_ language: AppLanguage) { self.language = language }

    static func string(_ resource: LocalizedStringResource, language: AppLanguage? = nil) -> String {
        var localized = resource
        localized.locale = (language ?? self.language).locale
        return String(localized: localized)
    }
}
