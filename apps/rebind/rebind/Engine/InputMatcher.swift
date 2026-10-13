nonisolated struct InputEvent: Sendable {
    enum Phase: Sendable { case down, up, drag, scroll, modifiersChanged }
    var trigger: InputTrigger
    var modifiers: ModifierSet = []
    var phase: Phase
    var isRepeat = false
    var isSynthetic = false
    // Quartz event time for double-press and wheel timing.
    var timestamp: UInt64 = 0
    // Hold deadlines use the worker's uptime clock for both receipt and polling,
    // without assuming an external event timestamp has the same clock origin.
    // Pure tests can omit this and supply deterministic timestamps above.
    var receivedAt: UInt64?
    var motion: PointerMotion?
}

nonisolated struct MatchDecision: Equatable, Sendable {
    var suppress = false
    var action: RebindAction?
    var shortcut: KeyboardShortcut? { action?.shortcut }
    var emergencyPause = false
}

nonisolated struct InputMatcher: Sendable {
    private var suppressed: Set<InputTrigger> = []
    private var lastScrollDispatch: UInt64?
    private var doublePress: DoublePress?
    private var hold: Hold?
    private var pointerGesture: PointerGesture?
    var doublePressIntervalNanoseconds: UInt64 = 500_000_000
    static let scrollIntervalNanoseconds: UInt64 = 100_000_000
    var hasSuppressedInput: Bool { !suppressed.isEmpty }
    var holdKey: MatchKey? { hold?.key }
    var pointerGestureSource: InputTrigger? {
        pointerGesture?.capturesMovement == true ? pointerGesture?.key.trigger : nil
    }
    static let pointerThreshold: Int64 = 50
    static let pointerTimeoutNanoseconds: UInt64 = 5_000_000_000

    init() { suppressed.reserveCapacity(128) }

    private struct DoublePress: Sendable {
        var key: MatchKey
        var startedAt: UInt64
        var released = false
    }

    private struct Hold: Sendable {
        var key: MatchKey
        var startedAt: UInt64
    }

    private struct PointerGesture: Sendable {
        var key: MatchKey
        var startedAt: UInt64
        var lastReceivedAt: UInt64
        var x: Int64 = 0
        var y: Int64 = 0
        // Retain source ownership after firing/cancellation until its release.
        var recognizing = true
        var capturesMovement = true
    }

    // A delayed worker must not fire a stale action after a long scheduling gap.
    static let holdLatenessNanoseconds: UInt64 = 100_000_000

    static func compile(_ bindings: [Binding]) -> [MatchKey: CompiledBinding] {
        var rules: [MatchKey: CompiledBinding] = [:]
        var conflicts: Set<MatchKey> = []
        var gestureSources: Set<MatchKey> = []
        var ordinarySources: Set<MatchKey> = []
        for binding in bindings where binding.isEnabled && binding.isValid {
            // A plain press rule may share its button with gestures: it runs on a
            // click without movement. Hold and double press would be ambiguous.
            if binding.trigger.isPointerGesture { gestureSources.insert(binding.matchKey.pressSource) }
            else if binding.activation != .press { ordinarySources.insert(binding.matchKey.pressSource) }
            if rules[binding.matchKey] != nil { conflicts.insert(binding.matchKey) }
            rules[binding.matchKey] = CompiledBinding(action: binding.action, activation: binding.activation,
                                                      holdDurationNanoseconds: UInt64(binding.holdDurationMilliseconds) * 1_000_000)
        }
        let ambiguousSources = gestureSources.intersection(ordinarySources)
        for key in rules.keys where ambiguousSources.contains(key.pressSource) { conflicts.insert(key) }
        for key in conflicts { rules.removeValue(forKey: key) }
        return rules
    }

    mutating func handle(_ event: InputEvent, rules: [MatchKey: CompiledBinding],
                         enabled: Bool, canDispatch: Bool = true) -> MatchDecision {
        guard !event.isSynthetic else { return MatchDecision() }
        // Cancel recognition without losing ownership of already swallowed presses.
        if !enabled || !canDispatch { doublePress = nil; cancelHold() }
        if event.phase == .modifiersChanged {
            if doublePress?.key.modifiers != event.modifiers { doublePress = nil }
            if hold?.key.modifiers != event.modifiers { hold = nil }
            if pointerGesture?.key.modifiers != event.modifiers { cancelPointerGesture() }
            return MatchDecision()
        }
        if event.phase == .scroll {
            doublePress = nil
            cancelHold()
            return handleScroll(event, rules: rules, enabled: enabled, canDispatch: canDispatch)
        }
        // Configured gesture tokens are never physical events from the adapter.
        if event.trigger.isPointerGesture { return MatchDecision() }
        if case .scroll = event.trigger { return MatchDecision() }
        if event.phase == .up {
            var click: RebindAction?
            if let candidate = pointerGesture, candidate.key.trigger == event.trigger {
                // Released before any stroke was recognized or cancelled: this was a
                // click. Run the button's press rule, or give the click back to the system.
                if candidate.recognizing, enabled, canDispatch, candidate.key.modifiers == event.modifiers,
                   suppressed.contains(event.trigger) {
                    click = rules[candidate.key]?.action ?? Self.passthroughClick(for: event.trigger)
                }
                pointerGesture = nil
            }
            if hold?.key.trigger == event.trigger { hold = nil }
            let owned = suppressed.remove(event.trigger) != nil
            if click != nil { doublePress = nil; return MatchDecision(suppress: owned, action: click) }
            if let candidate = doublePress, candidate.key.trigger == event.trigger {
                if owned, candidate.key.modifiers == event.modifiers,
                   event.timestamp >= candidate.startedAt,
                   event.timestamp - candidate.startedAt <= doublePressIntervalNanoseconds {
                    doublePress?.released = true
                } else { doublePress = nil }
            }
            return MatchDecision(suppress: owned)
        }
        if suppressed.contains(event.trigger) {
            // Repeat/duplicate down or drag is not a second intentional press.
            doublePress = nil
            if pointerGesture?.key.trigger == event.trigger {
                let suppress = event.phase != .drag || pointerGesture?.capturesMovement == true
                let action = handlePointerGesture(event, rules: rules)
                return MatchDecision(suppress: suppress, action: action)
            }
            if event.phase == .down || event.phase == .drag { cancelPointerGesture() }
            if let candidate = hold, candidate.key.trigger == event.trigger {
                // Quartz delivers mouse motion with a held auxiliary button as
                // drag events, including small involuntary movement. A button
                // hold depends on duration, not keeping the pointer stationary.
                let continuesHold: Bool
                if case .mouseButton = event.trigger, event.phase == .drag {
                    continuesHold = true
                } else { continuesHold = event.phase == .down && event.isRepeat }
                if !continuesHold || candidate.key.modifiers != event.modifiers
                    || (event.receivedAt ?? event.timestamp) < candidate.startedAt { hold = nil }
            } else if event.phase == .down || event.phase == .drag { hold = nil }
            return MatchDecision(suppress: true)
        }
        if event.phase == .drag { cancelHold() }
        guard event.phase == .down else { return MatchDecision() }
        cancelHold()
        let key = MatchKey(trigger: event.trigger, modifiers: event.modifiers)
        if key == .emergencyBypass {
            doublePress = nil
            suppressed.insert(event.trigger)
            return MatchDecision(suppress: true, emergencyPause: true)
        }
        guard enabled, canDispatch, !event.isRepeat else {
            doublePress = nil
            return MatchDecision()
        }
        // A button with gesture rules waits for movement; its click is decided on release.
        if case .mouseButton(let button) = event.trigger, pointerGesture == nil,
           PointerDirection.allCases.contains(where: {
               rules[MatchKey(trigger: .mouseGesture(button: button, direction: $0), modifiers: event.modifiers)] != nil
           }) {
            doublePress = nil
            let now = event.receivedAt ?? event.timestamp
            pointerGesture = PointerGesture(key: key, startedAt: now, lastReceivedAt: now)
            suppressed.insert(event.trigger)
            return MatchDecision(suppress: true)
        }
        guard let rule = rules[key] else {
            doublePress = nil
            return MatchDecision()
        }
        if rule.activation == .hold {
            doublePress = nil
            hold = Hold(key: key, startedAt: event.receivedAt ?? event.timestamp)
            suppressed.insert(event.trigger)
            return MatchDecision(suppress: true)
        }
        if rule.activation == .doublePress {
            if let candidate = doublePress {
                guard event.timestamp >= candidate.startedAt else {
                    doublePress = nil
                    return MatchDecision()
                }
                if candidate.key == key, candidate.released,
                   event.timestamp - candidate.startedAt <= doublePressIntervalNanoseconds {
                    doublePress = nil
                    suppressed.insert(event.trigger)
                    return MatchDecision(suppress: true, action: rule.action)
                }
            }
            // One candidate, so another physical press interrupts the sequence.
            doublePress = DoublePress(key: key, startedAt: event.timestamp)
            suppressed.insert(event.trigger)
            return MatchDecision(suppress: true)
        }
        doublePress = nil
        suppressed.insert(event.trigger)
        return MatchDecision(suppress: true, action: rule.action)
    }

    /// The ordinary click of a gesture button that has no press rule. Only the
    /// middle, fourth and fifth buttons can be given back; higher ones stay silent.
    private static func passthroughClick(for trigger: InputTrigger) -> RebindAction? {
        guard case .mouseButton(let button) = trigger else { return nil }
        switch button {
        case 2: return .mouse(.middleClick)
        case 3: return .mouse(.backClick)
        case 4: return .mouse(.forwardClick)
        default: return nil
        }
    }

    mutating func consume(_ event: InputEvent) {
        doublePress = nil
        cancelHold()
        guard event.phase == .down else { return }
        suppressed.insert(event.trigger)
    }

    mutating func resetScrollThrottle() { lastScrollDispatch = nil }

    // Unsupported wheel input cancels both duration and motion recognition.
    mutating func cancelHold() { hold = nil; cancelPointerGesture() }

    private mutating func cancelPointerGesture() {
        pointerGesture?.recognizing = false
        pointerGesture?.capturesMovement = false
    }

    mutating func expirePointerGesture(at now: UInt64) {
        guard let candidate = pointerGesture else { return }
        if now < candidate.lastReceivedAt || now - candidate.startedAt > Self.pointerTimeoutNanoseconds {
            cancelPointerGesture()
        }
    }

    mutating func cancelPendingActivation() {
        doublePress = nil
        cancelHold()
        resetScrollThrottle()
    }

    mutating func resetAfterCaptureLoss() {
        pointerGesture = nil
        suppressed.removeAll(keepingCapacity: true)
        cancelPendingActivation()
    }

    private mutating func handlePointerGesture(_ event: InputEvent,
                                               rules: [MatchKey: CompiledBinding]) -> RebindAction? {
        guard var candidate = pointerGesture, candidate.recognizing else { return nil }
        let now = event.receivedAt ?? event.timestamp
        guard event.phase == .drag, event.modifiers == candidate.key.modifiers,
              now >= candidate.lastReceivedAt, now - candidate.startedAt <= Self.pointerTimeoutNanoseconds,
              let motion = event.motion,
              motion.deltaX.magnitude <= 4096, motion.deltaY.magnitude <= 4096 else {
            cancelPointerGesture()
            return nil
        }
        candidate.lastReceivedAt = now
        candidate.x += motion.deltaX
        candidate.y += motion.deltaY
        let x = candidate.x.magnitude
        let y = candidate.y.magnitude
        guard x <= 4096, y <= 4096 else { cancelPointerGesture(); return nil }
        guard max(x, y) >= UInt64(Self.pointerThreshold) else { pointerGesture = candidate; return nil }
        // Commit the first substantial stroke. Ambiguous diagonals and an
        // unconfigured direction end recognition, without trying another outcome.
        let direction: PointerDirection
        if x >= 2 * y { direction = candidate.x < 0 ? .left : .right }
        else if y >= 2 * x { direction = candidate.y < 0 ? .up : .down }
        else { cancelPointerGesture(); return nil }
        guard case .mouseButton(let button) = candidate.key.trigger,
              let rule = rules[MatchKey(trigger: .mouseGesture(button: button, direction: direction),
                                       modifiers: candidate.key.modifiers)] else {
            cancelPointerGesture()
            return nil
        }
        candidate.recognizing = false
        pointerGesture = candidate
        return rule.action
    }

    mutating func pollHold(at now: UInt64, rules: [MatchKey: CompiledBinding],
                           enabled: Bool, canDispatch: Bool = true) -> RebindAction? {
        guard let candidate = hold else { return nil }
        guard enabled, canDispatch, suppressed.contains(candidate.key.trigger),
              let rule = rules[candidate.key], rule.activation == .hold,
              now >= candidate.startedAt else { hold = nil; return nil }
        let elapsed = now - candidate.startedAt
        guard elapsed >= rule.holdDurationNanoseconds else { return nil }
        hold = nil
        guard elapsed - rule.holdDurationNanoseconds <= Self.holdLatenessNanoseconds else { return nil }
        return rule.action
    }

    private mutating func handleScroll(_ event: InputEvent, rules: [MatchKey: CompiledBinding],
                                      enabled: Bool, canDispatch: Bool) -> MatchDecision {
        guard case .scroll = event.trigger, enabled, canDispatch,
              let rule = rules[MatchKey(trigger: event.trigger, modifiers: event.modifiers)], rule.activation == .press else {
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
        return MatchDecision(suppress: true, action: rule.action)
    }
}
