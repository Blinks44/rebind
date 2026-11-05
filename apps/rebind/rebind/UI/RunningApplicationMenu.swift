import AppKit
import SwiftUI

struct RunningApplicationMenu: View {
    let excludedIdentifiers: Set<String>
    let selectApplication: (ApplicationTarget) -> Void
    let browse: () -> Void
    @State private var choices: [RunningApplicationChoice] = []

    var body: some View {
        AnchoredMenu(select: select, makeMenu: makeMenu) {
            HStack(spacing: 6) {
                Text(.addExcludedApp)
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold)).accessibilityHidden(true)
            }
            .font(Theme.calloutStrong).foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14).frame(minHeight: Theme.smallControlHeight)
        }
        .accessibilityLabel(Text(.addExcludedApp))
    }

    private func select(_ index: Int) {
        if index == -1 { browse() } else if choices.indices.contains(index) { selectApplication(choices[index].target) }
    }

    func makeMenu(target: MenuSelectionTarget) -> NSMenu {
        choices = RunningApplicationChoice.current(excluding: excludedIdentifiers)
        let menu = NSMenu()
        let heading = NSMenuItem(title: AppLocalization.string(.runningApplicationsTitle), action: nil, keyEquivalent: "")
        heading.isEnabled = false
        menu.addItem(heading)
        for (index, choice) in choices.enumerated() {
            let item = NSMenuItem(title: choice.name, action: #selector(MenuSelectionTarget.selectItem(_:)), keyEquivalent: "")
            item.target = target
            item.tag = index
            let icon = NSWorkspace.shared.icon(forFile: choice.target.url.path)
            icon.size = NSSize(width: 16, height: 16)
            item.image = icon
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let file = NSMenuItem(
            title: AppLocalization.string(.chooseApplicationFromDisk), action: #selector(MenuSelectionTarget.selectItem(_:)),
            keyEquivalent: "")
        file.target = target
        file.tag = -1
        menu.addItem(file)
        return menu
    }
}
