nonisolated struct InputEvent: Sendable {
    enum Phase: Sendable { case down, up, drag, scroll }
    var trigger: InputTrigger
    var modifiers: ModifierSet = []
    var phase: Phase
    var isRepeat = false
    var isSynthetic = false
    // Quartz timestamps are roughly nanoseconds since startup, not wall time.
    var timestamp: UInt64 = 0
}

nonisolated struct MatchDecision: Equatable, Sendable {
    var suppress = false
    var shortcut: KeyboardShortcut?
    var emergencyPause = false
}

nonisolated struct InputMatcher: Sendable {
    private var suppressed: Set<InputTrigger> = []
    private var lastScrollDispatch: UInt64?
    static let scrollIntervalNanoseconds: UInt64 = 100_000_000
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
        if event.phase == .scroll {
            return handleScroll(event, rules: rules, enabled: enabled, canDispatch: canDispatch)
        }
        if case .scroll = event.trigger { return MatchDecision() }
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
        guard event.phase == .down else { return }
        suppressed.insert(event.trigger)
    }

    mutating func resetScrollThrottle() { lastScrollDispatch = nil }

    mutating func resetAfterCaptureLoss() {
        suppressed.removeAll(keepingCapacity: true)
        resetScrollThrottle()
    }

    private mutating func handleScroll(_ event: InputEvent, rules: [MatchKey: KeyboardShortcut],
                                      enabled: Bool, canDispatch: Bool) -> MatchDecision {
        guard case .scroll = event.trigger, enabled, canDispatch,
              let shortcut = rules[MatchKey(trigger: event.trigger, modifiers: event.modifiers)] else {
            return MatchDecision()
        }
        if let previous = lastScrollDispatch {
            // Out-of-order events fail open without poisoning the monotonic limiter.
            guard event.timestamp >= previous else { return MatchDecision() }
            if event.timestamp - previous < Self.scrollIntervalNanoseconds {
                return MatchDecision(suppress: true)
            }
        }
        // One pulse per accepted event, independent of the OS line multiplier.
        // The limiter is shared by wheel bindings so alternating axes cannot storm.
        lastScrollDispatch = event.timestamp
        return MatchDecision(suppress: true, shortcut: shortcut)
    }
}
