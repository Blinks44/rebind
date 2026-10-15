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
                choice(.mouseWheelSpeedTitle, SwiftUI.Binding(get: { model.configuration.mouseWheelSpeed },
                                                              set: { model.setMouseWheel(speed: $0) }), label: \.label)
                    .accessibilityIdentifier("input-wheel-speed")
                Theme.separator.frame(height: 1).padding(.vertical, 4)
                toggle(.smoothScrollingTitle, description: .smoothScrollingDescription,
                       isOn: SwiftUI.Binding(get: { model.configuration.smoothScrolling },
                                             set: { model.setSmoothScrolling(enabled: $0) }))
                    .accessibilityIdentifier("input-smooth-scrolling")
                if model.configuration.smoothScrolling {
                    choice(.smoothScrollingGlide, SwiftUI.Binding(get: { model.configuration.smoothScrollingGlide },
                                                                  set: { model.setSmoothScrolling(glide: $0) }), label: \.label)
                    choice(.smoothScrollingScope, SwiftUI.Binding(get: { model.configuration.smoothScrollingScope },
                                                                  set: { model.setSmoothScrolling(scope: $0) }), label: \.label)
                }
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

extension SmoothScrollingGlide {
    var label: LocalizedStringResource {
        switch self {
        case .short: .glideShort
        case .standard: .glideStandard
        case .long: .glideLong
        }
    }
}

extension SmoothScrollingScope {
    var label: LocalizedStringResource {
        switch self {
        case .steppedWheels: .smoothScrollingSteppedWheels
        case .allWheels: .smoothScrollingAllWheels
        }
    }
}
