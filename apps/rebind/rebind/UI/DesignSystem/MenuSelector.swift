import AppKit
import SwiftUI

/// A capsule selector with a native menu anchored to its leading edge rather than its selected label.
struct MenuSelector<Selection: Hashable>: View {
    @SwiftUI.Binding var selection: Selection
    let title: LocalizedStringResource
    let choices: [Selection]
    let label: (Selection) -> LocalizedStringResource
    var compact = false
    var singleLine = false
    /// Choices that start a new group, shown after a separator.
    var startsGroup: (Selection) -> Bool = { _ in false }
    var menuActionTitle: LocalizedStringResource?
    var menuAction: (() -> Void)?
    @Environment(\.locale) private var locale

    var body: some View {
        AnchoredMenu(select: select, makeMenu: makeMenu) {
            SelectorLabel(title: label(selection),
                          height: compact ? Theme.compactControlHeight : Theme.controlHeight,
                          horizontalInset: compact ? 12 : 16, singleLine: singleLine)
        }
        .accessibilityLabel(Text(title)).accessibilityValue(Text(label(selection)))
    }

    private func select(_ index: Int) {
        if index == choices.count, let menuAction {
            menuAction()
            return
        }
        guard choices.indices.contains(index) else { return }
        selection = choices[index]
    }

    private func makeMenu(target: MenuSelectionTarget) -> NSMenu {
        let menu = NSMenu()
        for (index, choice) in choices.enumerated() {
            if index > 0, startsGroup(choice) { menu.addItem(.separator()) }
            var resource = label(choice)
            resource.locale = locale
            let item = NSMenuItem(title: String(localized: resource),
                                  action: #selector(MenuSelectionTarget.selectItem(_:)), keyEquivalent: "")
            item.target = target
            item.tag = index
            item.state = choice == selection ? .on : .off
            menu.addItem(item)
        }
        if var title = menuActionTitle, menuAction != nil {
            title.locale = locale
            menu.addItem(.separator())
            let item = NSMenuItem(title: String(localized: title),
                                  action: #selector(MenuSelectionTarget.selectItem(_:)), keyEquivalent: "")
            item.target = target
            item.tag = choices.count
            menu.addItem(item)
        }
        return menu
    }
}
