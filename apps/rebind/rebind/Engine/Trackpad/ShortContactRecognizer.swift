import Foundation

// Short stationary contact classification. A physical click can satisfy these bounds;
// do not dispatch a tap action without an independent click-exclusion signal.
nonisolated struct ShortContactRecognizer: Sendable {
    enum Rejection: String, Sendable {
        case invalidMetadata = "invalid-metadata", frameGap = "frame-gap", nativeTime = "native-time"
        case neutralRequired = "neutral-required", changedContacts = "changed-contacts"
        case placementSpread = "placement-spread", travel = "travel", duration = "duration"
        case liftSpread = "lift-spread", fingerCount = "finger-count", transientPeak = "transient-peak"
    }
    private(set) var rejection: Rejection?
    // Transient qualified origin only; excluded from Codable diagnostic payloads.
    private(set) var origin: (x: Float, y: Float)?
    struct Contact: Sendable {
        let id: Int32
        let x: Float
        let y: Float
        let pressure: Float
    }

    struct Candidate: Codable, Equatable, Sendable {
        let fingers: Int
        let durationMilliseconds: Int
        let peakPressure: Float
    }

    private struct Stroke: Sendable {
        let started: Double
        var origins: [Int32: Contact] = [:]
        var peakCount = 0
        var peakFrames = 0
        var previousCount = 0
        var previousIDs: Set<Int32> = []
        var firstLift: Double?
        var pressure: Float = 0
        var valid = true
        var rejection: Rejection?
    }

    private(set) var continuity: UInt64 = 0
    private var stroke: Stroke?
    private var previousFrame: Int32?
    private var previousTime: Double?
    private var needsNeutral = true

    // Allow natural rolling placement/lift and slight fingertip movement.
    // Keep individual-contact travel checks: a stable centroid can hide a pinch.
    private static let maximumDuration = 0.4
    private static let fingerSpread = 0.15
    private static let maximumTravel: Float = 0.04

    // Unknown frame time/identity (including upstream empty arrays) cannot finish
    // a candidate safely. An empty frame still establishes contact neutrality.
    mutating func interrupt(isNeutral: Bool = false) {
        continuity &+= 1
        stroke = nil
        origin = nil
        previousFrame = nil
        previousTime = nil
        needsNeutral = !isNeutral
    }

    mutating func consume(frame: Int32, time: Double, contacts: [Contact],
                          allowIdleFrameGaps: Bool = true) -> Candidate? {
        rejection = nil
        origin = nil
        guard time.isFinite, time >= 0, contacts.count <= 16,
              Set(contacts.map(\.id)).count == contacts.count,
              contacts.allSatisfy({
                  $0.x.isFinite && $0.y.isFinite && (0...1).contains($0.x) && (0...1).contains($0.y)
                  && $0.pressure.isFinite && $0.pressure >= 0
              }) else {
            interrupt()
            rejection = .invalidMetadata
            return nil
        }
        if let previousFrame, let previousTime {
            // A forward gap after known release must not discard every new tap.
            // Never bridge missing samples inside a stroke or a pending action;
            // backwards/repeated native IDs and nonmonotonic time still cancel.
            let idleGap = allowIdleFrameGaps && stroke == nil && !needsNeutral
                && Int64(frame) > Int64(previousFrame) + 1
            if (Int64(frame) != Int64(previousFrame) + 1 && !idleGap)
                || time <= previousTime || (stroke != nil && time - previousTime > 0.05) {
                continuity &+= 1
                stroke = nil
                needsNeutral = true
                rejection = time <= previousTime ? .nativeTime : .frameGap
            }
        }
        previousFrame = frame
        previousTime = time

        if contacts.isEmpty {
            needsNeutral = false
            defer { stroke = nil }
            guard let stroke else { return nil }
            guard stroke.valid else { rejection = stroke.rejection; return nil }
            guard TrackpadTapSequence.candidateFingerCounts.contains(stroke.peakCount),
                  stroke.origins.count == stroke.peakCount else { rejection = .fingerCount; return nil }
            guard time - stroke.started >= 0.03, time - stroke.started <= Self.maximumDuration else { rejection = .duration; return nil }
            guard stroke.peakFrames >= 2 else { rejection = .transientPeak; return nil }
            guard stroke.firstLift.map({ time - $0 <= Self.fingerSpread }) ?? true else { rejection = .liftSpread; return nil }
            let sum = stroke.origins.values.reduce((x: Float(0), y: Float(0))) { ($0.x + $1.x, $0.y + $1.y) }
            origin = (sum.x / Float(stroke.peakCount), sum.y / Float(stroke.peakCount))
            return Candidate(fingers: stroke.peakCount,
                             durationMilliseconds: Int(((time - stroke.started) * 1000).rounded()),
                             peakPressure: stroke.pressure)
        }
        guard !needsNeutral else { if rejection == nil { rejection = .neutralRequired }; return nil }
        var current = stroke ?? Stroke(started: time)
        let ids = Set(contacts.map(\.id))
        if !current.previousIDs.isSubset(of: ids), current.firstLift == nil { current.firstLift = time }
        if current.firstLift != nil, contacts.count > current.previousCount {
            current.valid = false; if current.rejection == nil { current.rejection = .changedContacts }
        }
        if contacts.count > current.peakCount {
            current.peakCount = contacts.count
            current.peakFrames = 0
        }
        if contacts.count == current.peakCount {
            current.peakFrames += 1
        }
        for contact in contacts {
            if let origin = current.origins[contact.id] {
                let dx = contact.x - origin.x, dy = contact.y - origin.y
                if dx * dx + dy * dy > Self.maximumTravel * Self.maximumTravel {
                    current.valid = false; if current.rejection == nil { current.rejection = .travel }
                }
            } else {
                if time - current.started > Self.fingerSpread || current.firstLift != nil || current.origins.count >= 4 {
                    current.valid = false
                    if current.rejection == nil { current.rejection = current.firstLift != nil ? .changedContacts : .placementSpread }
                }
                // Keep memory bounded even for an invalid long/changing sequence.
                if current.origins.count < 4 { current.origins[contact.id] = contact }
            }
            current.pressure = max(current.pressure, contact.pressure)
        }
        if time - current.started > Self.maximumDuration || current.firstLift.map({ time - $0 > Self.fingerSpread }) ?? false {
            current.valid = false
            if current.rejection == nil { current.rejection = time - current.started > Self.maximumDuration ? .duration : .liftSpread }
        }
        current.previousCount = contacts.count
        current.previousIDs = ids
        stroke = current
        return nil
    }
}
