nonisolated struct InputEvent: Sendable {
    enum Phase: Sendable { case down, up, drag }
    var trigger: InputTrigger
    var modifiers: ModifierSet = []
    var phase: Phase
    var isRepeat = false
    var isSynthetic = false
}

nonisolated struct MatchDecision: Equatable, Sendable {
    var suppress = false
    var shortcut: KeyboardShortcut?
    var emergencyPause = false
}

nonisolated struct InputMatcher: Sendable {
    private var suppressed: Set<InputTrigger> = []
    var hasSuppressedInput: Bool { !suppressed.isEmpty }

    init() { suppressed.reserveCapacity(128) }

    static func compile(_ bindings: [Binding]) -> [MatchKey: KeyboardShortcut] {
        var rules: [MatchKey: KeyboardShortcut] = [:]
        var conflicts: Set<MatchKey> = []
        for binding in bindings where binding.isEnabled && binding.isValid {
            if rules[binding.matchKey] != nil { conflicts.insert(binding.matchKey) }
            rules[binding.matchKey] = binding.action.shortcut
        }
        for key in conflicts { rules.removeValue(forKey: key) }
        return rules
    }

    mutating func handle(_ event: InputEvent, rules: [MatchKey: KeyboardShortcut],
                         enabled: Bool, canDispatch: Bool = true) -> MatchDecision {
        guard !event.isSynthetic else { return MatchDecision() }
        if event.phase == .up {
            return MatchDecision(suppress: suppressed.remove(event.trigger) != nil)
        }
        if suppressed.contains(event.trigger) { return MatchDecision(suppress: true) }
        guard event.phase == .down else { return MatchDecision() }
        let key = MatchKey(trigger: event.trigger, modifiers: event.modifiers)
        if key == .emergencyBypass {
            suppressed.insert(event.trigger)
            return MatchDecision(suppress: true, emergencyPause: true)
        }
        guard enabled, canDispatch, !event.isRepeat, let shortcut = rules[key] else {
            return MatchDecision()
        }
        suppressed.insert(event.trigger)
        return MatchDecision(suppress: true, shortcut: shortcut)
    }

    mutating func consume(_ event: InputEvent) {
        suppressed.insert(event.trigger)
    }

    mutating func resetAfterCaptureLoss() { suppressed.removeAll(keepingCapacity: true) }
}
