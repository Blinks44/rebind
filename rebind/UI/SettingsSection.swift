import Foundation

/// Implemented settings destinations; other sections remain separate deliveries.
nonisolated enum SettingsSection: Hashable, CaseIterable {
    case general, permissions

    var title: LocalizedStringResource {
        switch self {
        case .general: .settingsGeneral
        case .permissions: .permissionsTitle
        }
    }
}
