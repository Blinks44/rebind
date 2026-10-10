// Pure sequencing only. No native capture, source attribution, suppression or
// action dispatch. The future adapter must validate motion/contact continuity
// and independently exclude clicks before submitting a completed tap.
nonisolated struct TrackpadTapSequence: Sendable {
    enum Gesture: Hashable, Sendable {
        case singleTap(fingers: Int)
        case doubleTap(fingers: Int)
        case cornerTap(TrackpadCorner)

        fileprivate var isSupported: Bool {
            switch self {
            case .singleTap(let fingers): [3, 4].contains(fingers)
            case .doubleTap(let fingers): (2...4).contains(fingers)
            case .cornerTap: true
            }
        }
    }

    struct Tap: Sendable {
        let fingers: Int
        // A qualified contact's starting centroid; retained in memory only.
        let x: Float
        let y: Float
    }

    private struct Pending: Sendable {
        let tap: Tap
        let deadline: UInt64
    }

    private let enabled: Set<Gesture>
    private let doubleTapInterval: UInt64
    private var pending: Pending?
    private var contactStartedAt: UInt64?
    private var lastTime: UInt64?

    static let minimumTapDuration: UInt64 = 20_000_000
    static let maximumTapDuration: UInt64 = 350_000_000
    static let maximumPollLateness: UInt64 = 100_000_000

    // Inject a validated system interval (NSEvent.doubleClickInterval) when a
    // production adapter is wired. Never query AppKit on the contact path.
    init?(enabled: Set<Gesture>, doubleTapIntervalNanoseconds: UInt64) {
        guard enabled.allSatisfy(\.isSupported),
              (1...2_000_000_000).contains(doubleTapIntervalNanoseconds) else { return nil }
        self.enabled = enabled
        doubleTapInterval = doubleTapIntervalNanoseconds
    }

    // The adapter calls this once after neutral -> contact, using the same
    // monotonic receipt clock as finish/poll. Starting mid-contact is forbidden.
    mutating func beginContact(at time: UInt64) -> [Gesture] {
        guard advanceClock(to: time) else { return [] }
        guard contactStartedAt == nil else { cancel(); return [] }
        let expired = expire(at: time)
        contactStartedAt = time
        return expired
    }

    mutating func finishContact(_ tap: Tap, at time: UInt64, clickExcluded: Bool) -> [Gesture] {
        guard advanceClock(to: time), let start = contactStartedAt,
              time >= start, (Self.minimumTapDuration...Self.maximumTapDuration).contains(time - start),
              clickExcluded, (1...4).contains(tap.fingers),
              tap.x.isFinite, tap.y.isFinite, (0...1).contains(tap.x), (0...1).contains(tap.y)
        else { cancel(); return [] }
        contactStartedAt = nil

        if let previous = pending, previous.tap.fingers == tap.fingers,
           enabled.contains(.doubleTap(fingers: tap.fingers)), nearby(previous.tap, tap) {
            // beginContact already enforces the inter-tap deadline. A second
            // valid tap may finish after it; polling cannot fire during contact.
            pending = nil
            return [.doubleTap(fingers: tap.fingers)]
        }

        // A different valid tap ends the previous pair. Emit at most its single
        // and this tap's single; unsupported gestures never become output.
        var result: [Gesture] = []
        if let previous = pending, let single = singleGesture(for: previous.tap) { result.append(single) }
        pending = nil
        if enabled.contains(.doubleTap(fingers: tap.fingers)) {
            let (deadline, overflow) = time.addingReportingOverflow(doubleTapInterval)
            guard !overflow else { cancel(); return [] }
            pending = Pending(tap: tap, deadline: deadline)
        } else if let single = singleGesture(for: tap) {
            result.append(single)
        }
        return result
    }

    mutating func poll(at time: UInt64) -> [Gesture] {
        guard advanceClock(to: time) else { return [] }
        if let start = contactStartedAt {
            // A lost release / held second chord must not deliver a stale first
            // action later. The adapter additionally resets on frame loss.
            if time - start > Self.maximumTapDuration { cancel() }
            return []
        }
        return expire(at: time)
    }

    // Required on any observed button click, movement/uncertain frame, pause,
    // profile switch, permission loss, sleep or device/session discontinuity.
    mutating func cancel() {
        pending = nil
        contactStartedAt = nil
        lastTime = nil
    }

    private mutating func advanceClock(to time: UInt64) -> Bool {
        guard lastTime.map({ time >= $0 }) ?? true else { cancel(); return false }
        lastTime = time
        return true
    }

    private mutating func expire(at time: UInt64) -> [Gesture] {
        guard let previous = pending, time >= previous.deadline else { return [] }
        pending = nil
        guard time - previous.deadline <= Self.maximumPollLateness,
              let single = singleGesture(for: previous.tap) else { return [] }
        return [single]
    }

    private func singleGesture(for tap: Tap) -> Gesture? {
        let gesture: Gesture
        if tap.fingers == 1, let corner = TrackpadCorner.containing(x: tap.x, y: tap.y) {
            gesture = .cornerTap(corner)
        } else {
            gesture = .singleTap(fingers: tap.fingers)
        }
        return enabled.contains(gesture) ? gesture : nil
    }

    private func nearby(_ first: Tap, _ second: Tap) -> Bool {
        let x = first.x - second.x
        let y = first.y - second.y
        // Provisional normalized centroid tolerance, not physical distance.
        let distance: Float = 0.08
        return x * x + y * y <= distance * distance
    }
}
