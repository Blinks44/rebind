import Foundation
import Testing
@testable import TrackpadProbe

struct ProbeTests {
    @Test func actionDecisionReportContainsOnlySafeMetadata() throws {
        let waiting = ActionTestObservation(phase: .waiting, reason: nil, elapsedMilliseconds: 10121)
        let cancelled = ActionTestObservation(phase: .cancelled, reason: .frameGap, elapsedMilliseconds: 10129)
        for observation in [waiting, cancelled] {
            let data = try JSONEncoder().encode(observation)
            let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
            #expect(Set(object.keys).isSubset(of: ["phase", "reason", "elapsedMilliseconds"]))
            #expect(object["phase"] as? String == observation.phase.rawValue)
            #expect(object["reason"] as? String == observation.reason?.rawValue)
            #expect(object["elapsedMilliseconds"] as? UInt64 == observation.elapsedMilliseconds)
        }
    }
    @Test func captureIsExplicitAndDurationIsBounded() throws {
        #expect(try ProbeOptions(arguments: []) == .check)
        #expect(try ProbeOptions(arguments: ["--check"]) == .check)
        #expect(try ProbeOptions(arguments: ["--capture"]) == .capture(seconds: 20))
        #expect(try ProbeOptions(arguments: ["--capture", "--seconds", "30"]) == .capture(seconds: 30))
        for seconds in ["0", "31", "-1", "infinity", "0.5"] {
            #expect(throws: ProbeOptions.InvalidArguments.self) {
                try ProbeOptions(arguments: ["--capture", "--seconds", seconds])
            }
        }
        #expect(throws: ProbeOptions.InvalidArguments.self) { try ProbeOptions(arguments: ["--seconds", "20"]) }
    }

    @Test func countChangesAndEmptyFramesResetTheSequence() {
        var statistics = ProbeStatistics()
        let changed1 = statistics.observe(count: 3, states: [3, 4], peakPressure: 10, frame: 1)
        #expect(changed1)
        let changed2 = statistics.observe(count: 3, states: [4], peakPressure: 20, frame: 2)
        #expect(!changed2)
        let changed3 = statistics.observe(count: 0, states: [], peakPressure: 0, frame: nil)
        #expect(changed3)
        let changed4 = statistics.observe(count: 4, states: [4], peakPressure: 5, frame: 99)
        #expect(changed4)
        #expect(statistics.contactCounts == [0, 3, 4])
        #expect(statistics.frames == 4 && statistics.countTransitions == 3)
        #expect(statistics.peakPressure == 20 && statistics.nonconsecutiveFrameIDs == 0)
    }

    @Test func gapsAndRolloverAreDiscontinuitiesNotNegativeDeltas() {
        var statistics = ProbeStatistics()
        _ = statistics.observe(count: 2, states: [4], peakPressure: 0, frame: .max)
        _ = statistics.observe(count: 2, states: [4], peakPressure: 0, frame: .min)
        #expect(statistics.nonconsecutiveFrameIDs == 1)
    }

    @Test func malformedMetadataNeverEntersTheShareableSummary() {
        var statistics = ProbeStatistics()
        for pressure in [Float.nan, .infinity, -1] {
            let changed5 = statistics.observe(count: 2, states: [4], peakPressure: pressure, frame: 1)
            #expect(!changed5)
        }
        let changed6 = statistics.observe(count: 17, states: [4], peakPressure: 0, frame: 1)
        #expect(!changed6)
        let changed7 = statistics.observe(count: 2, states: [8], peakPressure: 0, frame: 1)
        #expect(!changed7)
        #expect(statistics.frames == 0 && statistics.rejectedFrames == 5)
        #expect(statistics.contactCounts.isEmpty && statistics.contactStates.isEmpty)
    }

    @Test func reportContainsOnlyTheAggregateSchema() throws {
        var statistics = ProbeStatistics()
        _ = statistics.observe(count: 4, states: [3, 4], peakPressure: 25, frame: 50)
        let data = try JSONEncoder().encode(statistics)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["frames", "rejectedFrames", "countTransitions", "contactCounts",
                                   "contactStates", "peakPressure", "nonconsecutiveFrameIDs"])
    }

    @Test func unclassifiedDeviceCaptureRequiresAnExplicitMode() throws {
        #expect(try ProbeOptions(arguments: []) != .captureDefault(seconds: 20))
        #expect(try ProbeOptions(arguments: ["--capture-default"]) == .captureDefault(seconds: 20))
        #expect(try ProbeOptions(arguments: ["--capture-default", "--seconds", "1"]) == .captureDefault(seconds: 1))
        #expect(try ProbeOptions(arguments: ["--capture-default", "--seconds", "30"]) == .captureDefault(seconds: 30))
        for seconds in ["0", "31", "-1", "0.5"] {
            #expect(throws: ProbeOptions.InvalidArguments.self) {
                try ProbeOptions(arguments: ["--capture-default", "--seconds", seconds])
            }
        }
    }
}
