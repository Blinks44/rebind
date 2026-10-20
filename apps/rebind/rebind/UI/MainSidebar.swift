import AppKit
import SwiftUI

struct MainSidebar: View {
    @SwiftUI.Binding var selection: MainDestination
    let showAbout: () -> Void
    @FocusState private var focusedRow: Int?

    private var isShowingSettings: Bool {
        if case .settings = selection { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // The running app's own icon keeps the sidebar mark identical to the Dock.
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                Text(verbatim: "Rebind").font(Theme.title).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.leading, 8).padding(.top, 50).accessibilityElement(children: .combine)
            VStack(spacing: 4) {
                MainSidebarButton(title: LocalizedStringResource("keyboardNavigationTitle", table: "Navigation"), symbol: "keyboard",
                    isSelected: selection == .input(.allKeyboards), keyboardFocus: focusedRow == 0) { selection = .input(.allKeyboards) }
                    .focused($focusedRow, equals: 0)
                    .accessibilityIdentifier("sidebar-keyboard")
                    .keyboardShortcut("1", modifiers: .command)
                MainSidebarButton(title: .mouseTitle, symbol: "computermouse",
                    isSelected: selection == .input(.allMice), keyboardFocus: focusedRow == 1) { selection = .input(.allMice) }
                    .focused($focusedRow, equals: 1)
                    .accessibilityIdentifier("sidebar-mouse")
                    .keyboardShortcut("2", modifiers: .command)
                MainSidebarButton(title: LocalizedStringResource("trackpadNavigationTitle", table: "Navigation"), symbol: "rectangle.and.hand.point.up.left",
                    isSelected: selection == .input(.builtInTrackpad), keyboardFocus: focusedRow == 2) { selection = .input(.builtInTrackpad) }
                    .focused($focusedRow, equals: 2)
                    .accessibilityIdentifier("sidebar-trackpad")
                    .keyboardShortcut("3", modifiers: .command)
                MainSidebarButton(title: DeviceScope.magicTrackpad.title, symbol: DeviceScope.magicTrackpad.symbol,
                    isSelected: selection == .input(.magicTrackpad), keyboardFocus: focusedRow == 3) { selection = .input(.magicTrackpad) }
                    .focused($focusedRow, equals: 3)
                    .accessibilityIdentifier("sidebar-magic-trackpad")
                    .keyboardShortcut("4", modifiers: .command)
                MainSidebarButton(title: DeviceScope.magicMouse.title, symbol: DeviceScope.magicMouse.symbol,
                    isSelected: selection == .input(.magicMouse), keyboardFocus: focusedRow == 4) { selection = .input(.magicMouse) }
                    .focused($focusedRow, equals: 4)
                    .accessibilityIdentifier("sidebar-magic-mouse")
                    .keyboardShortcut("5", modifiers: .command)
            }.padding(.top, 18)

            Spacer(minLength: 16)
            Theme.separator.frame(height: 1).padding(.horizontal, 8).padding(.bottom, 15).accessibilityHidden(true)
            VStack(spacing: 4) {
                MainSidebarButton(title: .settingsTitle, symbol: "gearshape", isSelected: isShowingSettings, keyboardFocus: focusedRow == 5) {
                    selection = .settings(.general)
                }.focused($focusedRow, equals: 5).accessibilityIdentifier("sidebar-settings")
                MainSidebarButton(title: .aboutTitle, symbol: "info.circle", keyboardFocus: focusedRow == 6, action: showAbout)
                    .focused($focusedRow, equals: 6)
                    .accessibilityIdentifier("sidebar-about")
            }.padding(.bottom, 16)
        }
        .onKeyPress(.upArrow) { moveFocus(by: -1) }
        .onKeyPress(.downArrow) { moveFocus(by: 1) }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { MainSidebarSurface() }
        .padding([.leading, .vertical], 8)
    }
    private func moveFocus(by offset: Int) -> KeyPress.Result {
        guard let focusedRow else { return .ignored }
        self.focusedRow = min(max(focusedRow + offset, 0), 6)
        return .handled
    }
}
