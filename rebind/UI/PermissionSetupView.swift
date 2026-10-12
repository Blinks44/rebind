import AppKit
import SwiftUI

/// First-run and recovery guidance never changes the user's remapping preference.
struct PermissionSetupView: View {
    let model: AppModel
    let context: PermissionSetupContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    introduction
                    requiredAccess
                    VStack(alignment: .leading, spacing: 12) {
                        PermissionStatusLabel(title: .inputMonitoringTitle, status: .notRequired)
                        Text(.otherPermissionsPurpose).foregroundStyle(Theme.textSecondary)
                    }
                    Text(.privacyAssurance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    if let error = model.error { Text(error).foregroundStyle(.red) }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 12) {
                Spacer(minLength: 0)
                if context == .recovery {
                    Button(.close) { dismiss() }.keyboardShortcut(.cancelAction)
                } else {
                    if !model.permissions.allowsRemapping {
                        Button(.setUpLater) { finishSetup() }.keyboardShortcut(.cancelAction)
                    }
                    Button(.`continue`) {
                        model.refreshPermissions()
                        guard model.permissions.allowsRemapping else { return }
                        finishSetup()
                    }
                    .buttonStyle(PrimaryButtonStyle()).keyboardFocusRing()
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.permissions.allowsRemapping)
                }
            }
            .controlSize(.large)
            .buttonBorderShape(.capsule)
            .padding(.horizontal, 32).padding(.bottom, 32).padding(.top, 16)
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 560, idealHeight: 580)
        .background { ThemeCanvas() }
        .interactiveDismissDisabled(context == .firstRun)
    }

    private var introduction: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                .resizable().frame(width: 48, height: 48).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(context == .recovery ? LocalizedStringResource.restoreTitle : .setupTitle)
                    .font(Theme.largeTitle).accessibilityAddTraits(.isHeader)
                Text(context == .recovery ? LocalizedStringResource.restorePurpose : .setupPurpose)
                    .foregroundStyle(Theme.textSecondary)
            }
        }.frame(minHeight: 88, alignment: .top)
    }

    @ViewBuilder private var requiredAccess: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let requirement = model.permissions.requirement {
                PermissionStatusLabel(title: requirement == .accessibility ? .accessibilityTitle : .eventSendingTitle,
                                      status: context == .recovery ? .accessLost : .notEnabled, isWarning: true, isPrimary: true)
                Text(context == .recovery ? LocalizedStringResource.accessLostPurpose
                     : requirement == .accessibility ? .accessibilityPurpose : .eventSendingPurpose)
                    .foregroundStyle(Theme.textSecondary)
                PermissionAccessControls(model: model, requirement: requirement)
                Text(requirement == .eventPosting ? LocalizedStringResource.eventSendingSteps
                     : context == .recovery ? .restoreSteps : .accessibilitySteps)
                    .font(Theme.callout).foregroundStyle(Theme.textSecondary)
            } else {
                PermissionStatusLabel(title: .permissionsTitle, status: .ready, isPrimary: true)
                Text(context == .recovery ? LocalizedStringResource.permissionsRespectsPause : .readyPurpose)
                    .foregroundStyle(Theme.textSecondary)
                Button(.checkAgain) { model.refreshPermissions() }
                    .modifier(EditorSecondaryButton()).controlSize(.large).buttonBorderShape(.capsule)
                Text(.backgroundHint).font(Theme.callout).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func finishSetup() {
        if model.completePermissionSetup() { dismiss() }
    }
}
