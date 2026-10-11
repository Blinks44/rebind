import SwiftUI

enum MouseBindingList {
    static func matching(_ bindings: [Binding], search: String) -> [Binding] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return bindings.filter { binding in
            guard binding.scope == .allMice else { return false }
            return query.isEmpty
                || InputLabels.trigger(binding.trigger, modifiers: binding.modifiers).localizedStandardContains(query)
                || AppLocalization.string(detail(for: binding)).localizedStandardContains(query)
                || (binding.activation == .hold && String(binding.holdDurationMilliseconds).contains(query))
                || binding.action.label.localizedStandardContains(query)
        }
    }

    static func detail(for binding: Binding) -> LocalizedStringResource {
        switch binding.trigger {
        case .scroll: .mouseDiscreteStep
        case .mouseGesture: .pointerGestureInput
        default:
            switch binding.activation {
            case .press: .pressActivation
            case .doublePress: .doublePressActivation
            case .hold: .holdDuration(Int(binding.holdDurationMilliseconds))
            }
        }
    }
}
