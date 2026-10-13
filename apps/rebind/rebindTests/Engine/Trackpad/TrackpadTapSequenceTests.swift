import Testing
@testable import rebind

struct TrackpadTapSequenceTests {
    private typealias Sequence = TrackpadTapSequence
    private typealias Gesture = TrackpadTapSequence.Gesture
    private let interval: UInt64 = 500_000_000

    private func sequence(_ gestures: Set<Gesture>) throws -> Sequence {
        try #require(Sequence(enabled: gestures, doubleTapIntervalNanoseconds: interval))
    }

    private func tap(_ sequence: inout Sequence, fingers: Int = 3, start: UInt64,
                     x: Float = 0.5, y: Float = 0.5, duration: UInt64 = 100_000_000,
                     buttonActivityUnchanged: Bool = true) -> [Gesture] {
        let began = sequence.beginContact(at: start)
        let ended = sequence.finishContact(.init(fingers: fingers, x: x, y: y),
                                           at: start + duration, buttonActivityUnchanged: buttonActivityUnchanged)
        return began + ended
    }

    @Test(arguments: [3, 4])
    func singleOnlyDoesNotWaitForAnUnconfiguredDouble(_ fingers: Int) throws {
        var sut = try sequence([.singleTap(fingers: fingers)])
        let first = tap(&sut, fingers: fingers, start: 0)
        let poll = sut.poll(at: interval)
        let second = tap(&sut, fingers: fingers, start: interval)
        #expect(first == [.singleTap(fingers: fingers)])
        #expect(poll.isEmpty)
        #expect(second == first)
    }

    @Test(arguments: [2, 3, 4])
    func pairProducesOnlyDoubleAndDoesNotReuseSecondTap(_ fingers: Int) throws {
        var configured: Set<Gesture> = [.doubleTap(fingers: fingers)]
        if fingers >= 3 { configured.insert(.singleTap(fingers: fingers)) }
        var sut = try sequence(configured)
        let first = tap(&sut, fingers: fingers, start: 0)
        let pair = tap(&sut, fingers: fingers, start: 200_000_000)
        let third = tap(&sut, fingers: fingers, start: 400_000_000)
        let fourth = tap(&sut, fingers: fingers, start: 600_000_000)
        #expect(first.isEmpty)
        #expect(pair == [.doubleTap(fingers: fingers)])
        #expect(third.isEmpty)
        #expect(fourth == pair)
        #expect(sut.poll(at: 1_300_000_000).isEmpty)
    }

    @Test func solitaryTapExpiresOnceAndTwoFingerSingleIsAbsent() throws {
        for fingers in [2, 3, 4] {
            var configured: Set<Gesture> = [.doubleTap(fingers: fingers)]
            if fingers >= 3 { configured.insert(.singleTap(fingers: fingers)) }
            var sut = try sequence(configured)
            let first = tap(&sut, fingers: fingers, start: 0)
            let early = sut.poll(at: 599_999_999)
            let expired = sut.poll(at: 600_000_000)
            let repeated = sut.poll(at: 600_000_001)
            #expect(first.isEmpty && early.isEmpty && repeated.isEmpty)
            #expect(expired == (fingers == 2 ? [] : [.singleTap(fingers: fingers)]))
        }
    }

