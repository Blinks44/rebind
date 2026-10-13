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
                    Text(.languageTitle).font(Theme.headline).accessibilityAddTraits(.isHeader)
                    Text(.languageDescription).foregroundStyle(Theme.textSecondary)
                }
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            Text(.appLanguage).accessibilityHidden(true)
                            Spacer(minLength: 12)
                            MenuSelector(selection: $editing.draft, title: .appLanguage,
                                choices: AppLanguagePreference.allCases, label: languageTitle,
                                compact: true)
                            .accessibilityIdentifier("settings-language-selector")
                            .frame(width: 208, alignment: .trailing)
                            .disabled(model.storageLocked || editing.isSaving)
                        }
                        Text(editing.draft == .system ? LocalizedStringResource.systemHelp : .manualHelp)
                            .font(Theme.callout).foregroundStyle(Theme.textSecondary)
                        Text(.activeLanguage(model.activeLanguage.autonym))
                            .font(Theme.callout).foregroundStyle(Theme.textSecondary)
                        if editing.isSaving { Text(.languageSaving).foregroundStyle(Theme.textSecondary) }
                        if editing.hasChanges {
                            Button(.applyLanguage) { editing.apply() }
                                .secondaryButton()
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
                    Banner(severity: .information, title: .reopenTitle,
                                   message: .reopenDescription(savedPreferenceName)) {
                        Button(.quitRebind) { NSApp.terminate(nil) }.secondaryButton()
                    }
                }
                Text(.namesUnchanged).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 32).padding(.trailing, 40).padding(.bottom, 32)
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
        Banner(severity: .error, title: title, message: description)
    }
}
