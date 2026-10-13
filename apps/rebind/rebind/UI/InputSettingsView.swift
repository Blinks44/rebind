import SwiftUI

/// Recognition settings shared by every rule: gesture distance and excluded apps.
struct InputSettingsView: View {
    let model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.inputTitle).font(Theme.headline).accessibilityAddTraits(.isHeader)
                    Text(.inputDescription).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                information(.pressTiming, status: .perBinding, description: .pressTimingDescription)
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(.mouseGestures).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text(.mouseGesturesDescription).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        SegmentedPicker(selection: SwiftUI.Binding(get: { model.configuration.pointerGestureDistance },
                                                                   set: { model.setPointerGestureDistance($0) }),
                                        title: .gestureDistanceTitle, options: PointerGestureDistance.allCases,
                                        label: { $0.label }, fillsWidth: true)
                            .disabled(model.storageLocked)
                            .accessibilityIdentifier("input-gesture-distance")
                    }
                }
                information(.inputBuiltInTrackpad, status: .experimental, description: .trackpadInputDescription)
                ExcludedApplicationsCard(model: model)
                Text(.inputEditGuidance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 32).padding(.trailing, 40).padding(.bottom, 32)
        }
    }

    private func information(_ title: LocalizedStringResource, status: LocalizedStringResource,
                             description: LocalizedStringResource) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                StatusLabel(title: title, status: status)
                Text(description).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
