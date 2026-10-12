import SwiftUI

/// Shared raised content and recovery controls for Settings operations.
struct SettingsActionCard<Actions: View>: View {
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    @ViewBuilder var actions: Actions

    var body: some View {
        PermissionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(Theme.headline).accessibilityAddTraits(.isHeader)
                Text(description).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                actions.modifier(EditorSecondaryButton())
            }
        }
    }
}
