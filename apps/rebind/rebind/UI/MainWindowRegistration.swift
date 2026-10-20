import AppKit
import SwiftUI

/// Reports the actual main window without taking over SwiftUI's window delegate or lifecycle.
struct MainWindowRegistration: NSViewRepresentable {
    let presenter: MainWindowPresenter

    final class Probe: NSView {
        var presenter: MainWindowPresenter?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { presenter?.register(window) }
        }
    }

    func makeNSView(context: Context) -> Probe {
        let view = Probe()
        view.presenter = presenter
        return view
    }

    func updateNSView(_ view: Probe, context: Context) { }
}
