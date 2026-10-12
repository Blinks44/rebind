import SwiftUI

/// Explains existing recognition behavior without introducing global timing overrides.
struct InputSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.inputTitle).font(Theme.headline).accessibilityAddTraits(.isHeader)
                    Text(.inputDescription).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                information(.pressTiming, status: .perBinding, description: .pressTimingDescription)
                information(.mouseGestures, status: .inputFixedSensitivity, description: .mouseGesturesDescription)
                information(.inputBuiltInTrackpad, status: .experimental, description: .trackpadInputDescription)
                Text(.inputEditGuidance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 32).padding(.trailing, 40).padding(.bottom, 32)
        }
    }

    private func information(_ title: LocalizedStringResource, status: LocalizedStringResource,
                             description: LocalizedStringResource) -> some View {
        PermissionCard {
            VStack(alignment: .leading, spacing: 12) {
                PermissionStatusLabel(title: title, status: status)
                Text(description).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
