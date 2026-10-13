import SwiftUI

/// Both the application menu and sidebar open the same single About window.
struct AboutCommand: View {
    let language: AppLanguage
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(AppLocalization.string(.aboutRebind, language: language)) {
            openWindow(id: "about")
        }
    }
}
