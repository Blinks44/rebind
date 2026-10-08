import SwiftUI

struct PermissionView: View {
    let model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label(.permissionsTitle, systemImage: "lock.shield").font(.headline)
                Text(.permissionsExplanation).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Label(.accessibilityPermission, systemImage: model.permissions.accessibility ? "checkmark.circle" : "exclamationmark.circle")
                    Text(model.permissions.accessibility ? LocalizedStringResource.permissionGranted : .permissionMissing)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(.grantAccess) { model.requestAccessibility() }
                        .disabled(model.permissions.accessibility)
                    Button(.openSettings) { model.openPrivacyPane("Privacy_Accessibility") }
                }
                HStack {
                    Label(.eventPostingPermission, systemImage: model.permissions.posting ? "checkmark.circle" : "exclamationmark.circle")
                    Text(model.permissions.posting ? LocalizedStringResource.permissionGranted : .permissionMissing)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(.requestEventPosting) { model.requestEventPosting() }
                        .disabled(model.permissions.requirement != .eventPosting)
                }
                if model.permissions.accessibility && !model.permissions.posting {
                    Text(.postingPermissionHint).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    Label(.inputMonitoringPermission, systemImage: "info.circle")
                    Text(model.permissions.listening ? LocalizedStringResource.permissionGranted : .permissionNotRequired)
                        .foregroundStyle(.secondary)
                }
                Text(.inputMonitoringNotRequiredHint).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button(.refreshPermissions) { model.refreshPermissions() }
                    Button(.showApplicationInFinder) { model.showApplicationInFinder() }
                }
                Text(.permissionSettingsHint).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(.signingHint).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.padding().frame(maxWidth: .infinity, alignment: .leading)
        }.frame(maxHeight: 320)
    }
}
