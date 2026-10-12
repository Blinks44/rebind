import SwiftUI

/// Quiet navigation chrome; selection, hover and focus are supplied by the shared row.
struct MainSidebarButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.8 : 1)
    }
}
