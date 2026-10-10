// One receipt clock for both consumers. This does not align private native
// contact timestamps with Quartz event timestamps or identify physical source.
struct ProbeObservationClock: Sendable {
    private let startedAt: UInt64

    init(startedAt: UInt64) { self.startedAt = startedAt }

    func elapsedMilliseconds(at time: UInt64) -> UInt64? {
        guard time >= startedAt else { return nil }
        return (time - startedAt) / 1_000_000
    }
}

struct CandidateObservation: Encodable, Sendable {
    let fingers: Int
    let durationMilliseconds: Int
    let peakPressure: Float
    let elapsedMilliseconds: UInt64?

    init(_ candidate: ShortContactRecognizer.Candidate, elapsedMilliseconds: UInt64?) {
        fingers = candidate.fingers
        durationMilliseconds = candidate.durationMilliseconds
        peakPressure = candidate.peakPressure
        self.elapsedMilliseconds = elapsedMilliseconds
    }
}

struct ContactObservation: Encodable, Sendable {
    let contacts: Int
    let elapsedMilliseconds: UInt64?
}

struct ActionTestObservation: Encodable, Sendable {
    enum Phase: String, Encodable, Sendable { case waiting, rejected, cancelled }
    let phase: Phase
    let reason: FourFingerCloseGate.Reason?
    let elapsedMilliseconds: UInt64?
}
