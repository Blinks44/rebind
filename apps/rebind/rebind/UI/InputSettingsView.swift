import SwiftUI

/// Recognition settings shared by every rule: gesture distance, the mouse wheel and excluded apps.
struct InputSettingsView: View {
    let model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.settingsInput).font(Theme.headline).accessibilityAddTraits(.isHeader)
                    Text(.inputDescription).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        title(.mouseGestures, description: .mouseGesturesDescription)
                        SegmentedPicker(selection: SwiftUI.Binding(get: { model.configuration.pointerGestureDistance },
                                                                   set: { model.setPointerGestureDistance($0) }),
                                        title: .gestureDistanceTitle, options: PointerGestureDistance.allCases,
                                        label: { $0.label }, fillsWidth: true)
                            .accessibilityIdentifier("input-gesture-distance")
                    }
                }
                .disabled(model.storageLocked)
                mouseWheel
                ExcludedApplicationsCard(model: model)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .detailMargins().padding(.bottom, 32)
        }
    }

    private var mouseWheel: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                title(.mouseWheelTitle, description: .mouseWheelDescription)
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
                Text(.smoothScrollingInDevices).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .disabled(model.storageLocked)
    }

    private func title(_ title: LocalizedStringResource, description: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary).accessibilityAddTraits(.isHeader)
            Text(description).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
