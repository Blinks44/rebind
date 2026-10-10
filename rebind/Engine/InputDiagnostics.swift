// InlineArray is a standard-library fixed-size container. The callback writes a
// single slot; only UI snapshots allocate an Array. No shared COW event storage.
nonisolated struct InputDiagnostics: Sendable {
    static let capacity = 128
    static let eventsPerWindow = 20
    static let sessionDuration: UInt64 = 60_000_000_000
    private var storage = InlineArray<128, InputDiagnostic?>(repeating: nil)
    private var next = 0
    private var count = 0
    private var sequence: UInt64 = 0
    private var startedAt: UInt64?
    private var lastReceivedAt: UInt64 = 0
    private var windowStartedAt: UInt64 = 0
    private var acceptedInWindow = 0
    private(set) var revision: UInt64 = 0
    private var omitted: UInt64 = 0
    var isRunning: Bool { startedAt != nil }

    mutating func start(at now: UInt64) {
        stop(clear: true)
        startedAt = now
        lastReceivedAt = now
        windowStartedAt = now
        acceptedInWindow = 0
        revision &+= 1
    }

    mutating func stop(clear: Bool = false) {
        if startedAt != nil { startedAt = nil; revision &+= 1 }
        if clear { self.clear() }
    }

    mutating func clear() {
        guard count > 0 || omitted > 0 else { return }
        for index in 0..<Self.capacity { storage[index] = nil }
        next = 0
        count = 0
        omitted = 0
        revision &+= 1
    }

    mutating func expire(at now: UInt64) {
        guard let startedAt else { return }
        if now < lastReceivedAt { stop(clear: true) }
        else if now - startedAt >= Self.sessionDuration { stop() }
    }

    mutating func append(kind: InputDiagnostic.Kind, phase: InputDiagnostic.Phase,
                         modifiers: ModifierSet, outcome: InputDiagnostic.Outcome, at now: UInt64) {
        expire(at: now)
        guard let startedAt else { return }
        lastReceivedAt = now
        if now - windowStartedAt >= 1_000_000_000 {
            windowStartedAt = now
            acceptedInWindow = 0
        }
        guard acceptedInWindow < Self.eventsPerWindow else {
            omitted &+= 1
            revision &+= 1
            return
        }
        acceptedInWindow += 1
        sequence &+= 1
        storage[next] = InputDiagnostic(id: sequence, elapsedMilliseconds: (now - startedAt) / 1_000_000,
                                        kind: kind, phase: phase, modifiers: modifiers, outcome: outcome)
        next = (next + 1) % Self.capacity
        if count < Self.capacity { count += 1 } else { omitted &+= 1 }
        revision &+= 1
    }

    mutating func record(_ event: InputEvent, suppressed: Bool, queued: Bool) {
        guard isRunning, !event.isSynthetic, let now = event.receivedAt else { return }
        let kind: InputDiagnostic.Kind
        switch event.trigger {
        case .mouseButton(let number): kind = .button(number)
        case .scroll(let direction): kind = .wheel(direction)
        case .key, .mouseGesture, .fourFingerTap: return
        }
        let phase: InputDiagnostic.Phase
        switch event.phase {
        case .down: phase = .down
        case .up: phase = .up
        case .drag: phase = .drag
        case .scroll: phase = .scroll
        case .modifiersChanged: return
        }
        append(kind: kind, phase: phase, modifiers: event.modifiers,
               outcome: queued ? .queued : (suppressed ? .suppressed : .passedThrough), at: now)
    }

    func snapshot() -> DiagnosticSnapshot {
        var entries: [InputDiagnostic] = []
        entries.reserveCapacity(count)
        let first = (next + Self.capacity - count) % Self.capacity
        for offset in 0..<count {
            if let entry = storage[(first + offset) % Self.capacity] { entries.append(entry) }
        }
        return DiagnosticSnapshot(revision: revision, isRunning: isRunning, entries: entries, omitted: omitted)
    }
}
