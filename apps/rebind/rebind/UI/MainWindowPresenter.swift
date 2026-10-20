import AppKit

/// Coordinates the single SwiftUI scene with its native window across repeated menu/Dock opens.
@MainActor final class MainWindowPresenter {
    private weak var window: NSWindow?
    private var openScene: (() -> Void)?
    private var presentationRequested = false
    private let activate: () -> Void

    init(activate: @escaping () -> Void = { NSApp.activate() }) {
        self.activate = activate
    }

    /// Installed only by the app-lifetime menu host, never by the window being opened/closed.
    func installSceneOpener(_ open: @escaping () -> Void) {
        openScene = open
        if presentationRequested, window == nil { open() }
    }

    func register(_ window: NSWindow) {
        self.window = window
        if presentationRequested {
            DispatchQueue.main.async { [weak self] in self?.revealWindowIfRequested() }
        }
    }

    func show() {
        presentationRequested = true
        if NSApp.activationPolicy() != .regular { NSApp.setActivationPolicy(.regular) }
        // Leave native menu tracking and the activation-policy transition before presenting.
        DispatchQueue.main.async { [weak self] in
            guard let self, presentationRequested else { return }
            // Match the dashboard route used by Monny: request activation before ordering a
            // window into a stage. Reuse the native window instead of reopening a live scene.
            activate()
            if window != nil { revealWindowIfRequested() } else { openScene?() }
        }
    }

    private func revealWindowIfRequested() {
        guard presentationRequested, let window else { return }
        presentationRequested = false
        if window.isMiniaturized { window.deminiaturize(nil) }
        NSApp.unhide(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
