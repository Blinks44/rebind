import Foundation
import HIDPP
import Testing
@testable import rebind

private final class GestureMouse: HIDPPDeviceIO {
    let maxOutputReportSize: Int? = 20
    var acknowledgesWrites = true
    private(set) var writes: [Bool] = []

    func performSynchronousOutputReportRequest(_ report: Data, timeout: TimeInterval,
                                               matching: @escaping (Data) -> Bool) -> Data? {
        let bytes = Array(report)
        var payload: [UInt8]
        switch (bytes[2], bytes[3] >> 4) {
        case (0, 0):
            let features: [UInt16: UInt8] = [0x0005: 0x03, 0x1B04: 0x09]
            payload = [features[UInt16(bytes[4]) << 8 | UInt16(bytes[5])] ?? 0]
        case (0x03, 0): payload = [5]
        case (0x03, 1): payload = Array("Mouse".utf8)
        case (0x03, 2): payload = [3]
        case (0x09, 0): payload = [1]
        case (0x09, 1): payload = [0x00, 0xC3, 0x00, 0xC4, 0x30]
        case (0x09, 3):
            writes.append(bytes[6] & 0x01 != 0)
            guard acknowledgesWrites else { return nil }
            payload = Array(bytes[4...6])
        default: return nil
        }
        let reply = Data(Array(bytes.prefix(4)) + payload + Array(repeating: UInt8(0), count: 16 - payload.count))
        return matching(reply) ? reply : nil
    }
}

struct GestureButtonOwnershipTests {
    @Test func aRefreshRetainsTheDiversionOwedByAnOlderAdapterEvenWhenWritesBecomeBlocked() throws {
        let io = GestureMouse()
        let ownership = GestureButtonOwnership()
        let old = try #require(LogitechDevice(io: io, slot: 1, gestureOwnership: ownership))
        let refreshed = try #require(LogitechDevice(io: io, slot: 1, gestureOwnership: ownership))
        // An already-queued write can finish through the older adapter after the refresh.
        #expect(old.divertGestureButton(true))
        _ = refreshed.apply(MouseHardwareSettings(deviceKey: "mouse", usesGestureButton: true), canWrite: { false })
        #expect(io.writes == [true])
        #expect(refreshed.isGestureButtonDiverted)
        ownership.releaseAll()
        #expect(io.writes == [true, false])
        #expect(old.isGestureButtonDiverted == false && refreshed.isGestureButtonDiverted == false)
    }

    @Test func failedReleaseKeepsOwnershipForRetryAndOtherSlotsOrConnectionsDoNotInheritIt() throws {
        let io = GestureMouse()
        let ownership = GestureButtonOwnership()
        let mouse = try #require(LogitechDevice(io: io, slot: 1, gestureOwnership: ownership))
        let anotherSlot = try #require(LogitechDevice(io: io, slot: 2, gestureOwnership: ownership))
        let anotherConnection = try #require(LogitechDevice(io: io, slot: 1))
        #expect(mouse.divertGestureButton(true))
        #expect(anotherSlot.isGestureButtonDiverted == false && anotherConnection.isGestureButtonDiverted == false)
        io.acknowledgesWrites = false
        #expect(mouse.divertGestureButton(false) == false)
        #expect(mouse.isGestureButtonDiverted)
        ownership.releaseAll()
        #expect(mouse.isGestureButtonDiverted)
        io.acknowledgesWrites = true
        ownership.releaseAll()
        #expect(mouse.isGestureButtonDiverted == false)
    }

    @Test func cleanupIncludesAnAdapterThatHasNotBeenPublishedAndNoLongerExists() throws {
        let io = GestureMouse()
        let ownership = GestureButtonOwnership()
        do {
            let pending = try #require(LogitechDevice(io: io, slot: 1, gestureOwnership: ownership))
            #expect(pending.divertGestureButton(true))
        }
        ownership.releaseAll()
        #expect(io.writes == [true, false])
        #expect(ownership.contains(1) == false)
    }
}
