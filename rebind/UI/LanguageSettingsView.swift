import AppKit
import SwiftUI

struct LanguageSettingsView: View {
    let model: AppModel
    @State private var editing: LanguageSettingsModel

    init(model: AppModel, editing: LanguageSettingsModel? = nil) {
        self.model = model
        _editing = State(initialValue: editing ?? LanguageSettingsModel(app: model))
    }

    var body: some View {
        @Bindable var editing = editing
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.languageTitle).font(.headline).accessibilityAddTraits(.isHeader)
                    Text(.languageDescription).foregroundStyle(.secondary)
                }
                PermissionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            Text(.appLanguage).accessibilityHidden(true)
                            Spacer(minLength: 12)
                            EditorMenuSelector(selection: $editing.draft, title: .appLanguage,
                                choices: AppLanguagePreference.allCases, label: languageTitle,
                                compact: true, distinctSurface: true)
                            .accessibilityIdentifier("settings-language-selector")
                            .frame(width: 208, alignment: .trailing)
                            .disabled(model.storageLocked || editing.isSaving)
                        }
                        Text(editing.draft == .system ? LocalizedStringResource.systemHelp : .manualHelp)
                            .font(.callout).foregroundStyle(.secondary)
                        Text(.activeLanguage(model.activeLanguage.autonym))
                            .font(.callout).foregroundStyle(.secondary)
                        if editing.isSaving { Text(.languageSaving).foregroundStyle(.secondary) }
                        if editing.hasChanges {
                            Button(.applyLanguage) { editing.apply() }
                                .modifier(EditorSecondaryButton())
                                .disabled(model.storageLocked || editing.isSaving)
                        }
                    }
                }
                if model.storageLocked {
                    feedback(.storageUnreadable, description: .storageLockedLanguage)
                } else if editing.saveFailed {
                    feedback(.languageSaveFailed, description: .languageSaveFailedDescription)
                }
                if model.requiresLanguageReopen {
                    EditorFeedback(severity: .information, title: .reopenTitle,
                                   message: .reopenDescription(savedPreferenceName)) {
                        Button(.quitRebind) { NSApp.terminate(nil) }
                    }
                }
                Text(.namesUnchanged).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28).padding(.bottom, 28)
        }
        .onChange(of: model.configuration.languagePreference) {
            editing.draft = model.configuration.languagePreference
        }
    }

    private var savedPreferenceName: String {
        if model.configuration.languagePreference == .system {
            return AppLocalization.string(.systemDefault, language: model.activeLanguage)
        }
        return model.configuration.languagePreference.resolved(preferredLanguages: []).autonym
    }

    private func languageTitle(_ preference: AppLanguagePreference) -> LocalizedStringResource {
        if preference == .system { return .systemDefault }
        return LocalizedStringResource(stringLiteral: preference.resolved(preferredLanguages: []).autonym)
    }

    private func feedback(_ title: LocalizedStringResource,
                          description: LocalizedStringResource) -> some View {
        EditorFeedback(severity: .error, title: title, message: description)
    }
}
