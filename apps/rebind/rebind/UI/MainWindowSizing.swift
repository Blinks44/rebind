import AppKit
import SwiftUI

/// Reports the titlebar inset so the whole window, including its overlaid titlebar, keeps the Sketch minimum.
/// SwiftUI's content minimum otherwise adds the titlebar safe area to a view's minimum height.
struct MainWindowSizing: NSViewRepresentable {
    @SwiftUI.Binding var titlebarInset: CGFloat?

    func makeNSView(context: Context) -> MainWindowSizingView { MainWindowSizingView() }
    func updateNSView(_ view: MainWindowSizingView, context: Context) {
        view.onTitlebarInsetChange = { titlebarInset = $0 }
        view.scheduleMinimumSize()
    }
}
