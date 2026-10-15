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
    /// For a hold rule: sent when the trigger is released before the hold time.
    var tapShortcut: KeyboardShortcut?
    /// The rule works only while this app is in front; nil means in every app. A rule for an
    /// app replaces a rule for all apps with the same trigger there.
    var application: ApplicationTarget?
    static let maximumNoteLength = 80

    var matchKey: MatchKey { MatchKey(trigger: trigger, modifiers: modifiers, isMagicTrackpad: scope == .magicTrackpad) }
    var isValid: Bool {
        (scope == trigger.scope || (scope == .magicTrackpad && trigger.isTrackpad)) && trigger.isSupported && action.isSupported
            && modifiers.subtracting(.supported).isEmpty
            && matchKey != MatchKey.emergencyBypass
            && (activation == .press || (!trigger.isScroll && !trigger.holdsButton && !trigger.isTrackpad))
            && (!trigger.isTrackpad || modifiers.isEmpty || ModifierSet.trackpadChoices.contains(modifiers))
            && (100...5000).contains(holdDurationMilliseconds)
            && (note.map(Self.isValidNote) ?? true)
            && (!holdsOutput || (activation != .doublePress && trigger.canHoldOutput && action.canBeHeld))
            && (holdsOutput || !action.requiresHeldOutput)
            && (tapShortcut.map { activation == .hold && $0.isSupported } ?? true)
            && (application?.isSupported ?? true)
    }
}

extension Binding {
    nonisolated private enum CodingKeys: String, CodingKey {
        case id, scope, trigger, modifiers, action, isEnabled, activation, holdDurationMilliseconds, holdsOutput, note, tapShortcut
        case application
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
        tapShortcut = try values.decodeIfPresent(KeyboardShortcut.self, forKey: .tapShortcut)
        application = try values.decodeIfPresent(ApplicationTarget.self, forKey: .application)
    }
}

extension Binding {
    /// The same rule under a fresh identity, for a duplicate or a copy into another profile.
    nonisolated func duplicated() -> Binding {
        var copy = self
        copy.id = UUID()
        return copy
    }

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
