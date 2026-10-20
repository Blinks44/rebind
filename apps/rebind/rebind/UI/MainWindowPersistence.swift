import AppKit
import SwiftUI

/// Saves geometry independently of scene restoration, which stays disabled for background launch.
struct MainWindowPersistence: NSViewRepresentable {
    var frameName = "RebindMainWindow"

    final class Probe: NSView {
        var frameName = "RebindMainWindow"

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            // Let SwiftUI apply its initial default size and content constraints first.
            let name = frameName
            DispatchQueue.main.async { [weak window] in
                guard let window else { return }
                window.setFrameUsingName(name)
                window.setFrameAutosaveName(name)
            }
        }
    }

    func makeNSView(context: Context) -> Probe {
        let view = Probe()
        view.frameName = frameName
        return view
    }
    func updateNSView(_ view: Probe, context: Context) { }
}
