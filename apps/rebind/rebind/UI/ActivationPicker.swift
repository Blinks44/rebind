import SwiftUI

/// Press / Double Press / Hold for a key or mouse-button trigger.
struct ActivationPicker: View {
    @SwiftUI.Binding var selection: PressActivation

    var body: some View {
        SegmentedPicker(selection: $selection, title: .activationTitle, options: PressActivation.allCases,
                        label: { $0.title }, fillsWidth: true)
    }
}

extension PressActivation {
    var title: LocalizedStringResource {
        switch self {
        case .press: .pressActivation
        case .doublePress: .doublePressActivation
        case .hold: .holdActivation
        }
    }
}
