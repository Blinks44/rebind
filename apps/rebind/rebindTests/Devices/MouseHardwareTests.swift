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

    @Test func launchdHelpersAreNamedByTheirEnclosingBundle() {
        #expect(CompanionAppMonitor.bundleIdentifier(ofExecutable: "/System/Applications/Calculator.app/Contents/MacOS/Calculator")
                == "com.apple.calculator")
        #expect(CompanionAppMonitor.bundleIdentifier(ofExecutable: "/usr/bin/true") == nil)
        #expect(CompanionAppMonitor.bundleIdentifier(ofExecutable: "/nonexistent/X.app/Contents/MacOS/X") == nil)
        // G HUB's launchd tray helper sits in the main bundle; its updater's crash handler in the updater's.
        #expect(running([("com.logi.ghub", "lghub_system_tray")]) == ["Logitech G HUB"])
        #expect(running([("com.logi.ghub.updater", "logi_crashpad_handler")]).isEmpty)
    }

    @MainActor @Test func theProcessScanSeesBackgroundProcesses() {
        // This test process is not a Launch Services app, yet the scan must not come up empty.
        let monitor = CompanionAppMonitor()
        monitor.setConnectedVendors([0x046D])
        monitor.refresh()
        #expect(monitor.running.allSatisfy { CompanionApp.known.contains($0) })
    }

    @Test func theGHubUpdaterAloneIsNotGHub() {
        #expect(running([("com.logi.ghub.updater", "lghub_updater")]).isEmpty)
        #expect(running([("com.logi.ghub.updater", nil), ("com.logi.ghub.agent", nil)]) == ["Logitech G HUB"])
    }

    @MainActor @Test func scansOnlyForConnectedVendorsAndChecksBeforeHardwareWrites() {
        var scans = 0
        var changes = 0
        let monitor = CompanionAppMonitor(executablePaths: {
            scans += 1
            return ["/test/Contents/MacOS/logioptionsplus_agent"]
        })
        monitor.changed = { changes += 1 }
        monitor.refresh()
        monitor.setConnectedVendors([0x05AC])
        #expect(scans == 0)
        monitor.setConnectedVendors([0x046D, 0x05AC])
        #expect(scans == 1)
        #expect(monitor.controller(ofVendor: 0x046D)?.name == "Logi Options+")
        monitor.setConnectedVendors([0x046D])
        #expect(scans == 1) // Same relevant vendor, another HID interface is not a new scan.
        monitor.setConnectedVendors([])
        monitor.refresh()
        #expect(scans == 1)
        #expect(monitor.running.isEmpty)
        #expect(changes == 2)
        monitor.setConnectedVendors([0x046D])
        #expect(scans == 2) // Reconnect rechecks the helper before settings can be applied.
        #expect(monitor.controller(ofVendor: 0x046D, gaming: true) != nil)
    }
}

