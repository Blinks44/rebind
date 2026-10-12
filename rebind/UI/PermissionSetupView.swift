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
                    PermissionCard(insets: EdgeInsets()) {
                        VStack(spacing: 0) {
                            if model.permissions.requirement == .accessibility {
                                row(.eventSendingTitle, status: .permissionsWaitingAccessibility, isWarning: true,
                                    description: .permissionsSendingWaiting)
                                Theme.separator.frame(height: 1).padding(.horizontal, 20)
                            }
                            row(.inputMonitoringTitle, status: .notRequired, description: .otherPermissionsPurpose)
                        }
                    }
                    Text(.privacyAssurance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    if let error = model.error { Text(error).font(Theme.callout).foregroundStyle(Theme.dangerText) }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 12) {
                Spacer(minLength: 0)
                if context == .recovery {
                    Button(.close) { dismiss() }.keyboardShortcut(.cancelAction).modifier(EditorSecondaryButton())
                } else {
                    if !model.permissions.allowsRemapping {
                        Button(.setUpLater) { finishSetup() }.keyboardShortcut(.cancelAction).modifier(EditorSecondaryButton())
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
            .padding(.horizontal, 32).padding(.bottom, 32).padding(.top, 16)
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 560, idealHeight: 580)
        .background(Theme.sheetSurface)
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
                EditorFeedback(severity: .warning,
                    title: requirement == .accessibility ? .accessibilityTitle : .eventSendingTitle,
                    message: context == .recovery ? .accessLostPurpose
                        : requirement == .accessibility ? .accessibilityPurpose : .eventSendingPurpose)
                PermissionAccessControls(model: model, requirement: requirement)
                Text(requirement == .eventPosting ? LocalizedStringResource.eventSendingSteps
                     : context == .recovery ? .restoreSteps : .accessibilitySteps)
                    .font(Theme.callout).foregroundStyle(Theme.textSecondary)
            } else {
                EditorFeedback(severity: .success, title: .ready,
                    message: context == .recovery ? .permissionsRespectsPause : .readyPurpose) {
                    Button(.checkAgain) { model.refreshPermissions() }
                }
                Text(.backgroundHint).font(Theme.callout).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func row(_ title: LocalizedStringResource, status: LocalizedStringResource, isWarning: Bool = false,
                     description: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            PermissionStatusLabel(title: title, status: status, isWarning: isWarning)
            Text(description).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20).padding(.vertical, 14).frame(maxWidth: .infinity, alignment: .leading)
    }

    private func finishSetup() {
        if model.completePermissionSetup() { dismiss() }
    }
}
