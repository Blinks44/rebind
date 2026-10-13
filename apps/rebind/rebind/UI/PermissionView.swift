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
                        Text(.settingsTitle).font(Theme.largeTitle).accessibilityAddTraits(.isHeader)
                        Text(.settingsDescription).foregroundStyle(Theme.textSecondary)
                    }
                }
                accessStatus
                VStack(spacing: 16) {
                    accessibilityCard
                    eventSendingCard
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            StatusLabel(title: .inputMonitoringTitle, status: .notRequired)
                            Text(.permissionsOtherPurpose).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                Text(.privacyAssurance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                VStack(alignment: .leading, spacing: 12) {
                    Button(.showApplicationInFinder, action: model.showApplicationInFinder)
                        .secondaryButton()
                    Text(.signingHint).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, 32).padding(.trailing, 40).padding(.bottom, 32)
            .padding(.top, showsSettingsHeader ? 28 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
            Text(statusExplanation).foregroundStyle(Theme.textSecondary)
        }
    }

    private var accessStatusTitle: some View {
        Text(model.permissions.allowsRemapping ? LocalizedStringResource.permissionsAccessEnabled : .permissionsStopped)
            .font(Theme.headline)
            .foregroundStyle(model.permissions.allowsRemapping ? Theme.successText : Theme.warningText)
            .accessibilityAddTraits(.isHeader)
    }

    private var checkAgain: some View {
        Button(.checkAgain, action: model.refreshPermissions).secondaryButton()
    }

    private var statusExplanation: LocalizedStringResource {
        switch model.permissions.requirement {
        case .accessibility: .permissionsEnableAccessibility
        case .eventPosting: .permissionsAllowSending
        case nil: .permissionsRespectsPause
        }
    }

    private var accessibilityCard: some View {
        Card(severity: model.permissions.accessibility ? nil : .warning) {
            VStack(alignment: .leading, spacing: 12) {
                StatusLabel(title: .accessibilityTitle,
                                      status: model.permissions.accessibility ? .permissionEnabled : .notEnabled,
                                      isWarning: !model.permissions.accessibility, isPrimary: !model.permissions.accessibility,
                                      isVerified: model.permissions.accessibility)
                Text(model.permissions.accessibility ? LocalizedStringResource.permissionsAccessibilityEnabled : .permissionsAccessibilityPurpose)
                    .foregroundStyle(Theme.textSecondary)
                if !model.permissions.accessibility {
                    PermissionAccessControls(model: model, requirement: .accessibility, usesCompactStyle: true)
                    Text(.accessibilitySteps).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var eventSendingCard: some View {
        Card(severity: model.permissions.requirement == .eventPosting ? .warning : nil) {
            VStack(alignment: .leading, spacing: 12) {
                StatusLabel(title: .eventSendingTitle, status: postingStatus,
                                      isWarning: !model.permissions.posting,
                                      isPrimary: model.permissions.requirement == .eventPosting,
                                      isVerified: model.permissions.posting)
                Text(postingExplanation).foregroundStyle(Theme.textSecondary)
                if model.permissions.requirement == .eventPosting {
                    PermissionAccessControls(model: model, requirement: .eventPosting, usesCompactStyle: true)
                    Text(.eventSendingSteps).font(Theme.callout).foregroundStyle(Theme.textSecondary)
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
