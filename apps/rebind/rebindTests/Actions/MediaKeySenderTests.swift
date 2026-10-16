import AppKit
import IOKit.hidsystem
import Testing
@testable import rebind

struct MediaKeySenderTests {
    @Test(arguments: MediaAction.allCases)
    func constructsNativeAuxiliaryPairsWithExactCodesPhasesNoRepeatOrModifiers(_ action: MediaAction) throws {
        let pair = try #require(MediaKeySender.events(action))
        #expect(pair.count == 2)
        #expect(action.keyCode == [.playPause: 16, .nextTrack: 17, .previousTrack: 18, .brightnessUp: 2, .brightnessDown: 3][action])
        let sources = try pair.map { try #require(CGEventSource(event: $0)) }
        #expect(sources[0].sourceStateID == sources[1].sourceStateID)
        #expect(sources[0].sourceStateID != .hidSystemState && sources[0].sourceStateID != .combinedSessionState)
        for (index, event) in pair.enumerated() {
            let native = try #require(NSEvent(cgEvent: event))
            #expect(native.type == .systemDefined && event.type.rawValue == 14)
            #expect(native.subtype.rawValue == Int16(NX_SUBTYPE_AUX_CONTROL_BUTTONS))
            #expect(native.data1 >> 16 == action.keyCode)
            #expect((native.data1 >> 8) & 0xff == (index == 0 ? 10 : 11))
            #expect(native.data1 & 0xff == 0 && native.data2 == -1)
            #expect(event.flags.rawValue == UInt64(index == 0 ? 0xa00 : 0xb00))
            #expect(native.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty)
            #expect(event.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag)
        }
    }

    @Test func sanitizesInheritedModifiersAndTagsBothEvents() throws {
        let events = try #require(MediaKeySender.events(.playPause, make: { _, _ in
            let event = CGEvent(source: nil)
            event?.flags = [.maskCommand, .maskAlternate, .maskControl, .maskShift, .maskSecondaryFn]
            return event
        }))
        #expect(events.map { $0.flags.rawValue } == [0xa00, 0xb00])
        #expect(events.allSatisfy { $0.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag })
    }

    @Test func initialCancellationSkipsConstructionAndPosting() {
        var calls = 0
        #expect(MediaKeySender.perform(.playPause, canPerform: { false },
            build: { _ in calls += 1; return nil }, post: { _, _ in calls += 1 }) == .cancelled)
        #expect(calls == 0)
    }

    @Test(arguments: [0, 1, 2]) func sourceOrEitherEventFailureNeverPostsPartialPair(_ failure: Int) {
        var calls = 0, posts = 0
        let result = MediaKeySender.perform(.nextTrack, canPerform: { true }, build: { action in
            MediaKeySender.events(action, source: { failure == 0 ? nil : CGEventSource(stateID: .privateState) },
                make: { _, _ in
                    calls += 1
                    return calls == failure ? nil : CGEvent(source: nil)
                })
        }, post: { _, _ in posts += 1 })
        #expect(result == .unavailable && posts == 0)
    }

    @Test func cancellationDuringConstructionPreventsBothEvents() {
        var allowed = true, posts = 0
        #expect(MediaKeySender.perform(.previousTrack, canPerform: { allowed }, build: { action in
            allowed = false
            return MediaKeySender.events(action)
        }, post: { _, _ in posts += 1 }) == .cancelled)
        #expect(posts == 0)
    }

    @Test(arguments: MediaAction.allCases)
    func begunPairCompletesReleaseAtHIDTapAfterCancellation(_ action: MediaAction) throws {
        var allowed = true
        var posted: [CGEvent] = []
        let result = MediaKeySender.perform(action, canPerform: { allowed }, post: { event, location in
            #expect(location == .cghidEventTap)
            posted.append(event)
            allowed = false
        })
        #expect(result == .performed && posted.count == 2)
        let up = try #require(posted.last.flatMap { NSEvent(cgEvent: $0) })
        #expect((up.data1 >> 8) & 0xff == 11 && up.data1 >> 16 == action.keyCode)
    }

    @Test(arguments: SystemAction.allCases)
    func soundActionsPostTheSystemSoundKeyPairAtHIDTap(_ action: SystemAction) throws {
        #expect(action.keyCode == [.volumeUp: 0, .volumeDown: 1, .toggleMute: 7][action])
        var posted: [CGEvent] = []
        let result = MediaKeySender.perform(action, canPerform: { true }, post: { event, location in
            #expect(location == .cghidEventTap)
            posted.append(event)
        })
        #expect(result == .performed)
        let native = try posted.map { try #require(NSEvent(cgEvent: $0)) }
        #expect(native.map { $0.data1 } == [action.keyCode << 16 | 0xa00, action.keyCode << 16 | 0xb00])
        #expect(native.allSatisfy { $0.subtype.rawValue == Int16(NX_SUBTYPE_AUX_CONTROL_BUTTONS) })
        #expect(posted.allSatisfy { $0.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag })
        let cancelled = MediaKeySender.perform(action, canPerform: { false }, post: { _, _ in Issue.record("Posted") })
        #expect(cancelled == .cancelled)
    }
}
