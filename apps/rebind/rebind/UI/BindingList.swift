import SwiftUI

enum BindingList {
    static func matching(_ bindings: [Binding], search: String) -> [Binding] {
        bindings.filter { $0.scope == .allMice && matches($0, search: search) }
    }

    /// Search over the visible trigger, activation and action text of any rule.
    static func matches(_ binding: Binding, search: String) -> Bool {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty
            || InputLabels.trigger(binding.trigger, modifiers: binding.modifiers).localizedStandardContains(query)
            || AppLocalization.string(detail(for: binding)).localizedStandardContains(query)
            || (binding.activation == .hold && String(binding.holdDurationMilliseconds).contains(query))
            || binding.action.label.localizedStandardContains(query)
            || (binding.note?.localizedStandardContains(query) ?? false)
            || (binding.application?.displayName.localizedStandardContains(query) ?? false)
    }

    static func detail(for binding: Binding) -> LocalizedStringResource {
        switch binding.trigger {
        case .scroll: .mouseDiscreteStep
        case .mouseGesture: .pointerGestureInput
        case .buttonScroll: .buttonWheelInput
        default:
            switch binding.activation {
            case .press: .pressActivation
            case .doublePress: .doublePressActivation
            case .hold: .holdDuration(Int(binding.holdDurationMilliseconds))
            }
        }
    }
}
