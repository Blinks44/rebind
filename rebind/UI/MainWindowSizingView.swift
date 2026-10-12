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
            positionWindowButtons(in: window)
        }
    }

    private func positionWindowButtons(in window: NSWindow) {
        guard !window.styleMask.contains(.fullScreen) else { return }
        let buttons = [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton]
            .compactMap { window.standardWindowButton($0) }
        guard let first = buttons.first else { return }
        let leading = first.frame.minX
        let offsets = buttons.map { $0.frame.minX - leading }
        for (button, offset) in zip(buttons, offsets) {
            guard let parent = button.superview else { continue }
            // Screen 01: 20 pt leading; 18 pt top. Preserve native button size and spacing.
            let origin = NSPoint(x: bounds.minX + 20 + offset,
                                 y: bounds.maxY - 18 - button.frame.height)
            let position = parent.convert(origin, from: self)
            if button.frame.origin != position { button.setFrameOrigin(position) }
        }
    }
}
