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
        .controlSize(usesCompactStyle ? .regular : .large)
        .buttonBorderShape(.capsule)
    }

    @ViewBuilder private var buttons: some View {
        if requirement == .accessibility {
            Button(.openSystemSettings) { model.requestAccessibility() }
                .buttonStyle(.borderedProminent)
        } else {
            Button(.allowEventSending) { model.requestEventPosting() }
                .buttonStyle(.borderedProminent)
                .disabled(model.permissions.requirement != .eventPosting)
        }
        if usesCompactStyle {
            Button(.checkAgain, action: model.refreshPermissions).modifier(EditorSecondaryButton())
        } else {
            Button(.checkAgain, action: model.refreshPermissions).buttonStyle(.bordered)
        }
    }
}
