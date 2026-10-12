import SwiftUI

/// Shared raised content and recovery controls for Settings operations.
struct SettingsActionCard<Actions: View>: View {
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    @ViewBuilder var actions: Actions

    var body: some View {
        PermissionCard(isRaised: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline).accessibilityAddTraits(.isHeader)
                Text(description).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                actions.modifier(EditorSecondaryButton())
            }
        }
    }
}
