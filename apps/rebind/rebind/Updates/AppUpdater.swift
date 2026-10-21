import AppKit
import Sparkle

/// Sparkle checks the signed GitHub appcast, downloads, verifies and installs updates with its
/// standard windows. Rebind only offers the command and the automatic-check preference, which
/// Sparkle stores itself. No system profile or configuration is sent.
@Observable final class AppUpdater {
    private(set) var canCheckForUpdates = false
    @ObservationIgnored private let controller: SPUStandardUpdaterController
    @ObservationIgnored private let presentation = UpdatePresentation()
    @ObservationIgnored private var observation: NSKeyValueObservation?

    /// Tests and fixtures create the controller without starting scheduled checks.
    init(startsUpdater: Bool) {
        controller = SPUStandardUpdaterController(startingUpdater: startsUpdater, updaterDelegate: nil,
                                                  userDriverDelegate: presentation)
        observation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            MainActor.assumeIsolated { self?.canCheckForUpdates = updater.canCheckForUpdates }
        }
    }

    var automaticallyChecksForUpdates: Bool {
        get {
            access(keyPath: \.automaticallyChecksForUpdates)
            return controller.updater.automaticallyChecksForUpdates
        }
        set {
            withMutation(keyPath: \.automaticallyChecksForUpdates) {
                controller.updater.automaticallyChecksForUpdates = newValue
            }
        }
    }

    func checkForUpdates() { controller.checkForUpdates(nil) }
}

/// With "Show in Dock" off Rebind is an accessory app, so a scheduled update window would open
/// behind other apps. Bring it forward; closing it restores the Dock preference as for any window.
private final class UpdatePresentation: NSObject, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem,
                                                              andInImmediateFocus immediateFocus: Bool) -> Bool { true }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem,
                                                   state: SPUUserUpdateState) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }
}
