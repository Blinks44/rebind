import Foundation
import HIDPP
import Testing

private final class BatteryReply: HIDPPDeviceIO {
    let maxOutputReportSize: Int? = 20
    var payload: [UInt8] = []
    var answersWrite = false

    func performSynchronousOutputReportRequest(_ report: Data, timeout: TimeInterval,
                                               matching: @escaping (Data) -> Bool) -> Data? {
        let bytes = Array(report)
        if bytes[2] == 0x80, !answersWrite { return nil }
        let reply = Data(Array(bytes.prefix(4)) + payload + Array(repeating: UInt8(0), count: max(0, 16 - payload.count)))
        return matching(reply) ? reply : nil
    }
}

struct HIDPPReviewTests {
    @Test func aLongFeatureAtIndex41IsNotAReceiverConnectionNotice() {
        let gesture: [UInt8] = [0x11, 1, 0x41, 0, 0, 0xC3] + Array(repeating: 0, count: 14)
        #expect(ReceiverNotifications.isConnectionNotification(gesture) == false)
        #expect(ReprogControls.pressedControls(in: gesture, featureIndex: 0x41) == [ReprogControls.gestureButton])
        #expect(ReceiverNotifications.isConnectionNotification([0x10, 1, 0x41, 4, 0x31, 0, 0]))
        #expect(ReceiverNotifications.isConnectionNotification([0x10, 1, 0x41, 4, 0x71, 0, 0]))
        #expect(ReceiverNotifications.isConnectionNotification([0x10, 1, 0x41]) == false)
    }

    @Test func notificationEnableRequiresTheWriteAcknowledgement() {
        let io = BatteryReply()
        io.payload = [0, 0, 0]
        #expect(ReceiverNotifications.enable(on: io) == .refused)
        io.answersWrite = true
        #expect(ReceiverNotifications.enable(on: io) == .enabled)
    }

    @Test func adcBatteryUsesItsOwnConnectedAndChargingFlags() throws {
        let io = BatteryReply()
        let transport = try #require(HIDPPTransport(device: io, deviceIndex: 1))
        let battery = Battery(transport: transport, featureIndex: 2, source: .adcMeasurement)
        io.payload = [0x0F, 0x3C, 0x00]
        #expect(battery.status() == nil)
        io.payload[2] = 0x01
        #expect(battery.status() == .init(percentage: 62, isCharging: false))
        io.payload[2] = 0x03
        #expect(battery.status() == .init(percentage: 62, isCharging: true))
    }
}
