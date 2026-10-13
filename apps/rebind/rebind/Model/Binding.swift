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
    /// Keeps a shortcut pressed, or repeats a step action, for as long as the trigger is held.
    var holdsOutput = false
    /// The user's own description of the rule; nil when there is none.
    var note: String?
    static let maximumNoteLength = 80

    var matchKey: MatchKey { MatchKey(trigger: trigger, modifiers: modifiers, isMagicTrackpad: scope == .magicTrackpad) }
    var isValid: Bool {
        (scope == trigger.scope || (scope == .magicTrackpad && trigger.isTrackpad)) && trigger.isSupported && action.isSupported
            && modifiers.subtracting(.supported).isEmpty
            && matchKey != MatchKey.emergencyBypass
            && (activation == .press || (!trigger.isScroll && !trigger.holdsButton && !trigger.isTrackpad))
            && (!trigger.isTrackpad || modifiers.isEmpty)
            && (100...5000).contains(holdDurationMilliseconds)
            && (note.map(Self.isValidNote) ?? true)
            && (!holdsOutput || (activation == .press && trigger.canHoldOutput && action.canBeHeld))
    }
}

extension Binding {
    nonisolated private enum CodingKeys: String, CodingKey {
        case id, scope, trigger, modifiers, action, isEnabled, activation, holdDurationMilliseconds, holdsOutput, note
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
        holdsOutput = values.contains(.holdsOutput) ? try values.decode(Bool.self, forKey: .holdsOutput) : false
        note = try values.decodeIfPresent(String.self, forKey: .note)
    }
}

extension Binding {
    nonisolated static func isValidNote(_ note: String) -> Bool {
        !note.isEmpty && note.count <= maximumNoteLength
            && note == note.trimmingCharacters(in: .whitespacesAndNewlines)
            && !note.unicodeScalars.contains { $0.properties.generalCategory == .control }
    }
}

nonisolated struct MatchKey: Hashable, Sendable {
    var trigger: InputTrigger
    var modifiers: ModifierSet
    /// Separates Magic Trackpad rules from built-in trackpad rules that use the same gesture.
    var isMagicTrackpad = false
    var pressSource: MatchKey { Self(trigger: trigger.pressSource, modifiers: modifiers, isMagicTrackpad: isMagicTrackpad) }
    static let emergencyBypass = Self(trigger: .key(53), modifiers: [.command, .control, .option, .shift])
}
