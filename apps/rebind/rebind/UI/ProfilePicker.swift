import AppKit
import SwiftUI

struct ProfilePicker: View {
    let model: AppModel
    let manageProfiles: () -> Void

    var body: some View {
        AnchoredMenu(select: select, makeMenu: makeMenu) {
            HStack(spacing: 10) {
                Image(systemName: "square.on.square").font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.accent).frame(width: 16).accessibilityHidden(true)
                Text(verbatim: model.configuration.selectedProfile?.title ?? "")
                    .font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.iconSecondary).accessibilityHidden(true)
            }
            .padding(.leading, 14).padding(.trailing, 16)
            .frame(width: 196, height: Theme.controlHeight).contentShape(.capsule)
        }
        .disabled(model.storageLocked)
        .accessibilityLabel(Text(.profileTitle))
        .accessibilityValue(Text(verbatim: model.configuration.selectedProfile?.title ?? ""))
        .accessibilityIdentifier("bindings-profile")
    }

    private func select(_ index: Int) {
        guard !model.storageLocked else { return }
        let profiles = model.configuration.profiles
        if index == profiles.count { manageProfiles() }
        else if profiles.indices.contains(index) {
            // Save transactionally before changing the engine's active profile.
            model.selectProfile(profiles[index].id)
        }
    }

    private func makeMenu(target: MenuSelectionTarget) -> NSMenu {
        let menu = NSMenu()
        for (index, profile) in model.configuration.profiles.enumerated() {
            let item = NSMenuItem(title: profile.title,
                                  action: #selector(MenuSelectionTarget.selectItem(_:)), keyEquivalent: "")
            item.target = target
            item.tag = index
            item.state = profile.id == model.configuration.selectedProfileID ? .on : .off
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let manage = NSMenuItem(title: AppLocalization.string(.manageProfiles),
                                action: #selector(MenuSelectionTarget.selectItem(_:)), keyEquivalent: "")
        manage.target = target
        manage.tag = model.configuration.profiles.count
        menu.addItem(manage)
        return menu
    }
}
