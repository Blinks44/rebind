import ApplicationServices
import Foundation
import Testing
@testable import TrackpadProbe

struct ButtonObservationTests {
    @Test func combinedCaptureIsExplicitAndBounded() throws {
        #expect(try ProbeOptions(arguments: []) == .check)
        #expect(try ProbeOptions(arguments: ["--capture-default"]) == .captureDefault(seconds: 20))
        #expect(try ProbeOptions(arguments: ["--capture-clicks-default"]) == .captureClicksDefault(seconds: 20))
        #expect(try ProbeOptions(arguments: ["--capture-clicks-default", "--seconds", "30"]) == .captureClicksDefault(seconds: 30))
        for invalid in ["0", "31", "-1", "0.5"] {
            #expect(throws: ProbeOptions.InvalidArguments.self) {
                try ProbeOptions(arguments: ["--capture-clicks-default", "--seconds", invalid])
            }
        }
    }

    @Test func observerMaskContainsOnlyButtonPairs() {
        for type in [CGEventType.keyDown, .keyUp, .flagsChanged, .mouseMoved, .scrollWheel,
                     .leftMouseDragged, .rightMouseDragged, .otherMouseDragged] {
            #expect(PassiveButtonProbe.eventMask & (CGEventMask(1) << type.rawValue) == 0)
            #expect(PassiveButtonProbe.phase(for: type) == nil)
        }
        for type in [CGEventType.leftMouseDown, .rightMouseDown, .otherMouseDown] {
            #expect(PassiveButtonProbe.eventMask & (CGEventMask(1) << type.rawValue) != 0)
            #expect(PassiveButtonProbe.phase(for: type) == .down)
        }
        for type in [CGEventType.leftMouseUp, .rightMouseUp, .otherMouseUp] {
            #expect(PassiveButtonProbe.eventMask & (CGEventMask(1) << type.rawValue) != 0)
            #expect(PassiveButtonProbe.phase(for: type) == .up)
        }
    }

    @Test func proximityExpiresAndBackwardsTimeIsUnknown() {
        var buffer = ButtonObservations()
        buffer.updateContacts(4, at: 100)
        for time in [UInt64(100), 50_000_100, 50_000_101, 99] {
            buffer.observe(phase: .down, button: 0, pressure: 1, at: time)
        }
        #expect(buffer.records.map(\.nearbyContacts) == [4, 4, nil, nil])
        buffer.updateContacts(0, at: .max - 1)
        buffer.observe(phase: .up, button: 0, pressure: 0, at: .max)
        #expect(buffer.records.last?.nearbyContacts == 0)
    }

    @Test func recordCapacityIsBoundedWithoutReplacingEarlierObservations() {
        var buffer = ButtonObservations()
        for button in 0..<200 {
            buffer.observe(phase: .down, button: Int64(button), pressure: 1, at: 0)
        }
        #expect(buffer.records.count == 128 && buffer.omitted == 72 && buffer.observed == 200)
        #expect(buffer.records.first?.button == 0 && buffer.records.last?.button == 127)
    }

    @Test func stopClearsSensitiveTimingAndRecordsAndRejectsLaterCallbacks() {
        var buffer = ButtonObservations()
        buffer.markInstalled()
        buffer.updateContacts(3, at: 0)
        buffer.observe(phase: .down, button: 0, pressure: 1, at: 0)
        buffer.stop()
        buffer.observe(phase: .up, button: 0, pressure: 0, at: 1)
        #expect(buffer.installed && buffer.disabled && buffer.records.isEmpty && buffer.observed == 1)
    }

    @Test func malformedMetadataDoesNotEnterReport() {
        var buffer = ButtonObservations()
        for pressure in [Double.nan, .infinity, -1] {
            buffer.observe(phase: .down, button: 0, pressure: pressure, at: 0)
        }
        buffer.observe(phase: .down, button: -1, pressure: 1, at: 0)
        #expect(buffer.observed == 0 && buffer.records.isEmpty)
        buffer.updateContacts(17, at: 0)
        buffer.observe(phase: .down, button: 300, pressure: 1, at: 0)
        #expect(buffer.records.last?.nearbyContacts == nil && buffer.records.last?.button == 300)
    }

    @Test func serializedObservationCannotContainCoordinatesOrIdentity() throws {
        var buffer = ButtonObservations()
        buffer.updateContacts(3, at: 10)
        buffer.observe(phase: .down, button: 0, pressure: 1, at: 20)
        let record = try #require(buffer.records.first)
        let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as? [String: Any])
        #expect(Set(object.keys) == ["phase", "button", "pressure", "nearbyContacts", "elapsedMilliseconds"])
    }

    @Test func receiptTimesShareOneOriginAcrossCandidatesContactsAndButtons() throws {
        let origin: UInt64 = 9_000_000_000
        let clock = ProbeObservationClock(startedAt: origin)
        var buffer = ButtonObservations(clock: clock)
        buffer.updateContacts(0, at: origin + 136_000_000)
        buffer.observe(phase: .down, button: 0, pressure: 1, at: origin + 148_000_000)
        let candidate = CandidateObservation(.init(fingers: 3, durationMilliseconds: 136, peakPressure: 31),
                                             elapsedMilliseconds: clock.elapsedMilliseconds(at: origin + 136_000_000))
        let contact = ContactObservation(contacts: 0, elapsedMilliseconds: clock.elapsedMilliseconds(at: origin + 136_000_000))
        let button = try #require(buffer.records.first)
        #expect(candidate.elapsedMilliseconds == 136 && contact.elapsedMilliseconds == 136)
        #expect(button.elapsedMilliseconds == 148 && button.nearbyContacts == 0)
        // A button seen after a candidate is still reported, never used as an
        // automatic tap/click decision or discarded for having zero contacts.
        #expect(button.phase == .down && buffer.observed == 1)
        let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(candidate)) as? [String: Any])
        #expect(Set(object.keys) == ["fingers", "durationMilliseconds", "peakPressure", "elapsedMilliseconds"])
        let contactObject = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(contact)) as? [String: Any])
        #expect(Set(contactObject.keys) == ["contacts", "elapsedMilliseconds"])
    }

    @Test func receiptClockDoesNotUnderflowOrExposeItsAbsoluteOrigin() throws {
        let clock = ProbeObservationClock(startedAt: .max - 2_000_000)
        #expect(clock.elapsedMilliseconds(at: .max - 2_000_001) == nil)
        #expect(clock.elapsedMilliseconds(at: .max - 2_000_000) == 0)
        #expect(clock.elapsedMilliseconds(at: .max - 1) == 1)
        #expect(clock.elapsedMilliseconds(at: .max) == 2)
        var buffer = ButtonObservations(clock: clock)
        buffer.observe(phase: .down, button: 0, pressure: 1, at: .max - 2_000_001)
        let record = try #require(buffer.records.first)
        let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as? [String: Any])
        #expect(object["elapsedMilliseconds"] == nil)
        #expect(Set(object.keys) == ["phase", "button", "pressure"])
        #expect(buffer.observed == 1)
    }

    @Test func delayedContactConsumerIsNotReorderedToMatchButtonCallbacks() {
        let clock = ProbeObservationClock(startedAt: 1_000_000_000)
        var buffer = ButtonObservations(clock: clock)
        buffer.updateContacts(3, at: 1_020_000_000)
        buffer.observe(phase: .down, button: 0, pressure: 1, at: 1_010_000_000)
        buffer.observe(phase: .up, button: 0, pressure: 0, at: 1_150_000_000)
        #expect(buffer.records.map(\.elapsedMilliseconds) == [10, 150])
        #expect(buffer.records.map(\.nearbyContacts) == [nil, nil])
        buffer.stop()
        #expect(buffer.records.isEmpty)
    }

    @Test func cancellationKeepsCompletedReportButRefusesLateCallbacks() {
        var buffer = ButtonObservations()
        buffer.observe(phase: .down, button: 0, pressure: 1, at: 0)
        buffer.requestStop()
        buffer.observe(phase: .up, button: 0, pressure: 0, at: 1)
        #expect(buffer.records.count == 1 && buffer.observed == 1 && buffer.stopRequested)
    }

    @Test func preStoppedNativeThreadIsJoinedWithoutCreatingEventTap() async {
        let buffer = ButtonObservationBuffer()
        buffer.state.withLock { $0.requestStop() }
        let result = await PassiveButtonProbe.run(buffer: buffer, seconds: 1)
        #expect(result == "cancelled")
        #expect(buffer.state.withLock { $0.installed } == false)
    }

    @Test func callbackPassesOriginalEventAndIgnoresRebindTag() throws {
        let buffer = ButtonObservationBuffer()
        let taggedSource = try #require(CGEventSource(stateID: .privateState))
        taggedSource.userData = PassiveButtonProbe.rebindTag
        let event = try #require(CGEvent(mouseEventSource: taggedSource, mouseType: .leftMouseDown,
                                        mouseCursorPosition: .zero, mouseButton: .left))
        let context = Unmanaged.passUnretained(buffer).toOpaque()
        #expect(event.getIntegerValueField(.eventSourceUserData) == PassiveButtonProbe.rebindTag)
        let tagged = PassiveButtonProbe.receive(type: .leftMouseDown, event: event, context: context)
        #expect(tagged?.takeUnretainedValue() === event)
        #expect(buffer.state.withLock { $0.observed } == 0)
        // Setting the tagged event's field to zero did not clear its inherited
        // source value on this SDK. Use independently owned sources, as in real
        // tagged synthetic versus unrelated native events.
        let plainSource = try #require(CGEventSource(stateID: .privateState))
        plainSource.userData = 0
        let plain = try #require(CGEvent(mouseEventSource: plainSource, mouseType: .leftMouseDown,
                                        mouseCursorPosition: .zero, mouseButton: .left))
        #expect(plain.getIntegerValueField(.eventSourceUserData) == 0)
        let passed = PassiveButtonProbe.receive(type: .leftMouseDown, event: plain, context: context)
        #expect(passed?.takeUnretainedValue() === plain)
        #expect(buffer.state.withLock { $0.records.first?.button } == 0)
    }

    @Test func disabledCallbackClearsAndDoesNotRestart() throws {
        let buffer = ButtonObservationBuffer()
        buffer.state.withLock { $0.observe(phase: .down, button: 0, pressure: 1, at: 0) }
        let event = try #require(CGEvent(source: nil))
        let passed = PassiveButtonProbe.receive(type: .tapDisabledByTimeout, event: event, context: Unmanaged.passUnretained(buffer).toOpaque())
        #expect(passed?.takeUnretainedValue() === event)
        #expect(buffer.state.withLock { $0.disabled && $0.stopRequested && $0.records.isEmpty })
    }
}
