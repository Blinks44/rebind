import SwiftUI

struct PermissionView: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(.permissionsTitle, systemImage: "lock.shield").font(.headline)
            Text(.permissionsExplanation).foregroundStyle(.secondary)
            HStack {
                Label(.accessibilityPermission, systemImage: model.accessibilityGranted && model.postingGranted ? "checkmark.circle" : "exclamationmark.circle")
                Spacer()
                Button(.grantAccess) { model.requestAccessibility() }
                Button(.openSettings) { model.openPrivacyPane("Privacy_Accessibility") }
            }
            HStack {
                Label(.inputMonitoringPermission, systemImage: model.inputMonitoringGranted ? "checkmark.circle" : "exclamationmark.circle")
                Spacer()
                Button(.grantAccess) { model.requestInputMonitoring() }
                Button(.openSettings) { model.openPrivacyPane("Privacy_ListenEvent") }
            }
            Button(.refreshPermissions) { model.refreshPermissions() }
            Text(.signingHint).font(.caption).foregroundStyle(.secondary)
        }.padding()
    }
}
