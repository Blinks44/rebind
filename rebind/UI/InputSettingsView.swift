import SwiftUI

/// Explains existing recognition behavior without introducing global timing overrides.
struct InputSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.inputTitle).font(.headline).accessibilityAddTraits(.isHeader)
                    Text(.inputDescription).foregroundStyle(.secondary)
                }
                information(.pressTiming, status: .perBinding, description: .pressTimingDescription)
                information(.mouseGestures, status: .automatic, description: .mouseGesturesDescription)
                information(.inputBuiltInTrackpad, status: .experimental, description: .trackpadInputDescription)
                Text(.inputEditGuidance).font(.callout).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28).padding(.bottom, 28)
        }
    }

    private func information(_ title: LocalizedStringResource, status: LocalizedStringResource,
                             description: LocalizedStringResource) -> some View {
        PermissionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(title)
                    Spacer(minLength: 12)
                    Text(status).font(.callout).foregroundStyle(.secondary)
                }
                Text(description).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