    @Test func secondContactCanFinishAfterDeadlineWithoutFirstSingleFiring() throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3)])
        _ = tap(&sut, start: 0)
        let began = sut.beginContact(at: 599_999_999)
        let duringContact = sut.poll(at: 650_000_000)
        let finished = sut.finishContact(.init(fingers: 3, x: 0.52, y: 0.5),
                                         at: 700_000_000, buttonActivityUnchanged: true)
        #expect(began.isEmpty && duringContact.isEmpty)
        #expect(finished == [.doubleTap(fingers: 3)])
    }

    @Test func contactAtDeadlineStartsNewPair() throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3)])
        _ = tap(&sut, start: 0)
        let second = tap(&sut, start: 600_000_000)
        let expiry = sut.poll(at: 1_200_000_000)
        #expect(second == [.singleTap(fingers: 3)])
        #expect(expiry == [.singleTap(fingers: 3)])
    }

    @Test(arguments: [false, true])
    func differentFingerCountOrDistantLocationCannotCompletePair(_ distant: Bool) throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3),
                                .singleTap(fingers: 4), .doubleTap(fingers: 4)])
        _ = tap(&sut, start: 0)
        let secondFingers = distant ? 3 : 4
        let second = tap(&sut, fingers: secondFingers, start: 200_000_000, x: distant ? 0.8 : 0.5)
        let expiry = sut.poll(at: 800_000_000)
        #expect(second == [.singleTap(fingers: 3)])
        #expect(expiry == [.singleTap(fingers: secondFingers)])
    }

    @Test(arguments: TrackpadCorner.allCases)
    func singleFingerOnlyFiresConfiguredCorner(_ corner: TrackpadCorner) throws {
        var sut = try sequence([.cornerTap(corner)])
        let left = corner == .topLeft || corner == .bottomLeft
        let top = corner == .topLeft || corner == .topRight
        let recognized = tap(&sut, fingers: 1, start: 0, x: left ? 0.1 : 0.9, y: top ? 0.9 : 0.1)
        let center = tap(&sut, fingers: 1, start: 200_000_000)
        let otherCorner = tap(&sut, fingers: 1, start: 400_000_000, x: left ? 0.9 : 0.1, y: top ? 0.9 : 0.1)
        #expect(recognized == [.cornerTap(corner)])
        #expect(center.isEmpty && otherCorner.isEmpty)
    }

    @Test func observedButtonChangeCancelsBothCurrentAndPendingTap() throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3)])
        _ = tap(&sut, start: 0)
        let uncertain = tap(&sut, start: 200_000_000, buttonActivityUnchanged: false)
        let poll = sut.poll(at: 800_000_000)
        let newFirst = tap(&sut, start: 900_000_000)
        #expect(uncertain.isEmpty && poll.isEmpty && newFirst.isEmpty)
    }

    @Test func lifecycleCancellationDropsPendingAndActiveContacts() throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3)])
        _ = tap(&sut, start: 0)
        _ = sut.beginContact(at: 200_000_000)
        sut.cancel() // Same reset contract for a button, pause, loss or profile change.
        let lateRelease = sut.finishContact(.init(fingers: 3, x: 0.5, y: 0.5),
                                            at: 300_000_000, buttonActivityUnchanged: true)
        let expiry = sut.poll(at: 600_000_000)
        let first = tap(&sut, start: 700_000_000)
        #expect(lateRelease.isEmpty && expiry.isEmpty && first.isEmpty)
    }

    @Test(arguments: [UInt64(0), 19_999_999, 350_000_001, 1_000_000_000])
    func shortOrHeldSecondContactCannotDeliverPendingFirst(_ duration: UInt64) throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3)])
        _ = tap(&sut, start: 0)
        let invalid = tap(&sut, start: 200_000_000, duration: duration)
        let expiry = sut.poll(at: 1_300_000_000)
        #expect(invalid.isEmpty && expiry.isEmpty)
    }

    @Test func lostReleaseAndDuplicateBeginRequireNewContact() throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3)])
        _ = tap(&sut, start: 0)
        _ = sut.beginContact(at: 200_000_000)
        let held = sut.poll(at: 550_000_001)
        let release = sut.finishContact(.init(fingers: 3, x: 0.5, y: 0.5),
                                        at: 560_000_000, buttonActivityUnchanged: true)
        _ = sut.beginContact(at: 600_000_000)
        let duplicate = sut.beginContact(at: 610_000_000)
        let duplicateRelease = sut.finishContact(.init(fingers: 3, x: 0.5, y: 0.5),
                                                 at: 700_000_000, buttonActivityUnchanged: true)
        #expect(held.isEmpty && release.isEmpty && duplicate.isEmpty && duplicateRelease.isEmpty)
    }

    @Test(arguments: [
        (0, Float(0.5), Float(0.5)), (5, 0.5, 0.5), (3, .nan, 0.5),
        (3, 0.5, .infinity), (3, -0.1, 0.5), (3, 0.5, 1.1),
    ])
    func malformedCompletedTapDropsThePair(_ sample: (Int, Float, Float)) throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3)])
        _ = tap(&sut, start: 0)
        let invalid = tap(&sut, fingers: sample.0, start: 200_000_000, x: sample.1, y: sample.2)
        let expiry = sut.poll(at: 600_000_000)
        #expect(invalid.isEmpty && expiry.isEmpty)
    }

    @Test func regressedClockAndOverflowDiscardPendingState() throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3)])
        _ = tap(&sut, start: 100_000_000)
        let regressed = sut.beginContact(at: 199_999_999)
        let expiry = sut.poll(at: 700_000_000)
        #expect(regressed.isEmpty && expiry.isEmpty)
        sut.cancel()
        let nearMaximum = tap(&sut, start: .max - 200_000_000)
        let overflowPoll = sut.poll(at: .max)
        #expect(nearMaximum.isEmpty && overflowPoll.isEmpty)
    }

    @Test func stalledWorkerDoesNotDeliverAnOldSingle() throws {
        var sut = try sequence([.singleTap(fingers: 3), .doubleTap(fingers: 3)])
        _ = tap(&sut, start: 0)
        let delayed = sut.poll(at: 700_000_001)
        let repeated = sut.poll(at: 800_000_000)
        #expect(delayed.isEmpty && repeated.isEmpty)
    }

    @Test func unsupportedConfigurationCannotEnableExtraGestureKinds() {
        for gesture in [Gesture.singleTap(fingers: 1), .singleTap(fingers: 2),
                        .singleTap(fingers: 5), .doubleTap(fingers: 1), .doubleTap(fingers: 5)] {
            #expect(Sequence(enabled: [gesture], doubleTapIntervalNanoseconds: interval) == nil)
        }
        for value: UInt64 in [0, 2_000_000_001, .max] {
            #expect(Sequence(enabled: [], doubleTapIntervalNanoseconds: value) == nil)
        }
    }
}
