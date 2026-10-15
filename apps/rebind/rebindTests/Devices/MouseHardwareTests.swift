import Foundation
import HIDPP
import Testing
@testable import rebind

struct CompanionAppTests {
    private func running(_ processes: [(String?, String?)]) -> [String] {
        CompanionApp.running(in: processes.map { (bundleIdentifier: $0.0, executableName: $0.1) }).map(\.name)
    }

    @Test func recognizesTheAppsAndTheirHelpers() {
        #expect(running([("com.logi.optionsplus", "logioptionsplus")]) == ["Logi Options+"])
        #expect(running([(nil, "logioptionsplus_agent")]) == ["Logi Options+"])
        #expect(running([("com.logi.ghub.agent", "lghub_agent")]) == ["Logitech G HUB"])
        #expect(running([("com.logi.ghub", nil), ("com.logi.ghub.agent", nil),
                         ("com.logi.optionsplus.helper", nil)]) == ["Logi Options+", "Logitech G HUB"])
    }

    @Test func ignoresUnrelatedProcesses() {
        #expect(running([("com.logi.optionsplusfake", nil), ("com.apple.finder", "Finder"), (nil, nil)]).isEmpty)
    }
}

struct MouseHardwareSettingsTests {
    private let settings = MouseHardwareSettings(deviceKey: MouseHardwareSettings.deviceKey(vendorID: 0x046D, name: "MX Master 3S"),
                                                 wheelMode: .smartShift, smartShiftSensitivity: 12, dpi: 1600)

    @Test func storedSettingsRoundTripAndValidate() throws {
        #expect(settings.deviceKey == "046d:MX Master 3S")
        var configuration = Configuration()
        configuration.mouseHardware = [settings]
        try configuration.validate()
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
    }

    @Test func invalidOrDuplicateSettingsAreRejected() {
        var configuration = Configuration()
        var tooSensitive = settings
        tooSensitive.smartShiftSensitivity = 51
        configuration.mouseHardware = [tooSensitive]
        #expect(throws: ConfigurationError.invalid) { try configuration.validate() }
        configuration.mouseHardware = [settings, settings]
        #expect(throws: ConfigurationError.invalid) { try configuration.validate() }
    }

    @Test func anOlderFileCannotCarryMouseSettings() {
        var configuration = Configuration()
        configuration.mouseHardware = [settings]
        configuration.schemaVersion = 34
        #expect(throws: ConfigurationError.invalid) { try configuration.migrated() }
    }

    @Test func wheelChoicesMapToDeviceModes() {
        #expect(LogitechMouse.mode(for: settings) == .smartShift(threshold: 12))
        #expect(LogitechMouse.mode(for: MouseHardwareSettings(deviceKey: "k", wheelMode: .alwaysClick)) == .alwaysRatchet)
        #expect(LogitechMouse.mode(for: MouseHardwareSettings(deviceKey: "k", wheelMode: .alwaysFreeSpin)) == .freeSpin)
        #expect(LogitechMouse.mode(for: MouseHardwareSettings(deviceKey: "k", dpi: 800)) == nil)
        #expect(LogitechMouse.settings(for: .smartShift(threshold: 200), sensitivity: 10) == (.smartShift, 50))
        #expect(LogitechMouse.settings(for: .freeSpin, sensitivity: 7) == (.alwaysFreeSpin, 7))
    }
}

/// A HID++ 2.0 mouse with SmartShift (0x2110) and Adjustable DPI (0x2201) that records writes.
private final class MockMouse: HIDPPDeviceIO, @unchecked Sendable {
    let maxOutputReportSize: Int? = HIDPPConstants.longReportLength
    private(set) var writes: [[UInt8]] = []
    var mode: [UInt8] = [0x02, 16, 10]
    var dpi = 1000

