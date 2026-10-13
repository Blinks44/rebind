import AppKit
import SwiftUI

/// Makes the hosting window appear on the Space the user is looking at. Without it,
/// reopening a closed window switches back to the Space where it was first shown.
struct ActiveSpaceWindow: NSViewRepresentable {
    final class Probe: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.collectionBehavior.insert(.moveToActiveSpace)
        }
    }

    func makeNSView(context: Context) -> Probe { Probe() }
    func updateNSView(_ view: Probe, context: Context) { }
}
