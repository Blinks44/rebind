import SwiftUI

/// Explains existing recognition behavior without introducing global timing overrides.
struct InputSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.inputTitle).font(.headline).accessibilityAddTraits(.isHeader)
                    Text(.inputDescription).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                information(.pressTiming, status: .perBinding, description: .pressTimingDescription)
                information(.mouseGestures, status: .inputFixedSensitivity, description: .mouseGesturesDescription)
                information(.inputBuiltInTrackpad, status: .experimental, description: .trackpadInputDescription)
                Text(.inputEditGuidance).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28).padding(.bottom, 28)
        }
    }

    private func information(_ title: LocalizedStringResource, status: LocalizedStringResource,
                             description: LocalizedStringResource) -> some View {
        PermissionCard(isRaised: true) {
            VStack(alignment: .leading, spacing: 12) {
                PermissionStatusLabel(title: title, status: status)
                Text(description).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
