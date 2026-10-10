import Foundation
import Testing
@testable import TrackpadProbe

struct ShortContactTests {
    private func contacts(_ count: Int, offset: Float = 0) -> [ShortContactRecognizer.Contact] {
        (0..<count).map { .init(id: Int32($0), x: 0.2 + Float($0) * 0.1 + offset, y: 0.5, pressure: 100) }
    }

    @Test(arguments: [3, 4]) func candidateOccursOnceAfterLift(fingers: Int) throws {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        let began = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(fingers))
        let held = recognizer.consume(frame: 2, time: 0.03, contacts: contacts(fingers))
        #expect(began == nil && held == nil)
        let result = recognizer.consume(frame: 3, time: 0.05, contacts: [])
        let candidate = try #require(result)
        #expect(candidate.fingers == fingers && candidate.durationMilliseconds == 40)
        let repeated = recognizer.consume(frame: 4, time: 0.06, contacts: [])
        #expect(repeated == nil)
        let data = try JSONEncoder().encode(candidate)
        let report = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(report.keys) == ["fingers", "durationMilliseconds", "peakPressure"])
    }

    @Test func staggeredArrivalAndLiftUsePeakCount() throws {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        for (index, count) in [1, 2, 3, 4, 4, 3, 1].enumerated() {
            let candidate = recognizer.consume(frame: Int32(index + 1), time: Double(index + 1) * 0.02,
                                               contacts: contacts(count))
            #expect(candidate == nil)
        }
        let result = recognizer.consume(frame: 8, time: 0.16, contacts: [])
        let candidate = try #require(result)
        #expect(candidate.fingers == 4)
    }

    @Test(arguments: [1, 2, 5]) func unsupportedCountsNeverBecomeCandidates(fingers: Int) {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(fingers))
        _ = recognizer.consume(frame: 2, time: 0.03, contacts: contacts(fingers))
        let candidate = recognizer.consume(frame: 3, time: 0.05, contacts: [])
        #expect(candidate == nil)
    }

    @Test func movementAndHoldAreRejected() {
        for moving in [true, false] {
            var recognizer = ShortContactRecognizer()
            _ = recognizer.consume(frame: 0, time: 0, contacts: [])
            for frame in 1...16 {
                _ = recognizer.consume(frame: Int32(frame), time: Double(frame) * 0.02,
                                       contacts: contacts(3, offset: moving ? 0.04 : 0))
                if moving {
                    _ = recognizer.consume(frame: Int32(frame + 1), time: Double(frame + 1) * 0.02,
                                           contacts: contacts(3))
                    break
                }
            }
            let candidate = recognizer.consume(frame: moving ? 3 : 17, time: moving ? 0.06 : 0.34, contacts: [])
            #expect(candidate == nil)
        }
    }

    @Test func replacementBounceAndLateFingerAreRejected() {
        for scenario in 0...2 {
            var recognizer = ShortContactRecognizer()
            _ = recognizer.consume(frame: 0, time: 0, contacts: [])
            _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(3))
            for frame in 2...6 {
                var values = contacts(3)
                if scenario == 0 && frame >= 3 {
                    values[0] = .init(id: 8, x: 0.2, y: 0.5, pressure: 100)
                } else if scenario == 1 && frame == 3 {
                    values = contacts(2)
                } else if scenario == 2 && frame >= 6 {
                    values = contacts(4)
                }
                _ = recognizer.consume(frame: Int32(frame), time: Double(frame) * 0.02, contacts: values)
            }
            let candidate = recognizer.consume(frame: 7, time: 0.14, contacts: [])
            #expect(candidate == nil)
        }
    }

    @Test func lostFramesBadTimeAndCancellationRequireNeutral() {
        for scenario in 0...3 {
            var recognizer = ShortContactRecognizer()
            _ = recognizer.consume(frame: 0, time: 0, contacts: [])
            _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(3))
            if scenario == 3 { recognizer.interrupt() }
            _ = recognizer.consume(frame: scenario == 0 ? 3 : 2,
                                   time: scenario == 1 ? 0.005 : (scenario == 2 ? 0.1 : 0.03), contacts: contacts(3))
            let endedFrame: Int32 = scenario == 0 ? 4 : 3
            let endedTime = scenario == 2 ? 0.12 : 0.05
            let candidate = recognizer.consume(frame: endedFrame, time: endedTime, contacts: [])
            #expect(candidate == nil)
            _ = recognizer.consume(frame: endedFrame + 1, time: endedTime + 0.02, contacts: contacts(4))
            _ = recognizer.consume(frame: endedFrame + 2, time: endedTime + 0.04, contacts: contacts(4))
            let recovered = recognizer.consume(frame: endedFrame + 3, time: endedTime + 0.06, contacts: [])
            #expect(recovered?.fingers == 4)
        }
    }

    @Test func startupMidTouchAndUntimedEndCannotProduceCandidate() {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(4))
        _ = recognizer.consume(frame: 2, time: 0.03, contacts: contacts(4))
        let startup = recognizer.consume(frame: 3, time: 0.05, contacts: [])
        #expect(startup == nil)
        _ = recognizer.consume(frame: 4, time: 0.07, contacts: contacts(4))
        _ = recognizer.consume(frame: 5, time: 0.09, contacts: contacts(4))
        recognizer.interrupt(isNeutral: true)
        let empty = recognizer.consume(frame: 6, time: 0.11, contacts: [])
        #expect(empty == nil)
    }

    @Test func malformedContactsAndTransientPeakAreRejected() {
        for malformed in [contacts(3) + [contacts(3)[0]], [.init(id: 0, x: .nan, y: 0.5, pressure: 0)]] {
            var recognizer = ShortContactRecognizer()
            _ = recognizer.consume(frame: 0, time: 0, contacts: [])
            _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(3))
            _ = recognizer.consume(frame: 2, time: 0.03, contacts: malformed)
            let candidate = recognizer.consume(frame: 3, time: 0.05, contacts: [])
            #expect(candidate == nil)
        }
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(3))
        _ = recognizer.consume(frame: 2, time: 0.02, contacts: contacts(2))
        let transient = recognizer.consume(frame: 3, time: 0.05, contacts: [])
        #expect(transient == nil)
    }

    @Test func idleSilenceBetweenConsecutiveFramesDoesNotCancelNewStroke() {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        _ = recognizer.consume(frame: 1, time: 2, contacts: contacts(3))
        _ = recognizer.consume(frame: 2, time: 2.02, contacts: contacts(3))
        let candidate = recognizer.consume(frame: 3, time: 2.04, contacts: [])
        #expect(candidate?.fingers == 3)
    }
}
