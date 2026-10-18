import Foundation
import Testing
@testable import rebind

@MainActor struct NativeTrackpadConnectionTests {
    @Test(arguments: TrackpadSingleTap.allCases, [false, true])
    func freshWrappersForOneConnectionPreserveSingleAndDoubleTaps(_ tap: TrackpadSingleTap, _ double: Bool) {
        let objects = [NSObject(), NSObject(), NSObject()]
        defer { withExtendedLifetime(objects) {} }
        let connections = objects.map {
            NativeTrackpadDevice.Connection(device: Unmanaged.passUnretained($0).toOpaque(), registryEntryID: 100)
        }
        let gesture: TrackpadTapGesture = double ? .double(tap) : .single(tap)
        let runtime = TrackpadRuntime(revision: 1, inputActivity: 0, isMagicTrackpad: true,
            actions: [gesture: .shortcut(.init(keyCode: 13, modifiers: .command))])
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        // Match the production discovery decision at two-second intervals. A wrapper
        // comparison restarts arming forever, even though native contacts still feed clicks.
        for index in 1..<connections.count {
            #expect(connections[index].device != connections[0].device)
            if connections[index] != connections[index - 1] {
                session = TrackpadTapSession(runtime: runtime, foreground: 100,
                                             startedAt: UInt64(index) * 2_000_000_000)
            }
        }
        var frameID: Int32 = 0
        func stroke(endingAt end: UInt64) {
            for (offset, count) in [0, tap.rawValue, tap.rawValue, 0].enumerated() {
                let receipt = end - UInt64(3 - offset) * 20_000_000
                var frame = NativeTrackpadFrame(receipt: receipt, revision: 1, activity: 0,
                    frame: frameID, time: Double(receipt) / 1_000_000_000, count: count)
                frameID += 1
                if count > 0 { frame.first = .init(id: 0, x: 0.3, y: 0.5, pressure: 0) }
                if count > 1 { frame.second = .init(id: 1, x: 0.4, y: 0.5, pressure: 0) }
                if count > 2 { frame.third = .init(id: 2, x: 0.5, y: 0.5, pressure: 0) }
                if count > 3 { frame.fourth = .init(id: 3, x: 0.6, y: 0.5, pressure: 0) }
                session.consume(frame, at: receipt)
            }
        }
        stroke(endingAt: 4_100_000_000)
        if double {
            #expect(session.takeReadyGesture(at: 4_160_000_000) == nil)
            frameID += 50 // Native streams skip frame IDs while no finger is down.
            stroke(endingAt: 4_350_000_000)
        }
        let release: UInt64 = double ? 4_350_000_000 : 4_100_000_000
        #expect(session.takeReadyGesture(at: release + 59_999_999) == nil)
        #expect(session.takeReadyGesture(at: release + 60_000_000) == gesture)
        #expect(session.takeReadyGesture(at: release + 70_000_000) == nil)
    }

    @Test func replacementServiceIsANewConnectionEvenIfAWrapperAddressRepeats() {
        let object = NSObject()
        let pointer = Unmanaged.passUnretained(object).toOpaque()
        let old = NativeTrackpadDevice.Connection(device: pointer, registryEntryID: 100)
        let replacement = NativeTrackpadDevice.Connection(device: pointer, registryEntryID: 101)
        #expect(old != replacement)
        withExtendedLifetime(object) {}
    }
}
