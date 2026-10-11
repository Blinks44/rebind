import SwiftUI

/// Missing access leaves rules editable and provides a route to permission Settings.
struct PermissionRecoveryBanner: View {
    let model: AppModel
    let reviewPermissions: () -> Void

    var body: some View {
        if let requirement = model.permissions.requirement {
            PermissionCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(requirement == .accessibility ? LocalizedStringResource.recoveryAccessibilityTitle : .recoveryEventTitle)
                        .font(.headline).accessibilityAddTraits(.isHeader)
                    Text(requirement == .accessibility ? LocalizedStringResource.recoverySavedRules : .recoverySendingPurpose)
                        .foregroundStyle(.secondary)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) { actions(requirement) }
                        VStack(alignment: .leading, spacing: 12) { actions(requirement) }
                    }.controlSize(.large).buttonBorderShape(.capsule)
                }
            }
        }
    }

    @ViewBuilder private func actions(_ requirement: InputPermissionRequirement) -> some View {
        if requirement == .accessibility {
            Button(.openSystemSettings) { model.requestAccessibility() }.buttonStyle(.borderedProminent)
        } else {
            Button(.allowEventSending) { model.requestEventPosting() }.buttonStyle(.borderedProminent)
        }
        Button(.reviewPermissions, action: reviewPermissions).buttonStyle(.bordered)
    }
}
