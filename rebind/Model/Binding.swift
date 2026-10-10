import Foundation

nonisolated struct Binding: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var scope: DeviceScope
    var trigger: InputTrigger
    var modifiers: ModifierSet
    var action: RebindAction
    var isEnabled = true
    var activation: PressActivation = .press
    var holdDurationMilliseconds: UInt32 = 500

    var matchKey: MatchKey { MatchKey(trigger: trigger, modifiers: modifiers) }
    var isValid: Bool {
        scope == trigger.scope && trigger.isSupported && action.isSupported
            && modifiers.subtracting(.supported).isEmpty
            && matchKey != MatchKey.emergencyBypass
            && (activation == .press || (!trigger.isScroll && !trigger.isPointerGesture && !trigger.isTrackpad))
            && (!trigger.isTrackpad || (modifiers.isEmpty && action.shortcut != nil))
            && (100...5000).contains(holdDurationMilliseconds)
    }
}

extension Binding {
    nonisolated private enum CodingKeys: String, CodingKey {
        case id, scope, trigger, modifiers, action, isEnabled, activation, holdDurationMilliseconds
    }

    nonisolated init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        scope = try values.decode(DeviceScope.self, forKey: .scope)
        trigger = try values.decode(InputTrigger.self, forKey: .trigger)
        modifiers = try values.decode(ModifierSet.self, forKey: .modifiers)
        action = try values.decode(RebindAction.self, forKey: .action)
        isEnabled = try values.decode(Bool.self, forKey: .isEnabled)
        // Older schemas predate activation. Unknown/new enum values still fail.
        activation = values.contains(.activation) ? try values.decode(PressActivation.self, forKey: .activation) : .press
        holdDurationMilliseconds = values.contains(.holdDurationMilliseconds)
            ? try values.decode(UInt32.self, forKey: .holdDurationMilliseconds) : 500
    }
}

nonisolated struct MatchKey: Hashable, Sendable {
    var trigger: InputTrigger
    var modifiers: ModifierSet
    var pressSource: MatchKey { Self(trigger: trigger.pressSource, modifiers: modifiers) }
    static let emergencyBypass = Self(trigger: .key(53), modifiers: [.command, .control, .option, .shift])
}
