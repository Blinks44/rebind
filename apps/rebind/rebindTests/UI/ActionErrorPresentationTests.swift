import AppKit
import Testing
@testable import rebind

@MainActor struct ActionErrorPresentationTests {
    @Test func hidingGestureGuidancePreservesActionErrorAndItsOriginalDeadline() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindNotice-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        let model = AppModel(store: store, loadConfiguration: false)
        let now = ContinuousClock.now
        model.refreshActionError(.windowLayoutFailed, now: now)
        model.setPresencePreference(\.hidesTrackpadGestureWarning, to: true)
        #expect(model.configuration.hidesTrackpadGestureWarning)
        #expect(try store.load().hidesTrackpadGestureWarning)
        #expect(model.error == .windowLayoutFailed)
        model.refreshActionError(now: now.advanced(by: .seconds(29)))
        #expect(model.error == .windowLayoutFailed)
        model.refreshActionError(now: now.advanced(by: .seconds(30)))
        #expect(model.error == nil)
    }

    @Test(arguments: [LocalizedStringResource.storageWriteFailed, .bindingInvalid])
    func preferenceSaveClearsOnlyItsStorageFailure(message: LocalizedStringResource) {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindNotice-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(store: ConfigurationStore(url: directory.appending(path: "configuration.json")),
                             loadConfiguration: false)
        model.error = message
        model.setPresencePreference(\.hidesTrackpadGestureWarning, to: true)
        #expect(model.error == (message == .storageWriteFailed ? nil : message))
    }

    @Test func actionFailureExpiresAfterThirtySeconds() {
        let model = AppModel(loadConfiguration: false)
        let now = ContinuousClock.now
        model.refreshActionError(.windowLayoutFailed, now: now)
        model.refreshActionError(now: now.advanced(by: .seconds(29)))
        #expect(model.error == .windowLayoutFailed)
        model.refreshActionError(now: now.advanced(by: .seconds(30)))
        #expect(model.error == nil)
    }

    @Test func repeatedFailureRestartsExpiry() {
        let model = AppModel(loadConfiguration: false)
        let now = ContinuousClock.now
        model.refreshActionError(.windowLayoutFailed, now: now)
        model.refreshActionError(.windowLayoutFailed, now: now.advanced(by: .seconds(20)))
        model.refreshActionError(now: now.advanced(by: .seconds(30)))
        #expect(model.error == .windowLayoutFailed)
        model.refreshActionError(now: now.advanced(by: .seconds(50)))
        #expect(model.error == nil)
    }

    @Test func transientFailureCannotReplaceOrExpirePersistentError() {
        let model = AppModel(loadConfiguration: false)
        let now = ContinuousClock.now
        model.refreshActionError(.windowLayoutFailed, now: now)
        model.error = .storageWriteFailed
        model.refreshActionError(.windowActionFailed, now: now.advanced(by: .seconds(20)))
        model.refreshActionError(now: now.advanced(by: .seconds(60)))
        #expect(model.error == .storageWriteFailed)
    }

    @Test func dismissingThenSettingAnotherErrorCancelsOldExpiry() {
        let model = AppModel(loadConfiguration: false)
        let now = ContinuousClock.now
        model.refreshActionError(.windowLayoutFailed, now: now)
        model.error = nil
        model.error = .bindingInvalid
        model.refreshActionError(now: now.advanced(by: .seconds(60)))
        #expect(model.error == .bindingInvalid)
    }

    @Test func mailboxFailureReachesPresentationWithoutExecutingAction() {
        let model = AppModel(loadConfiguration: false, sessionAllowsInput: { true })
        model.mailbox.state.withLock { $0.actionFailed = .windowLayout(.fill) }
        model.refresh()
        #expect(model.error == .windowLayoutFailed)
        #expect(model.mailbox.state.withLock { $0.actionFailed == nil })
    }

    @Test(arguments: AppLanguage.allCases)
    func longErrorDoesNotExpandNativeMenu(language: AppLanguage) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(withTitle: AppLocalization.string(.openRebind, language: language), action: nil, keyEquivalent: "")
        let slider = NSMenuItem()
        slider.view = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 48))
        menu.addItem(slider)
        let width = menu.size.width
        let message = AppLocalization.string(.windowLayoutFailed, language: language)
        let item = MenuBarController.errorItem(message, textWidth: width - 48)
        menu.insertItem(item, at: 0)
        #expect(item.title.hasSuffix("…"))
        #expect(menu.size.width <= width)
        #expect(item.toolTip == message)
        #expect(item.accessibilityLabel() == message)
        #expect(!item.isEnabled)
    }

    @Test func shortMessageStaysWhole() {
        let item = MenuBarController.errorItem("Short", textWidth: 200)
        #expect(item.title == "Short")
    }
}
