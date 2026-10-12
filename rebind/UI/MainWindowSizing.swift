import AppKit
import SwiftUI

/// Constrains the whole window, including its overlaid titlebar, to the Sketch minimum.
/// SwiftUI's content minimum otherwise adds the titlebar safe area to a view's minimum height.
struct MainWindowSizing: NSViewRepresentable {
    @SwiftUI.Binding var titlebarInset: CGFloat?

    func makeNSView(context: Context) -> MainWindowSizingView { MainWindowSizingView() }
    func updateNSView(_ view: MainWindowSizingView, context: Context) {
        view.onTitlebarInsetChange = { titlebarInset = $0 }
        view.scheduleMinimumSize()
    }
}
