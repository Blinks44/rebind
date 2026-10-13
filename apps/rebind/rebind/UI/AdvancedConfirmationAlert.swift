import AppKit

@MainActor enum AdvancedConfirmationAlert {
    static func make(for review: AdvancedSettingsModel.Review, language: AppLanguage) -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = AppLocalization.string(review.isReset ? .advancedResetConfirmTitle : .advancedImportTitle,
                                                    language: language)
        let description: LocalizedStringResource = review.isReset ? .advancedResetConfirmBody
            : .advancedImportBody(count1: review.profileCount, count2: review.bindingCount)
        alert.informativeText = AppLocalization.string(description, language: language)
        let cancel = alert.addButton(withTitle: AppLocalization.string(.cancel, language: language))
        let replace = alert.addButton(withTitle: AppLocalization.string(
            review.isReset ? .advancedResetAction : .advancedReplaceAction, language: language))
        replace.hasDestructiveAction = true
        replace.keyEquivalent = ""
        alert.layout()
        cancel.keyEquivalent = "\r"
        cancel.keyEquivalentModifierMask = []
        alert.window.defaultButtonCell = cancel.cell as? NSButtonCell
        alert.window.makeFirstResponder(cancel)
        return alert
    }

    static func present(_ alert: NSAlert, for window: NSWindow) async -> NSApplication.ModalResponse {
        // AppKit reassigns the first alert button's key equivalent to Return.
        // Preserve Escape cancellation with a monitor limited to this local sheet.
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let canceled = MainActor.assumeIsolated {
                guard event.window === alert.window, event.keyCode == 53 else { return false }
                alert.buttons.first?.performClick(nil)
                return true
            }
            return canceled ? nil : event
        }
        defer { if let monitor { NSEvent.removeMonitor(monitor) } }
        return await alert.beginSheetModal(for: window)
    }
}
