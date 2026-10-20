import AppKit
import SwiftUI

/// App-scoped, user-initiated checks; no startup request or background schedule.
@Observable final class UpdateChecker {
    private(set) var isChecking = false
    private var task: Task<Void, Never>?

    isolated deinit { task?.cancel() }

    func check(language: AppLanguage) {
        guard !isChecking else { return }
        isChecking = true
        task = Task {
            defer { isChecking = false; task = nil }
            let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            do {
                let result = try await ReleaseUpdate.check(currentVersion: current)
                try Task.checkCancellation()
                await present(result, current: current, language: language)
            } catch is CancellationError { }
            catch {
                guard !Task.isCancelled else { return }
                await present(nil, current: current, language: language)
            }
        }
    }

    private func present(_ result: ReleaseUpdate?, current: String, language: AppLanguage) async {
        let alert = NSAlert()
        let title: LocalizedStringResource
        let message: LocalizedStringResource
        switch result {
        case .available(let version):
            title = .updateAvailableTitle
            message = .updateAvailableMessage(version, current)
        case .current:
            title = .updateCurrentTitle
            message = .updateCurrentMessage(current)
        case .noRelease:
            title = .updateNoReleaseTitle
            message = .updateNoReleaseMessage
        case nil:
            title = .updateCheckFailedTitle
            message = .updateCheckFailedMessage
        }
        alert.messageText = AppLocalization.string(title, language: language)
        alert.informativeText = AppLocalization.string(message, language: language)
        alert.alertStyle = result == nil ? .warning : .informational
        if case .available = result {
            alert.addButton(withTitle: AppLocalization.string(.updateOpenRelease, language: language))
        }
        alert.addButton(withTitle: AppLocalization.string(.aboutDone, language: language))
        let response: NSApplication.ModalResponse
        if let window = NSApp.keyWindow, window.attachedSheet == nil {
            response = await alert.beginSheetModal(for: window)
        } else {
            response = alert.runModal()
        }
        if case .available = result, response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(ReleaseUpdate.latestURL)
        }
    }
}
