import Synchronization

struct ButtonObservations: Sendable {
    struct Record: Codable, Equatable, Sendable {
        enum Phase: String, Codable, Sendable { case down, up }
        let phase: Phase
        let button: Int64
        let pressure: Double
        // Temporal proximity only, never physical source attribution.
        let nearbyContacts: Int?
        // Milliseconds since this capture's shared receipt-clock origin.
        let elapsedMilliseconds: UInt64?
    }

    private(set) var records: [Record] = []
    private(set) var omitted = 0
    private(set) var observed = 0
    private var contactCount: Int?
    private var contactsSeenAt: UInt64?
    private(set) var disabled = false
    private(set) var installed = false
    private(set) var stopRequested = false
    private let clock: ProbeObservationClock

    init(clock: ProbeObservationClock = .init(startedAt: 0)) {
        self.clock = clock
        records.reserveCapacity(128)
    }

    mutating func markInstalled() { installed = true }
    mutating func requestStop() { stopRequested = true }

    mutating func updateContacts(_ count: Int?, at time: UInt64) {
        contactCount = count.flatMap { (0...16).contains($0) ? $0 : nil }
        contactsSeenAt = contactCount == nil ? nil : time
    }

    mutating func observe(phase: Record.Phase, button: Int64, pressure: Double, at time: UInt64) {
        guard !disabled, !stopRequested, button >= 0, pressure.isFinite, pressure >= 0 else { return }
        observed += 1
        guard records.count < 128 else { omitted += 1; return }
        let fresh = contactsSeenAt.map { time >= $0 && time - $0 <= 50_000_000 } ?? false
        records.append(Record(phase: phase, button: button, pressure: pressure,
                              nearbyContacts: fresh ? contactCount : nil,
                              elapsedMilliseconds: clock.elapsedMilliseconds(at: time)))
    }

    mutating func stop() {
        disabled = true
        stopRequested = true
        records.removeAll(keepingCapacity: true)
        updateContacts(nil, at: 0)
    }
}

final class ButtonObservationBuffer: Sendable {
    let state: Mutex<ButtonObservations>

    init(clock: ProbeObservationClock = .init(startedAt: 0)) {
        state = Mutex(ButtonObservations(clock: clock))
    }
}