    func performSynchronousOutputReportRequest(_ report: Data, timeout: TimeInterval,
                                               matching: @escaping (Data) -> Bool) -> Data? {
        let bytes = [UInt8](report)
        let function = bytes[3] >> 4
        var payload: [UInt8] = []
        switch (bytes[2], function) {
        case (0x00, 0):
            let features: [UInt16: UInt8] = [0x2110: 0x0E, 0x2201: 0x0F]
            payload = [features[UInt16(bytes[4]) << 8 | UInt16(bytes[5])] ?? 0]
        case (0x0E, 0): payload = mode
        case (0x0E, 1): mode = Array(bytes[4...6]); writes.append(Array(bytes[2...6]))
        case (0x0F, 1): payload = [0x00, 0x00, 0xC8, 0xE0, 0x32, 0x0F, 0xA0, 0x00, 0x00] // 200...4000 by 50
        case (0x0F, 2): payload = [0x00, UInt8(dpi >> 8), UInt8(dpi & 0xFF), 0x00, 0x00]
        case (0x0F, 3): dpi = Int(bytes[5]) << 8 | Int(bytes[6]); writes.append(Array(bytes[2...6]))
        default: return nil
        }
        let reply = Data(bytes[0...3] + payload + [UInt8](repeating: 0, count: max(0, 16 - payload.count)))
        return matching(reply) ? reply : nil
    }
}

struct LogitechMouseTests {
    @Test func readsAndWritesSmartShiftAndDPI() throws {
        let device = MockMouse()
        let mouse = try #require(LogitechMouse(io: device, slot: nil))
        let state = mouse.read()
        #expect(state.wheelMode == .smartShift && state.smartShiftSensitivity == 16 && state.dpi == 1000)
        #expect(state.supportedDPI.first == 200 && state.supportedDPI.last == 4000 && state.supportedDPI.count == 77)

        let applied = mouse.apply(MouseHardwareSettings(deviceKey: "k", wheelMode: .alwaysFreeSpin, dpi: 1610)) // nearest: 1600
        #expect(device.writes == [[0x0E, 0x18, 0x01, 0x00, 0x00], [0x0F, 0x38, 0x00, 0x06, 0x40]])
        #expect(applied.wheelMode == .alwaysFreeSpin && applied.dpi == 1600)
    }

    @Test func nothingIsWrittenForUnsetValues() throws {
        let device = MockMouse()
        let mouse = try #require(LogitechMouse(io: device, slot: nil))
        _ = mouse.apply(MouseHardwareSettings(deviceKey: "k"))
        #expect(device.writes.isEmpty)
    }
}

@MainActor struct CompanionLockTests {
    @Test func onlyAppsThatRewriteSettingsLockDevices() throws {
        let options = try #require(CompanionApp.known.first { $0.name == "Logi Options+" })
        let hub = try #require(CompanionApp.known.first { $0.name == "Logitech G HUB" })
        #expect(options.controlsHardwareSettings && !hub.controlsHardwareSettings)
    }
}

struct MouseHardwareExpectedStateTests {
    private let state = LogitechMouseState(name: "MX Master 2S", wheelMode: .smartShift, smartShiftSensitivity: 16,
                                           dpi: 1000, supportedDPI: [400, 800, 1000, 1600])

    @Test func aNewChoiceShowsAtOnceRoundedToWhatTheMouseAccepts() throws {
        let expected = try #require(MouseHardware.expected(state, after: MouseHardwareSettings(
            deviceKey: "k", wheelMode: .alwaysFreeSpin, smartShiftSensitivity: 20, dpi: 1500)))
        #expect(expected.wheelMode == .alwaysFreeSpin && expected.smartShiftSensitivity == 16 && expected.dpi == 1600)
        let sensitivity = try #require(MouseHardware.expected(state, after: MouseHardwareSettings(
            deviceKey: "k", wheelMode: .smartShift, smartShiftSensitivity: 30)))
        #expect(sensitivity.wheelMode == .smartShift && sensitivity.smartShiftSensitivity == 30 && sensitivity.dpi == 1000)
    }

    @Test func featuresTheMouseLacksStayAbsent() throws {
        let dpiOnly = LogitechMouseState(name: "M", dpi: 800, supportedDPI: [800, 1600])
        let expected = try #require(MouseHardware.expected(dpiOnly, after: MouseHardwareSettings(deviceKey: "k", wheelMode: .alwaysClick, dpi: 1600)))
        #expect(expected.wheelMode == nil && expected.dpi == 1600)
    }
}
