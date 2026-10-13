import Foundation
import Testing
@testable import rebind

struct AppShortContactTests {
    private func contacts(_ count: Int, offset: Float = 0) -> [ShortContactRecognizer.Contact] {
        (0..<count).map { .init(id: Int32($0), x: 0.2 + Float($0) * 0.1 + offset, y: 0.5, pressure: 100) }
    }

    @Test func diagnosticReasonsDistinguishMotionFromChangingContacts() {
        for changedContacts in [false, true] {
            var recognizer = ShortContactRecognizer()
            _ = recognizer.consume(frame: 0, time: 0, contacts: [])
            _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(4))
            _ = recognizer.consume(frame: 2, time: 0.03, contacts: contacts(changedContacts ? 3 : 4))
            _ = recognizer.consume(frame: 3, time: 0.05,
                                   contacts: contacts(4, offset: changedContacts ? 0 : 0.06))
            let candidate = recognizer.consume(frame: 4, time: 0.07, contacts: [])
            #expect(candidate == nil)
            #expect(recognizer.rejection == (changedContacts ? .changedContacts : .travel))
        }
    }

    @Test(arguments: [2, 3, 4]) func candidateOccursOnceAfterLift(fingers: Int) throws {
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

    @Test func twoFingerStrokeQualifiesOnlyWhenStationary() throws {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(2))
        _ = recognizer.consume(frame: 2, time: 0.03, contacts: contacts(2))
        let consumed = recognizer.consume(frame: 3, time: 0.05, contacts: [])
        let candidate = try #require(consumed)
        #expect(candidate.fingers == 2)
        var scrolling = ShortContactRecognizer()
        _ = scrolling.consume(frame: 0, time: 0, contacts: [])
        _ = scrolling.consume(frame: 1, time: 0.01, contacts: contacts(2))
        _ = scrolling.consume(frame: 2, time: 0.03, contacts: contacts(2, offset: 0.06))
        #expect(scrolling.consume(frame: 3, time: 0.05, contacts: []) == nil)
        #expect(scrolling.rejection == .travel)
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

    @Test(arguments: [5, 6]) func unsupportedCountsNeverBecomeCandidates(fingers: Int) {
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
            for frame in 1...22 {
                _ = recognizer.consume(frame: Int32(frame), time: Double(frame) * 0.02,
                                       contacts: contacts(3, offset: moving ? 0.06 : 0))
                if moving {
                    _ = recognizer.consume(frame: Int32(frame + 1), time: Double(frame + 1) * 0.02,
                                           contacts: contacts(3))
                    break
                }
            }
            let candidate = recognizer.consume(frame: moving ? 3 : 23, time: moving ? 0.06 : 0.46, contacts: [])
            #expect(candidate == nil)
        }
    }

    @Test func replacementBounceAndLateFingerAreRejected() {
        for scenario in 0...2 {
            var recognizer = ShortContactRecognizer()
            _ = recognizer.consume(frame: 0, time: 0, contacts: [])
            _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(3))
            for frame in 2...10 {
                var values = contacts(3)
                if scenario == 0 && frame >= 3 {
                    values[0] = .init(id: 8, x: 0.2, y: 0.5, pressure: 100)
                } else if scenario == 1 && frame == 3 {
                    values = contacts(2)
                } else if scenario == 2 && frame >= 9 {
                    values = contacts(4)
                }
                _ = recognizer.consume(frame: Int32(frame), time: Double(frame) * 0.02, contacts: values)
            }
            let candidate = recognizer.consume(frame: 11, time: 0.22, contacts: [])
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

    @Test func forwardFrameGapAfterKnownNeutralDoesNotDiscardEveryNewTap() {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        for stroke in 1...3 {
            let first = Int32(stroke * 100)
            let start = Double(stroke)
            _ = recognizer.consume(frame: first, time: start, contacts: contacts(4))
            _ = recognizer.consume(frame: first + 1, time: start + 0.02, contacts: contacts(4))
            let candidate = recognizer.consume(frame: first + 2, time: start + 0.04, contacts: [])
            #expect(candidate?.fingers == 4)
        }
    }

    @Test(arguments: [99, 100]) func idleFrameRegressionStillCancelsAndThenRecovers(_ id: Int32) {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 100, time: 1, contacts: [])
        _ = recognizer.consume(frame: id, time: 2, contacts: contacts(4))
        _ = recognizer.consume(frame: id + 1, time: 2.02, contacts: contacts(4))
        let invalid = recognizer.consume(frame: id + 2, time: 2.04, contacts: [])
        #expect(invalid == nil)
        _ = recognizer.consume(frame: 200, time: 3, contacts: contacts(4))
        _ = recognizer.consume(frame: 201, time: 3.02, contacts: contacts(4))
        let recovered = recognizer.consume(frame: 202, time: 3.04, contacts: [])
        #expect(recovered?.fingers == 4)
    }

    @Test func twoEightMillisecondPeakFramesRecognizeAFastTap() {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        _ = recognizer.consume(frame: 1, time: 0.01, contacts: contacts(3))
        _ = recognizer.consume(frame: 2, time: 0.018, contacts: contacts(4))
        _ = recognizer.consume(frame: 3, time: 0.026, contacts: contacts(4))
        _ = recognizer.consume(frame: 4, time: 0.034, contacts: contacts(2))
        let candidate = recognizer.consume(frame: 5, time: 0.042, contacts: [])
        #expect(candidate?.fingers == 4 && candidate?.durationMilliseconds == 32)
    }

    @Test func rollingPlacementLiftAndSmallFingertipShiftAreAccepted() {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        // All fingers arrive over 120 ms, lift over 120 ms, and drift by 3%.
        let counts = [1, 1, 2, 2, 3, 3, 4, 4, 4, 4, 3, 3, 2, 2, 1, 1, 0]
        var candidate: ShortContactRecognizer.Candidate?
        for (index, count) in counts.enumerated() {
            candidate = recognizer.consume(frame: Int32(index + 1), time: Double(index + 1) * 0.02,
                                           contacts: contacts(count, offset: index >= 8 ? 0.03 : 0))
            if index < counts.count - 1 { #expect(candidate == nil) }
        }
        #expect(candidate?.fingers == 4 && candidate?.durationMilliseconds == 320)
    }

    @Test func OpposingFingerMovementCannotHideBehindAStableCentroid() {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        _ = recognizer.consume(frame: 1, time: 0.02, contacts: contacts(4))
        var values = contacts(4)
        values[0] = .init(id: 0, x: 0.25, y: 0.5, pressure: 100)
        values[3] = .init(id: 3, x: 0.45, y: 0.5, pressure: 100)
        _ = recognizer.consume(frame: 2, time: 0.04, contacts: values)
        let candidate = recognizer.consume(frame: 3, time: 0.06, contacts: [])
        #expect(candidate == nil)
    }

    @Test func slowRollingLiftStillRejectsTheStroke() {
        var recognizer = ShortContactRecognizer()
        _ = recognizer.consume(frame: 0, time: 0, contacts: [])
        for index in 1...11 {
            _ = recognizer.consume(frame: Int32(index), time: Double(index) * 0.02,
                                   contacts: contacts(index < 3 ? 4 : 3))
        }
        let candidate = recognizer.consume(frame: 12, time: 0.24, contacts: [])
        #expect(candidate == nil)
    }
}
