import SwiftUI

/// Keeps native pointer/shortcut/AX activation while giving custom controls a reliable Tab stop.
/// Apply to Button only; native Menu labels require their own menu presentation.
/// The editing focus interaction is local to Rebind; it does not alter macOS preferences.
struct KeyboardButtonStyle<Appearance: ButtonStyle>: PrimitiveButtonStyle {
    let appearance: Appearance
    @Environment(\.isEnabled) private var isEnabled

    init(_ appearance: Appearance) { self.appearance = appearance }

    func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        Button(configuration)
            .buttonStyle(appearance)
            .focusable(false, interactions: .activate)
            .focusable(isEnabled, interactions: .edit)
            .onKeyPress(.space) {
                guard isEnabled else { return .ignored }
                configuration.trigger()
                return .handled
            }
    }
}
