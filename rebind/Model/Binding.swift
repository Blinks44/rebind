import Foundation

nonisolated struct Binding: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var scope: DeviceScope
    var trigger: InputTrigger
    var modifiers: ModifierSet
    var action: RebindAction
    var isEnabled = true

    var matchKey: MatchKey { MatchKey(trigger: trigger, modifiers: modifiers) }
    var isValid: Bool {
        scope == trigger.scope && trigger.isSupported && action.shortcut.isSupported
            && modifiers.subtracting(.supported).isEmpty
            && matchKey != MatchKey.emergencyBypass
    }
}

nonisolated struct MatchKey: Hashable, Sendable {
    var trigger: InputTrigger
    var modifiers: ModifierSet
    static let emergencyBypass = Self(trigger: .key(53), modifiers: [.command, .control, .option, .shift])
}