struct ProbeOrderTests {
    @Test func aSlotThatJustConnectedIsAskedFirst() {
        #expect(MouseHardware.probeOrder(first: nil) == [1, 2, 3, 4, 5, 6])
        #expect(MouseHardware.probeOrder(first: 3) == [3, 1, 2, 4, 5, 6])
        #expect(MouseHardware.probeOrder(first: 0xFF) == [1, 2, 3, 4, 5, 6])
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
        #expect(LogitechDevice.mode(for: settings) == .smartShift(threshold: 12))
        #expect(LogitechDevice.mode(for: MouseHardwareSettings(deviceKey: "k", wheelMode: .alwaysClick)) == .alwaysRatchet)
        #expect(LogitechDevice.mode(for: MouseHardwareSettings(deviceKey: "k", wheelMode: .alwaysFreeSpin)) == .freeSpin)
        #expect(LogitechDevice.mode(for: MouseHardwareSettings(deviceKey: "k", dpi: 800)) == nil)
        #expect(LogitechDevice.settings(for: .smartShift(threshold: 200), sensitivity: 10) == (.smartShift, 50))
        #expect(LogitechDevice.settings(for: .freeSpin, sensitivity: 7) == (.alwaysFreeSpin, 7))
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
    @Test func aCompanionAppStartingDuringARequestPreventsLaterWrites() throws {
        let device = MockMouse()
        let mouse = try #require(LogitechDevice(io: device, slot: nil))
        _ = mouse.apply(MouseHardwareSettings(deviceKey: "k", wheelMode: .alwaysFreeSpin, dpi: 1600),
                        canWrite: { device.writes.isEmpty })
        // Only the first write (pointer speed) went out; the wheel mode was never written.
        #expect(device.writes.count == 1)
        #expect(device.dpi == 1600 && device.mode == [0x02, 16, 10])
        let access = DeviceWriteAccess()
        access.update(standard: true, gaming: false)
        #expect(access.allows(gaming: false) && access.allows(gaming: true) == false)
        access.update(standard: false, gaming: false)
        #expect(access.allows(gaming: false) == false)
    }

    @Test func aQueuedWriteCannotRegainAuthorizationAfterARefreshOrCompanionRestart() {
        let access = DeviceWriteAccess()
        access.update(standard: true, gaming: true)
        let queued = access.revision
        access.update(standard: false, gaming: false)
        access.update(standard: true, gaming: true)
        #expect(!access.allows(gaming: false, revision: queued))
        let refreshed = access.revision
        #expect(access.allows(gaming: true, revision: refreshed))
        access.invalidate()
        #expect(!access.allows(gaming: true, revision: refreshed))
    }

    @Test func readsAndWritesSmartShiftAndDPI() throws {
        let device = MockMouse()
        let mouse = try #require(LogitechDevice(io: device, slot: nil))
        let state = mouse.read()
        #expect(state.wheelMode == .smartShift && state.smartShiftSensitivity == 16 && state.dpi == 1000)
        #expect(state.supportedDPI.first == 200 && state.supportedDPI.last == 4000 && state.supportedDPI.count == 77)

        let applied = mouse.apply(MouseHardwareSettings(deviceKey: "k", wheelMode: .alwaysFreeSpin, dpi: 1610)) // nearest: 1600
        // Pointer speed first: a mouse that just connected moves at its own speed until then.
        #expect(device.writes == [[0x0F, 0x38, 0x00, 0x06, 0x40], [0x0E, 0x18, 0x01, 0x00, 0x00]])
        #expect(applied.wheelMode == .alwaysFreeSpin && applied.dpi == 1600)
    }

    @Test func nothingIsWrittenForUnsetValues() throws {
        let device = MockMouse()
        let mouse = try #require(LogitechDevice(io: device, slot: nil))
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
    private let state = LogitechDeviceState(name: "MX Master 2S", wheelMode: .smartShift, smartShiftSensitivity: 16,
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
        let dpiOnly = LogitechDeviceState(name: "M", dpi: 800, supportedDPI: [800, 1600])
        let expected = try #require(MouseHardware.expected(dpiOnly, after: MouseHardwareSettings(deviceKey: "k", wheelMode: .alwaysClick, dpi: 1600)))
        #expect(expected.wheelMode == nil && expected.dpi == 1600)
    }
}

@MainActor struct GamingMouseLockTests {
    @Test func gHubLocksOnlyGamingMiceAndOptionsPlusLocksAll() {
        let monitor = CompanionAppMonitor()
        let hub = CompanionApp.known.first { $0.name == "Logitech G HUB" }
        let options = CompanionApp.known.first { $0.name == "Logi Options+" }
        #expect(hub?.managesGamingMice == true && options?.controlsHardwareSettings == true)
        #expect(monitor.controller(ofVendor: 0x046D, gaming: true) == nil)
    }
}

/// A HID++ keyboard with only a battery: it is kept for its charge and never written to.
private final class MockKeyboard: HIDPPDeviceIO, @unchecked Sendable {
    let maxOutputReportSize: Int? = HIDPPConstants.longReportLength
    private(set) var writes = 0
    private(set) var featureQueries: [UInt16] = []
    var kind: UInt8? = 0

    func performSynchronousOutputReportRequest(_ report: Data, timeout: TimeInterval,
                                               matching: @escaping (Data) -> Bool) -> Data? {
        let bytes = [UInt8](report)
        var payload: [UInt8] = []
        switch (bytes[2], bytes[3] >> 4) {
        case (0x00, 0):
            featureQueries.append(UInt16(bytes[4]) << 8 | UInt16(bytes[5]))
            let features: [UInt16: UInt8] = [0x0005: 0x03, 0x1004: 0x05]
            payload = [features[UInt16(bytes[4]) << 8 | UInt16(bytes[5])] ?? 0]
        case (0x03, 0): payload = [4]
        case (0x03, 1): payload = Array("G915".utf8)
        case (0x03, 2):
            guard let kind else { return nil }
            payload = [kind]
        case (0x05, 1): payload = [45, 0x04, 0x00]
        default: writes += 1; return nil
        }
        let reply = Data(bytes[0...3] + payload + [UInt8](repeating: 0, count: max(0, 16 - payload.count)))
        return matching(reply) ? reply : nil
    }
}

struct LogitechKeyboardTests {
    @Test func aKeyboardWithoutLightingRetainsBatteryOnlyBehavior() throws {
        let keyboard = MockKeyboard()
        let device = try #require(LogitechDevice(io: keyboard, slot: 2))
        #expect(device.isKeyboard)
        let state = device.read()
        #expect(state.isKeyboard && state.name == "G915" && state.batteryPercentage == 45 && !state.hasSettings)
        _ = device.apply(MouseHardwareSettings(deviceKey: "k", dpi: 1600, usesGestureButton: true))
        #expect(device.isGestureButtonDiverted == false)
        #expect(keyboard.featureQueries == [0x0005, 0x1004, 0x8071])
        #expect(keyboard.writes == 0)
    }

    @Test(arguments: [UInt8?(1), 4, 7, 255, nil])
    func nonInputAndUnknownTypesStopBeforeBatteryAndMouseQueries(_ kind: UInt8?) {
        let io = MockKeyboard()
        io.kind = kind
        #expect(LogitechDevice(io: io, slot: 1) == nil)
        #expect(io.featureQueries == [0x0005])
    }
}
