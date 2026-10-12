import AppKit
import SwiftUI

struct MainSidebar: View {
    let model: AppModel
    @SwiftUI.Binding var selection: MainDestination
    let manageProfiles: () -> Void
    let showAbout: () -> Void

    private var isShowingSettings: Bool {
        if case .settings = selection { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                Image(.rebindSidebarLogo)
                    .resizable().frame(width: 32, height: 32).accessibilityHidden(true)
                Text("Rebind").font(.system(size: 16, weight: .semibold))
            }.padding(.leading, 4).padding(.top, 56)

            ProfilePicker(model: model, usesGlass: true, manageProfiles: manageProfiles)
                .padding(.top, 24)
                .accessibilityIdentifier("sidebar-profile")

            VStack(spacing: 4) {
                MainSidebarButton(title: LocalizedStringResource("keyboardNavigationTitle", table: "Navigation"), symbol: "keyboard",
                    isSelected: selection == .input(.allKeyboards)) { selection = .input(.allKeyboards) }
                    .accessibilityIdentifier("sidebar-keyboard")
                MainSidebarButton(title: .mouseTitle, symbol: "computermouse",
                    isSelected: selection == .input(.allMice)) { selection = .input(.allMice) }
                    .accessibilityIdentifier("sidebar-mouse")
                MainSidebarButton(title: LocalizedStringResource("trackpadNavigationTitle", table: "Navigation"), symbol: "rectangle.and.hand.point.up.left",
                    isSelected: selection == .input(.builtInTrackpad)) { selection = .input(.builtInTrackpad) }
                    .accessibilityIdentifier("sidebar-trackpad")
                MainSidebarButton(title: LocalizedStringResource("magicMouseNavigationTitle", table: "Navigation"), symbol: "computermouse") { }
                    .disabled(true).help(Text(.magicMouseNotAvailable))
            }.padding(.top, 24)

            Spacer(minLength: 24)
            Color(.navigationSeparator).frame(height: 1)
                .padding(.horizontal, 12).padding(.bottom, 19).accessibilityHidden(true)
            VStack(spacing: 4) {
                MainSidebarButton(title: .settingsTitle, symbol: "gearshape", isSelected: isShowingSettings) {
                    selection = .settings(.general)
                }.accessibilityIdentifier("sidebar-settings")
                MainSidebarButton(title: .aboutTitle, symbol: "info.circle", action: showAbout)
                    .accessibilityIdentifier("sidebar-about")
            }.padding(.bottom, 36)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { MainSidebarSurface().padding(8) }
    }
}
