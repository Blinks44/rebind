import SwiftUI

/// Settings shared by every mouse: wheel direction and speed, and the mouse gesture distance.
struct AllMiceCard: View {
    let model: AppModel

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(.allMice).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary).accessibilityAddTraits(.isHeader)
                    Text(.allMiceDescription).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                toggle(.reverseMouseWheel, description: .reverseMouseWheelDescription,
                       isOn: SwiftUI.Binding(get: { model.configuration.reversesMouseWheel },
                                             set: { model.setMouseWheel(reverses: $0) }))
                    .accessibilityIdentifier("input-reverse-wheel")
                toggle(.reverseHorizontalScrolling, description: .reverseHorizontalScrollingDescription,
                       isOn: SwiftUI.Binding(get: { model.configuration.reversesHorizontalScrolling },
                                             set: { model.setMouseWheel(reversesHorizontally: $0) }))
                choice(.mouseWheelSpeedTitle, SwiftUI.Binding(get: { model.configuration.mouseWheelSpeed },
                                                              set: { model.setMouseWheel(speed: $0) }), label: \.label)
                    .accessibilityIdentifier("input-wheel-speed")
                choice(.mouseGestureDistance, SwiftUI.Binding(get: { model.configuration.pointerGestureDistance },
                                                              set: { model.setPointerGestureDistance($0) }), label: \.label)
                    .accessibilityIdentifier("input-gesture-distance")
            }
        }
        .disabled(model.storageLocked)
    }

    private func toggle(_ title: LocalizedStringResource, description: LocalizedStringResource,
                        isOn: SwiftUI.Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Theme.body).foregroundStyle(Theme.textPrimary)
                Text(description).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(ThemeSwitchStyle())
    }

    private func choice<Value: Hashable & CaseIterable>(_ title: LocalizedStringResource, _ selection: SwiftUI.Binding<Value>,
                                                        label: @escaping (Value) -> LocalizedStringResource) -> some View
        where Value.AllCases == [Value] {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.caption).foregroundStyle(Theme.textSecondary)
            SegmentedPicker(selection: selection, title: title, options: Value.allCases, label: label, fillsWidth: true)
        }
    }
}
