import Foundation

// Aggregate-only output. Raw coordinates, contact IDs, device IDs and session
// dictionaries cannot be represented in the serialized report.
struct ProbeStatistics: Codable, Sendable {
    private(set) var frames = 0
    private(set) var rejectedFrames = 0
    private(set) var countTransitions = 0
    private(set) var contactCounts: Set<Int> = []
    private(set) var contactStates: Set<Int> = []
    private(set) var peakPressure: Float = 0
    private(set) var nonconsecutiveFrameIDs = 0
    private(set) var previousCount: Int?
    private var previousFrame: Int32?

    private enum CodingKeys: String, CodingKey {
        case frames, rejectedFrames, countTransitions, contactCounts, contactStates
        case peakPressure, nonconsecutiveFrameIDs
    }

    mutating func observe(count: Int, states: Set<Int>, peakPressure pressure: Float, frame: Int32?) -> Bool {
        guard (0...16).contains(count), states.allSatisfy({ (0...7).contains($0) }),
              pressure.isFinite, pressure >= 0 else {
            rejectedFrames += 1
            previousFrame = nil
            return false
        }
        frames += 1
        contactCounts.insert(count)
        contactStates.formUnion(states)
        peakPressure = max(peakPressure, pressure)
        if let frame, let previousFrame, Int64(frame) != Int64(previousFrame) + 1 {
            nonconsecutiveFrameIDs += 1
        }
        previousFrame = frame
        let changed = count != previousCount
        if changed { countTransitions += 1 }
        previousCount = count
        return changed
    }
}
