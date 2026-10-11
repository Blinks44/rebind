import Foundation
import Observation

@MainActor @Observable final class AdvancedSettingsModel {
    struct Review {
        let id = UUID()
        let replacement: Configuration
        let expected: Configuration
        let revision: UInt64
        let isReset: Bool

        var profileCount: Int { replacement.profiles.count }
        var bindingCount: Int { replacement.profiles.reduce(0) { $0 + $1.bindings.count } }
    }

    enum Feedback: Equatable {
        case imported(Int, Int), reset, exported, invalidBackup, incompatibleBackup
        case writeFailed, exportFailed, staleReview
    }

    private(set) var review: Review?
    private(set) var isValidating = false
    private(set) var feedback: Feedback?
    @ObservationIgnored private let app: AppModel

    init(app: AppModel) { self.app = app }

    func validateImport(at url: URL) async {
        guard !app.storageLocked, !isValidating else { return }
        let expected = app.configuration
        let revision = app.configurationReplacementRevision
        review = nil
        feedback = nil
        isValidating = true
        defer { isValidating = false }
        do {
            let backup = try await ConfigurationFileOperations.readBackup(at: url)
            try Task.checkCancellation()
            guard app.configuration == expected, app.configurationReplacementRevision == revision else {
                feedback = .staleReview
                return
            }
            review = Review(replacement: backup.configuration, expected: expected,
                            revision: revision, isReset: false)
        } catch is CancellationError {
            // Closing the page cancels validation without an error or a replacement.
        } catch ConfigurationError.incompatible { feedback = .incompatibleBackup }
        catch { feedback = .invalidBackup }
    }

    func reviewReset() {
        guard !app.storageLocked, !isValidating else { return }
        feedback = nil
        review = Review(replacement: Configuration(), expected: app.configuration,
                        revision: app.configurationReplacementRevision, isReset: true)
    }

    func cancelReview() { review = nil }

    func importPanelFailed() { feedback = .invalidBackup }

    func confirmReplacement() {
        guard let review, !app.storageLocked, !isValidating else { return }
        do {
            try app.replaceConfiguration(with: review.replacement, expected: review.expected,
                                         revision: review.revision)
            feedback = review.isReset ? .reset : .imported(review.profileCount, review.bindingCount)
            self.review = nil
        } catch ConfigurationReplacementError.staleReview {
            self.review = nil
            feedback = .staleReview
        } catch { feedback = .writeFailed }
    }

    func export(to url: URL) async {
        feedback = nil
        do {
            if app.storageLocked {
                try await ConfigurationFileOperations.exportOriginal(at: app.configurationFileURL, to: url)
            } else {
                let backup = try ConfigurationBackup(configuration: app.configuration)
                try await ConfigurationFileOperations.export(backup, to: url, protecting: app.configurationFileURL)
            }
            feedback = .exported
        } catch is CancellationError { }
        catch { feedback = .exportFailed }
    }
}
