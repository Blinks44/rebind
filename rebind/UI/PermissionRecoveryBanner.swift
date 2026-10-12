import SwiftUI

/// Missing access leaves rules editable and provides a route to permission Settings.
struct PermissionRecoveryBanner: View {
    let model: AppModel
    let reviewPermissions: () -> Void

    var body: some View {
        if let requirement = model.permissions.requirement {
            EditorFeedback(severity: .warning,
                title: requirement == .accessibility ? .recoveryAccessibilityTitle : .recoveryEventTitle,
                message: requirement == .accessibility ? .recoverySavedRules : .recoverySendingPurpose) {
                HStack(spacing: 10) {
                    if requirement == .accessibility {
                        Button(.openSystemSettings) { model.requestAccessibility() }
                    } else {
                        Button(.allowEventSending) { model.requestEventPosting() }
                    }
                    Button(.reviewPermissions, action: reviewPermissions)
                }
            }
        }
    }
}
