import Foundation
import Observation

/// Page-local draft; constructing a fresh page discards an unapplied choice.
@MainActor @Observable final class LanguageSettingsModel {
    var draft: AppLanguagePreference
    private(set) var saveFailed = false
    private(set) var isSaving = false
    @ObservationIgnored private let app: AppModel

    init(app: AppModel) {
        self.app = app
        draft = app.configuration.languagePreference
    }

    var hasChanges: Bool { draft != app.configuration.languagePreference }

    func apply() {
        guard hasChanges, !isSaving, !app.storageLocked else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try app.saveLanguagePreference(draft)
            saveFailed = false
        } catch { saveFailed = true }
    }
}
