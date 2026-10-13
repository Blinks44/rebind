import AppKit
import SwiftUI

struct MainSidebar: View {
    @SwiftUI.Binding var selection: MainDestination
    let showAbout: () -> Void

    private var isShowingSettings: Bool {
        if case .settings = selection { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // The running app's own icon keeps the sidebar mark identical to the Dock.
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 32, height: 32)
                    .accessibilityHidden(true)
                Text(verbatim: "Rebind").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.leading, 8).padding(.top, 56).accessibilityElement(children: .combine)
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
                MainSidebarButton(title: DeviceScope.magicTrackpad.title, symbol: DeviceScope.magicTrackpad.symbol,
                    isSelected: selection == .input(.magicTrackpad)) { selection = .input(.magicTrackpad) }
                    .accessibilityIdentifier("sidebar-magic-trackpad")
                MainSidebarButton(title: LocalizedStringResource("magicMouseNavigationTitle", table: "Navigation"), symbol: "magicmouse") { }
                    .disabled(true).help(Text(.magicMouseNotAvailable))
            }.padding(.top, 24)

            Spacer(minLength: 16)
            Theme.separator.frame(height: 1).padding(.horizontal, 8).padding(.bottom, 15).accessibilityHidden(true)
            VStack(spacing: 4) {
                MainSidebarButton(title: .settingsTitle, symbol: "gearshape", isSelected: isShowingSettings) {
                    selection = .settings(.general)
                }.accessibilityIdentifier("sidebar-settings")
                MainSidebarButton(title: .aboutTitle, symbol: "info.circle", action: showAbout)
                    .accessibilityIdentifier("sidebar-about")
            }.padding(.bottom, 16)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { MainSidebarSurface() }
        .padding([.leading, .vertical], 8)
    }
}
