import AppKit
import SwiftUI

/// Keeps menu placement independent of the selected row's text/checkmark insets.
struct AnchoredMenu<Label: View>: View {
    let select: (Int) -> Void
    let makeMenu: (MenuSelectionTarget) -> NSMenu
    @ViewBuilder let label: Label
    @Environment(\.isEnabled) private var isEnabled
    @State private var anchorView = NSView()
    @State private var menuRequested = false
    @FocusState private var focused: Bool

    var body: some View {
        Button {
            let event = NSApp.currentEvent?.type
            requestMenu(restoreKeyboardFocus: event == .keyDown || event == .keyUp)
        } label: { label }
            .buttonStyle(.plain)
            .background { MenuAnchorView(view: anchorView).allowsHitTesting(false).accessibilityHidden(true) }
            .modifier(ControlSurface())
            .focused($focused)
            .keyboardFocusRing()
            .onKeyPress(.downArrow) {
                guard isEnabled else { return .ignored }
                requestMenu(restoreKeyboardFocus: true)
                return .handled
            }
    }

    private func requestMenu(restoreKeyboardFocus: Bool) {
        guard isEnabled, !menuRequested else { return }
        menuRequested = true
        // Leave the button/AX action before entering AppKit's nested tracking loop.
        DispatchQueue.main.async { showMenu(restoreKeyboardFocus: restoreKeyboardFocus) }
    }

    private func showMenu(restoreKeyboardFocus: Bool) {
        defer { menuRequested = false }
        guard isEnabled, anchorView.window != nil else { return }
        defer { focused = restoreKeyboardFocus }
        let target = MenuSelectionTarget(select: select)
        let menu = makeMenu(target)
        menu.autoenablesItems = false
        menu.minimumWidth = anchorView.bounds.width
        // nil positions the content frame, including the checkmark column.
        // AppKit retains screen-edge adjustment and native keyboard tracking.
        let origin = NSPoint(x: anchorView.bounds.minX, y: anchorView.bounds.minY - 8)
        withExtendedLifetime(target) { _ = menu.popUp(positioning: nil, at: origin, in: anchorView) }
    }
}
