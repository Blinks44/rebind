import SwiftUI

/// Settings → Permissions uses actual grants, independently of engine status.
struct PermissionView: View {
    let model: AppModel
    var showsSettingsHeader = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if showsSettingsHeader {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(.settingsTitle).font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                        Text(.settingsDescription).foregroundStyle(.secondary)
                    }
                }
                accessStatus
                VStack(spacing: 16) {
                    accessibilityCard
                    eventSendingCard
                    PermissionCard(isRaised: true) {
                        VStack(alignment: .leading, spacing: 12) {
                            PermissionStatusLabel(title: .inputMonitoringTitle, status: .notRequired)
                            Text(.permissionsOtherPurpose).foregroundStyle(.secondary)
                        }
                    }
                }
                Text(.privacyAssurance).font(.callout).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Button(.showApplicationInFinder, action: model.showApplicationInFinder)
                        .modifier(EditorSecondaryButton())
                    Text(.signingHint).font(.callout).foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 28).padding(.bottom, 28)
            .padding(.top, showsSettingsHeader ? 28 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background { PermissionCanvas() }
        .navigationTitle(.settingsTitle)
    }

    private var accessStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    accessStatusTitle
                    Spacer(minLength: 0)
                    if model.permissions.allowsRemapping { checkAgain }
                }
                VStack(alignment: .leading, spacing: 12) {
                    accessStatusTitle
                    if model.permissions.allowsRemapping { checkAgain }
                }
            }
            Text(statusExplanation).foregroundStyle(.secondary)
        }
    }

    private var accessStatusTitle: some View {
        Text(model.permissions.allowsRemapping ? LocalizedStringResource.permissionsAccessEnabled : .permissionsStopped)
            .font(.headline)
            .foregroundStyle(model.permissions.allowsRemapping ? Color(.permissionSuccess) : Color(.permissionWarning))
            .accessibilityAddTraits(.isHeader)
    }

    private var checkAgain: some View {
        Button(.checkAgain, action: model.refreshPermissions).modifier(EditorSecondaryButton())
    }

    private var statusExplanation: LocalizedStringResource {
        switch model.permissions.requirement {
        case .accessibility: .permissionsEnableAccessibility
        case .eventPosting: .permissionsAllowSending
        case nil: .permissionsRespectsPause
        }
    }

    private var accessibilityCard: some View {
        PermissionCard(severity: model.permissions.accessibility ? nil : .warning, isRaised: true) {
            VStack(alignment: .leading, spacing: 12) {
                PermissionStatusLabel(title: .accessibilityTitle,
                                      status: model.permissions.accessibility ? .permissionEnabled : .notEnabled,
                                      isWarning: !model.permissions.accessibility, isPrimary: !model.permissions.accessibility,
                                      isVerified: model.permissions.accessibility)
                Text(model.permissions.accessibility ? LocalizedStringResource.permissionsAccessibilityEnabled : .permissionsAccessibilityPurpose)
                    .foregroundStyle(.secondary)
                if !model.permissions.accessibility {
                    PermissionAccessControls(model: model, requirement: .accessibility, usesCompactStyle: true)
                    Text(.accessibilitySteps).font(.callout).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var eventSendingCard: some View {
        PermissionCard(severity: model.permissions.requirement == .eventPosting ? .warning : nil, isRaised: true) {
            VStack(alignment: .leading, spacing: 12) {
                PermissionStatusLabel(title: .eventSendingTitle, status: postingStatus,
                                      isWarning: !model.permissions.posting,
                                      isPrimary: model.permissions.requirement == .eventPosting,
                                      isVerified: model.permissions.posting)
                Text(postingExplanation).foregroundStyle(.secondary)
                if model.permissions.requirement == .eventPosting {
                    PermissionAccessControls(model: model, requirement: .eventPosting, usesCompactStyle: true)
                    Text(.eventSendingSteps).font(.callout).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var postingStatus: LocalizedStringResource {
        if model.permissions.posting { return .permissionEnabled }
        return model.permissions.accessibility ? .notEnabled : .permissionsWaitingAccessibility
    }

    private var postingExplanation: LocalizedStringResource {
        if model.permissions.posting { return .permissionsSendingEnabled }
        return model.permissions.accessibility ? .permissionsSendingPurpose : .permissionsSendingWaiting
    }
}
