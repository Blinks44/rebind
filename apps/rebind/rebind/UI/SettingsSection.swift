import Foundation

/// The tabs of Settings, in display order.
nonisolated enum SettingsSection: Hashable, CaseIterable {
    case general, permissions, language, advanced

    var title: LocalizedStringResource {
        switch self {
        case .general: .settingsGeneral
        case .permissions: .permissionsTitle
        case .language: .settingsLanguage
        case .advanced: .settingsAdvanced
        }
    }
}
