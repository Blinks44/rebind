import SwiftUI

/// A setting chosen from a list of values, such as a mouse's DPI steps. The choice is saved once a
/// drag ends, not on every step of it; without a list of values only the current one is shown.
struct SettingSlider: View {
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    let value: Int
    let values: [Int]
    var valueLabel: ((Int) -> LocalizedStringResource)?
    let commit: (Int) -> Void
    @State private var draft: Int?
    @State private var dragging = false

    private var shown: Int { draft ?? value }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Theme.body).foregroundStyle(Theme.textPrimary)
                Text(description).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let valueLabel {
                Text(valueLabel(shown)).font(Theme.callout).monospacedDigit().foregroundStyle(Theme.textSecondary)
            }
            if values.count > 1 {
                Slider(value: index, in: 0...Double(values.count - 1), step: 1) { editing in
                    dragging = editing
                    if !editing { send() }
                }
                .tint(Theme.accent)
                .frame(width: 240)
                .accessibilityLabel(Text(title))
                .accessibilityValue(Text(verbatim: String(shown)))
            }
        }
    }

    private var index: SwiftUI.Binding<Double> {
        SwiftUI.Binding(
            get: { Double(values.firstIndex(of: shown) ?? Self.nearest(to: shown, in: values)) },
            set: { position in
                draft = values[min(max(Int(position.rounded()), 0), values.count - 1)]
                // Arrow keys change the value without a drag.
                if !dragging { send() }
            })
    }

    private func send() {
        guard let sent = draft else { return }
        draft = nil
        if sent != value { commit(sent) }
    }

    static func nearest(to value: Int, in values: [Int]) -> Int {
        values.indices.min { abs(values[$0] - value) < abs(values[$1] - value) } ?? 0
    }
}
