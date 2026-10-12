import AppKit
import SwiftUI

/// A glass selector with a native menu anchored to its leading edge rather than its selected label.
struct EditorMenuSelector<Selection: Hashable>: View {
    @SwiftUI.Binding var selection: Selection
    let title: LocalizedStringResource
    let choices: [Selection]
    let label: (Selection) -> LocalizedStringResource
    var compact = false
    var distinctSurface = false
    var symbol: String?
    var singleLine = false
    @Environment(\.locale) private var locale
    @Environment(\.isEnabled) private var isEnabled
    @State private var anchorView = NSView()
    @State private var menuRequested = false
    @FocusState private var focused: Bool

    var body: some View {
        Button {
            let event = NSApp.currentEvent?.type
            requestMenu(restoreKeyboardFocus: event == .keyDown || event == .keyUp)
        } label: {
            EditorSelectorLabel(title: label(selection), symbol: symbol,
                                height: compact ? EditorMetrics.compactSelectorHeight : EditorMetrics.selectorHeight,
                                horizontalInset: compact ? 12 : 16, singleLine: singleLine)
        }
            .buttonStyle(.plain)
            .background { EditorMenuAnchorView(view: anchorView).allowsHitTesting(false).accessibilityHidden(true) }
            .modifier(EditorGlassSurface(distinctSurface: distinctSurface))
            .focused($focused)
            .accessibilityLabel(Text(title)).accessibilityValue(Text(label(selection)))
            .onKeyPress(.downArrow) {
                guard isEnabled else { return .ignored }
                requestMenu(restoreKeyboardFocus: true)
                return .handled
            }
    }

    private func requestMenu(restoreKeyboardFocus: Bool) {
        guard isEnabled, !menuRequested else { return }
        menuRequested = true
        // Return from the button/AX action before AppKit enters its nested menu-tracking loop.
        DispatchQueue.main.async { showMenu(restoreKeyboardFocus: restoreKeyboardFocus) }
    }

    private func showMenu(restoreKeyboardFocus: Bool) {
        defer { menuRequested = false }
        guard isEnabled, anchorView.window != nil else { return }
        defer { focused = restoreKeyboardFocus }
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.minimumWidth = anchorView.bounds.width
        let target = EditorMenuSelectionTarget { index in
            guard choices.indices.contains(index) else { return }
            selection = choices[index]
        }
        for (index, choice) in choices.enumerated() {
            var resource = label(choice)
            resource.locale = locale
            let item = NSMenuItem(title: String(localized: resource),
                                  action: #selector(EditorMenuSelectionTarget.selectItem(_:)), keyEquivalent: "")
            item.target = target
            item.tag = index
            item.state = choice == selection ? .on : .off
            menu.addItem(item)
        }
        // A nil positioning item anchors the menu content frame, including its checkmark column.
        // AppKit still adjusts placement at screen edges and owns dismissal/keyboard tracking.
        let origin = NSPoint(x: anchorView.bounds.minX, y: anchorView.bounds.minY - 8)
        withExtendedLifetime(target) { _ = menu.popUp(positioning: nil, at: origin, in: anchorView) }
    }
}
