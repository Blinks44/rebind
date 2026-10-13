import SwiftUI

/// Explicit grant requests and passive checks shared by setup and recovery.
struct PermissionAccessControls: View {
    let model: AppModel
    let requirement: InputPermissionRequirement
    var usesCompactStyle = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { buttons }
            VStack(alignment: .leading, spacing: 12) { buttons }
        }
        .controlSize(usesCompactStyle ? .small : .large)
    }

    @ViewBuilder private var buttons: some View {
        if requirement == .accessibility {
            Button(.openSystemSettings) { model.requestAccessibility() }
                .primaryButton()
        } else {
            Button(.allowEventSending) { model.requestEventPosting() }
                .primaryButton()
                .disabled(model.permissions.requirement != .eventPosting)
        }
        Button(.checkAgain, action: model.refreshPermissions).secondaryButton()
    }
}
