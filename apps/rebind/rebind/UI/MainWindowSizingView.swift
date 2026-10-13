import AppKit
import Combine

final class MainWindowSizingView: NSView {
    private var windowObservations: [AnyCancellable] = []
    private var updateScheduled = false
    private var reportedTitlebarInset: CGFloat?
    var onTitlebarInsetChange: ((CGFloat) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        windowObservations = []
        if let window {
            windowObservations = [NSWindow.didResizeNotification, NSWindow.didBecomeKeyNotification,
                                  NSWindow.didResignKeyNotification, NSWindow.didExitFullScreenNotification].map { name in
                NotificationCenter.default.publisher(for: name)
                .filter { [weak window] notification in
                    (notification.object as? NSWindow) === window
                }
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.scheduleMinimumSize() }
            }
        }
        scheduleMinimumSize()
    }

    override func layout() {
        super.layout()
        scheduleMinimumSize()
    }

    func scheduleMinimumSize() {
        guard !updateScheduled else { return }
        updateScheduled = true
        // SwiftUI updates content-size constraints after attaching/updating the hosting view.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            updateScheduled = false
            guard let window else { return }
            let inset = max(0, window.frame.height - window.contentLayoutRect.height)
            if reportedTitlebarInset != inset {
                reportedTitlebarInset = inset
                onTitlebarInsetChange?(inset)
            }
        }
    }
}
