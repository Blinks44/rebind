import Foundation

// Short stationary contact classification. A physical click can satisfy these bounds;
// do not dispatch a tap action without an independent click-exclusion signal.
nonisolated struct ShortContactRecognizer: Sendable {
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
        var peakStarted: Double = 0
        var peakLastSeen: Double = 0
        var previousCount = 0
        var previousIDs: Set<Int32> = []
        var firstLift: Double?
        var pressure: Float = 0
        var valid = true
    }

    private(set) var continuity: UInt64 = 0
    private var stroke: Stroke?
    private var previousFrame: Int32?
    private var previousTime: Double?
    private var needsNeutral = true

    // Unknown frame time/identity (including upstream empty arrays) cannot finish
    // a candidate safely. An empty frame still establishes contact neutrality.
    mutating func interrupt(isNeutral: Bool = false) {
        continuity &+= 1
        stroke = nil
        previousFrame = nil
        previousTime = nil
        needsNeutral = !isNeutral
    }

    mutating func consume(frame: Int32, time: Double, contacts: [Contact]) -> Candidate? {
        guard time.isFinite, time >= 0, contacts.count <= 16,
              Set(contacts.map(\.id)).count == contacts.count,
              contacts.allSatisfy({
                  $0.x.isFinite && $0.y.isFinite && (0...1).contains($0.x) && (0...1).contains($0.y)
                  && $0.pressure.isFinite && $0.pressure >= 0
              }) else {
            interrupt()
            return nil
        }
        if let previousFrame, let previousTime,
           Int64(frame) != Int64(previousFrame) + 1 || time <= previousTime || (stroke != nil && time - previousTime > 0.05) {
            continuity &+= 1
            stroke = nil
            needsNeutral = true
        }
        previousFrame = frame
        previousTime = time

        if contacts.isEmpty {
            needsNeutral = false
            defer { stroke = nil }
            guard let stroke, stroke.valid, [3, 4].contains(stroke.peakCount), stroke.origins.count == stroke.peakCount,
                  time - stroke.started >= 0.03, time - stroke.started <= 0.25,
                  stroke.peakLastSeen - stroke.peakStarted >= 0.015,
                  stroke.firstLift.map({ time - $0 <= 0.08 }) ?? true else { return nil }
            return Candidate(fingers: stroke.peakCount,
                             durationMilliseconds: Int(((time - stroke.started) * 1000).rounded()),
                             peakPressure: stroke.pressure)
        }
        guard !needsNeutral else { return nil }
        var current = stroke ?? Stroke(started: time)
        let ids = Set(contacts.map(\.id))
        if !current.previousIDs.isSubset(of: ids), current.firstLift == nil { current.firstLift = time }
        if current.firstLift != nil, contacts.count > current.previousCount { current.valid = false }
        if contacts.count > current.peakCount {
            current.peakCount = contacts.count
            current.peakStarted = time
        }
        if contacts.count == current.peakCount { current.peakLastSeen = time }
        for contact in contacts {
            if let origin = current.origins[contact.id] {
                let dx = contact.x - origin.x, dy = contact.y - origin.y
                if dx * dx + dy * dy > 0.02 * 0.02 { current.valid = false }
            } else {
                if time - current.started > 0.08 || current.firstLift != nil || current.origins.count >= 4 {
                    current.valid = false
                }
                // Keep memory bounded even for an invalid long/changing sequence.
                if current.origins.count < 4 { current.origins[contact.id] = contact }
            }
            current.pressure = max(current.pressure, contact.pressure)
        }
        if time - current.started > 0.25 || current.firstLift.map({ time - $0 > 0.08 }) ?? false {
            current.valid = false
        }
        current.previousCount = contacts.count
        current.previousIDs = ids
        stroke = current
        return nil
    }
}
