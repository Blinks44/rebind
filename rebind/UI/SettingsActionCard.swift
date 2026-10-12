import SwiftUI

/// One Settings row on a raised card: title and description, with its actions trailing.
/// Narrow windows and long translations move the actions under the text.
struct SettingsActionCard<Actions: View>: View {
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    @ViewBuilder var actions: Actions

    var body: some View {
        PermissionCard {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    label
                    Spacer(minLength: 16)
                    HStack(spacing: 8) { actions }.fixedSize()
                }
                VStack(alignment: .leading, spacing: 12) {
                    label
                    HStack(spacing: 8) { actions }
                }
            }
            .modifier(EditorSecondaryButton())
        }
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary).accessibilityAddTraits(.isHeader)
            Text(description).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
