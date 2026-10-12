import AppKit
import SwiftUI

/// Supplies the selector's actual local bounds to AppKit's menu placement.
struct EditorMenuAnchorView: NSViewRepresentable {
    let view: NSView

    func makeNSView(context: Context) -> NSView {
        view.setAccessibilityElement(false)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
