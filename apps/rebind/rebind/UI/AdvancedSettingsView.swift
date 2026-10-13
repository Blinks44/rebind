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
    @State private var windowAnchor = NSView()
    @State private var confirmation: NSAlert?
    @State private var copiedReport = false

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
                SettingsActionCard(title: .advancedDiagnosticsTitle,
                                   description: model.storageLocked ? .advancedDiagnosticsUnavailableBody : .advancedDiagnosticsDescription) {
                    Button(.advancedDiagnosticsAction) { showingDiagnostics = true }.secondaryButton()
                }
                if model.storageLocked {
                    Banner(severity: .warning, title: .advancedProtectedTitle, message: .advancedProtectedBody) {
                        ViewThatFits(in: .horizontal) {
                            HStack { protectedActions }
                            VStack(alignment: .leading) { protectedActions }
                        }
                    }
                    if let feedback = editing.feedback { feedbackCard(feedback) }
                    SettingsActionCard(title: .advancedResetUnavailableTitle, description: .advancedResetUnavailableBody) { EmptyView() }
                } else {
                    if editing.isValidating {
                        Banner(severity: .information, title: .advancedConfigurationTitle,
                                       message: .advancedValidationDescription) {
                            ProgressView().controlSize(.small)
                        }
                    } else {
                        SettingsActionCard(title: .advancedConfigurationTitle,
                                           description: .advancedConfigurationDescription) {
                            transferActions
                        }
                    }
                    if let feedback = editing.feedback, !feedbackBelongsToReset {
                        feedbackCard(feedback)
                    }
                    SettingsActionCard(title: .advancedResetTitle,
                                       description: editing.isValidating ? .advancedValidationResetDescription : .advancedResetDescription) {
                        Button(.advancedResetAction) { editing.reviewReset() }.disabled(busy).secondaryButton()
                    }
                    if let feedback = editing.feedback, feedbackBelongsToReset {
                        feedbackCard(feedback)
                    }
                }
                SettingsActionCard(title: .supportReportTitle, description: .supportReportDescription) {
                    Button(copiedReport ? LocalizedStringResource.supportReportCopied : .supportReportCopy) {
                        NSPasteboard.general.clearContents()
                        copiedReport = NSPasteboard.general.setString(model.supportReport(), forType: .string)
                    }.secondaryButton()
                }
                if model.requiresLanguageReopen {
                    Banner(severity: .information, title: .reopenTitle, message: .reopenDescription(savedLanguageName)) {
                        Button(.quitRebind) { NSApp.terminate(nil) }.secondaryButton()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 32).padding(.trailing, 40).padding(.bottom, 32)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { request = FileRequest(importURL: url) }
            else { editing.importPanelFailed() }
        }
        .sheet(isPresented: $showingDiagnostics) { InputDiagnosticsView(model: model) }
        .background { AdvancedWindowAnchor(view: windowAnchor).frame(width: 0, height: 0).accessibilityHidden(true) }
        .task(id: editing.review?.id) {
            guard let review = editing.review, let window = windowAnchor.window else { return }
            let alert = AdvancedConfirmationAlert.make(for: review, language: model.activeLanguage)
            confirmation = alert
            let response = await AdvancedConfirmationAlert.present(alert, for: window)
            confirmation = nil
            guard !Task.isCancelled, editing.review?.id == review.id else { return }
            if response == .alertSecondButtonReturn { editing.confirmReplacement() }
            else { editing.cancelReview() }
        }
        .task(id: request) {
            guard let current = request else { return }
            defer { if request?.id == current.id { request = nil } }
            if let url = current.importURL { await editing.validateImport(at: url) }
            else { await exportWithPanel() }
        }
        .onDisappear {
            panel?.cancel(nil)
            if let sheet = confirmation?.window, let parent = sheet.sheetParent {
                parent.endSheet(sheet, returnCode: .abort)
            }
            request = nil
            importing = false
            editing.cancelReview()
        }
        .onChange(of: model.configurationReplacementRevision) {
            if let review = editing.review, review.revision != model.configurationReplacementRevision {
                if let sheet = confirmation?.window, let parent = sheet.sheetParent {
                    parent.endSheet(sheet, returnCode: .abort)
                }
                editing.cancelReview()
            }
        }
    }

    private var savedLanguageName: String {
        model.configuration.languagePreference == .system
            ? AppLocalization.string(.systemDefault, language: model.activeLanguage)
            : model.configuration.languagePreference.resolved(preferredLanguages: []).autonym
    }

    @ViewBuilder private var transferActions: some View {
        Button(.advancedConfigurationAction) { request = FileRequest(importURL: nil) }.disabled(busy).secondaryButton()
        Button(.advancedConfigurationSecondaryAction) { importing = true }.disabled(busy).secondaryButton()
    }

    @ViewBuilder private var protectedActions: some View {
        Button(.advancedRevealOriginal) { NSWorkspace.shared.activateFileViewerSelecting([model.configurationFileURL]) }.secondaryButton()
        Button(.advancedExportOriginal) { request = FileRequest(importURL: nil) }.disabled(busy).secondaryButton()
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

    private var feedbackBelongsToReset: Bool {
        switch editing.feedback {
        case .reset: true
        case .writeFailed: editing.review?.isReset == true
        default: false
        }
    }

    @ViewBuilder private func feedbackCard(_ feedback: AdvancedSettingsModel.Feedback) -> some View {
        switch feedback {
        case .imported(let profiles, let bindings):
            Banner(severity: .success, title: .advancedImportSuccess,
                           message: .advancedImportSuccessDescription(count1: profiles, count2: bindings))
        case .reset:
            Banner(severity: .success, title: .advancedResetSuccess, message: .advancedResetSuccessDescription)
        case .exported:
            Banner(severity: .success, title: .advancedExportSuccess)
        case .invalidBackup, .incompatibleBackup:
            Banner(severity: .error, title: .advancedImportRejectedTitle,
                           message: isIncompatible(feedback) ? .advancedImportRejectedBody : .advancedInvalidBackupBody) {
                Button(.advancedChooseBackup) { importing = true }.disabled(busy).secondaryButton()
            }
        case .writeFailed:
            Banner(severity: .error, title: .advancedWriteFailedTitle, message: .advancedWriteFailedBody) {
                Button(.advancedRetry) {
                    // A retry requests a fresh review; it never silently commits a stale one.
                    if editing.review?.isReset == true { editing.reviewReset() }
                    else { editing.cancelReview(); importing = true }
                }.disabled(busy).secondaryButton()
            }
        case .exportFailed:
            Banner(severity: .error, title: .advancedExportFailedTitle, message: .advancedExportFailedBody) {
                Button(.advancedRetry) { request = FileRequest(importURL: nil) }.disabled(busy).secondaryButton()
            }
        case .staleReview:
            Banner(severity: .error, title: .advancedWriteFailedTitle, message: .advancedStaleReviewBody)
        }
    }

    private func isIncompatible(_ feedback: AdvancedSettingsModel.Feedback) -> Bool {
        if case .incompatibleBackup = feedback { return true }
        return false
    }
}

private struct AdvancedWindowAnchor: NSViewRepresentable {
    let view: NSView
    func makeNSView(context: Context) -> NSView { view }
    func updateNSView(_ nsView: NSView, context: Context) { }
}
