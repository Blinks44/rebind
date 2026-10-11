import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct AdvancedSettingsView: View {
    let model: AppModel
    @State private var editing: AdvancedSettingsModel
    @State private var importing = false
    @State private var showingDiagnostics = false
    @State private var request: FileRequest?
    @State private var panel: NSSavePanel?
    @State private var confirming = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    private struct FileRequest: Equatable {
        let id = UUID()
        let importURL: URL?
    }

    init(model: AppModel, editing: AdvancedSettingsModel? = nil) {
        self.model = model
        _editing = State(initialValue: editing ?? AdvancedSettingsModel(app: model))
    }

    private var busy: Bool { importing || request != nil || editing.isValidating }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                actionCard(.advancedDiagnosticsTitle,
                           description: model.storageLocked ? .advancedDiagnosticsUnavailableBody : .advancedDiagnosticsDescription) {
                    Button(.advancedDiagnosticsAction) { showingDiagnostics = true }
                }
                if model.storageLocked {
                    actionCard(.advancedProtectedTitle, description: .advancedProtectedBody) {
                        ViewThatFits(in: .horizontal) {
                            HStack { protectedActions }
                            VStack(alignment: .leading) { protectedActions }
                        }
                    }
                    actionCard(.advancedResetUnavailableTitle, description: .advancedResetUnavailableBody) { EmptyView() }
                } else {
                    actionCard(.advancedConfigurationTitle,
                               description: editing.isValidating ? .advancedValidationDescription : .advancedConfigurationDescription) {
                        if editing.isValidating { ProgressView().controlSize(.small) }
                        ViewThatFits(in: .horizontal) {
                            HStack { transferActions }
                            VStack(alignment: .leading) { transferActions }
                        }
                    }
                    actionCard(.advancedResetTitle,
                               description: editing.isValidating ? .advancedValidationResetDescription : .advancedResetDescription) {
                        Button(.advancedResetAction) { editing.reviewReset() }.disabled(busy)
                    }
                }
                if let feedback = editing.feedback { feedbackCard(feedback) }
                if model.requiresLanguageReopen {
                    actionCard(.reopenTitle, description: .reopenDescription(savedLanguageName)) {
                        Button(.quitRebind) { NSApp.terminate(nil) }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28).padding(.bottom, 28)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { request = FileRequest(importURL: url) }
            else { editing.importPanelFailed() }
        }
        .sheet(isPresented: $showingDiagnostics) { InputDiagnosticsView(model: model) }
        .alert(editing.review?.isReset == true ? LocalizedStringResource.advancedResetConfirmTitle : .advancedImportTitle,
               isPresented: $confirming, presenting: editing.review) { review in
            Button(.cancel, role: .cancel) { editing.cancelReview() }.keyboardShortcut(.defaultAction)
            Button(review.isReset ? LocalizedStringResource.advancedResetAction : .advancedReplaceAction,
                   role: .destructive) { editing.confirmReplacement() }
        } message: { review in
            if review.isReset { Text(.advancedResetConfirmBody) }
            else { Text(.advancedImportBody(count1: review.profileCount, count2: review.bindingCount)) }
        }
        .task(id: request) {
            guard let current = request else { return }
            defer { if request?.id == current.id { request = nil } }
            if let url = current.importURL { await editing.validateImport(at: url) }
            else { await exportWithPanel() }
        }
        .onDisappear {
            panel?.cancel(nil)
            request = nil
            importing = false
            editing.cancelReview()
        }
        .onChange(of: editing.review?.id) { confirming = editing.review != nil }
    }

    private var savedLanguageName: String {
        model.configuration.languagePreference == .system
            ? AppLocalization.string(.systemDefault, language: model.activeLanguage)
            : model.configuration.languagePreference.resolved(preferredLanguages: []).autonym
    }

    @ViewBuilder private var transferActions: some View {
        Button(.advancedConfigurationAction) { request = FileRequest(importURL: nil) }.disabled(busy)
        Button(.advancedConfigurationSecondaryAction) { importing = true }.disabled(busy)
    }

    @ViewBuilder private var protectedActions: some View {
        Button(.advancedRevealOriginal) { NSWorkspace.shared.activateFileViewerSelecting([model.configurationFileURL]) }
        Button(.advancedExportOriginal) { request = FileRequest(importURL: nil) }.disabled(busy)
    }

    private func exportWithPanel() async {
        let save = NSSavePanel()
        save.allowedContentTypes = [.json]
        save.nameFieldStringValue = model.storageLocked ? "Rebind-original.json" : "Rebind-backup.json"
        save.title = AppLocalization.string(model.storageLocked ? .advancedExportOriginal : .advancedConfigurationAction)
        save.canCreateDirectories = true
        panel = save
        defer { panel = nil }
        let response = await save.begin()
        guard response == .OK, !Task.isCancelled, let url = save.url else { return }
        await editing.export(to: url)
    }

    private func actionCard<Actions: View>(_ title: LocalizedStringResource,
                                          description: LocalizedStringResource,
                                          @ViewBuilder actions: () -> Actions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            Text(description).font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            actions().buttonStyle(.bordered).buttonBorderShape(.capsule)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12).fill(Color(.permissionSurface))
                .overlay {
                    LinearGradient(colors: [.white.opacity(colorScheme == .dark ? 0.03 : 0.12), .clear],
                                   startPoint: .top, endPoint: .bottom)
                        .clipShape(.rect(cornerRadius: 12))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12).strokeBorder(
                Color(nsColor: .separatorColor).opacity(contrast == .increased ? 1 : colorScheme == .dark ? 0.5 : 0.15))
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.06), radius: 5, y: 3)
    }

    @ViewBuilder private func feedbackCard(_ feedback: AdvancedSettingsModel.Feedback) -> some View {
        switch feedback {
        case .imported(let profiles, let bindings):
            actionCard(.advancedImportSuccess, description: .advancedImportSuccessDescription(count1: profiles, count2: bindings)) { EmptyView() }
        case .reset:
            actionCard(.advancedResetSuccess, description: .advancedResetSuccessDescription) { EmptyView() }
        case .exported:
            PermissionCard { Label(.advancedExportSuccess, systemImage: "checkmark.circle") }
        case .invalidBackup, .incompatibleBackup:
            actionCard(.advancedImportRejectedTitle,
                       description: isIncompatible(feedback) ? .advancedImportRejectedBody : .advancedInvalidBackupBody) {
                Button(.advancedChooseBackup) { importing = true }.disabled(busy)
            }
        case .writeFailed:
            actionCard(.advancedWriteFailedTitle, description: .advancedWriteFailedBody) {
                Button(.advancedRetry) {
                    // A retry requests a fresh review; it never silently commits a stale one.
                    if editing.review?.isReset == true { editing.reviewReset() }
                    else { editing.cancelReview(); importing = true }
                }.disabled(busy)
            }
        case .exportFailed:
            actionCard(.advancedExportFailedTitle, description: .advancedExportFailedBody) {
                Button(.advancedRetry) { request = FileRequest(importURL: nil) }.disabled(busy)
            }
        case .staleReview:
            actionCard(.advancedWriteFailedTitle, description: .advancedStaleReviewBody) { EmptyView() }
        }
    }

    private func isIncompatible(_ feedback: AdvancedSettingsModel.Feedback) -> Bool {
        if case .incompatibleBackup = feedback { return true }
        return false
    }
}
