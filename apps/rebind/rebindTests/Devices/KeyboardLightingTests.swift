import Foundation
import Testing
@testable import rebind

struct KeyboardLightingTests {
    @Test(arguments: [nil, 0, 9, 10, 100] as [Int?], [true, false])
    func batteryTransitionsRestoreSavedColorAndBrightness(percentage: Int?, charging: Bool) {
        let settings = KeyboardLightingSettings(deviceKey: "046d:Test keyboard", brightness: 100,
                                                color: 0x123456, lowBattery: .blinkingRed)
        let output = settings.output(percentage: percentage, charging: charging, supportsBlinking: true)
        let low = percentage.map { $0 < 10 } == true && !charging
        #expect(output.color == (low ? 0xFF0000 : 0x123456))
        #expect(output.brightness == (low ? 25 : 100))
        #expect(output.breathing == low)
    }

    @Test func offAndKeepColorNeverActivateBatteryOverride() {
        var settings = KeyboardLightingSettings(deviceKey: "046d:Test keyboard", isEnabled: false,
                                                brightness: 100, color: 0x010203, lowBattery: .red)
        #expect(settings.output(percentage: 1, charging: false, supportsBlinking: true).brightness == 0)
        #expect(settings.output(percentage: 1, charging: false, supportsBlinking: true).color == 0x010203)
        settings.isEnabled = true
        settings.lowBattery = .keepColor
        #expect(settings.output(percentage: 1, charging: false, supportsBlinking: true).brightness == 100)
        #expect(settings.output(percentage: 1, charging: false, supportsBlinking: true).color == 0x010203)
    }

    @Test func configurationRoundTripAndLegacyMigrationPreserveRules() throws {
        var configuration = Configuration()
        configuration.keyboardLighting = [KeyboardLightingSettings(deviceKey: "046d:Test keyboard", color: 0xABCDEF)]
        try configuration.validate()
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
        let legacy = Configuration(schemaVersion: 45)
        let migrated = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(legacy)).migrated()
        #expect(migrated.keyboardLighting.isEmpty)
        #expect(migrated.profiles == legacy.profiles)
        configuration.schemaVersion = 45
        #expect(throws: ConfigurationError.invalid) { try configuration.migrated() }
    }

    @Test func rejectsDuplicateAndInvalidSettings() throws {
        var configuration = Configuration()
        let settings = KeyboardLightingSettings(deviceKey: "046d:Test keyboard")
        configuration.keyboardLighting = [settings, settings]
        #expect(throws: ConfigurationError.invalid) { try configuration.validate() }
        configuration.keyboardLighting = [KeyboardLightingSettings(deviceKey: "", brightness: 0, color: 0x1000000)]
        #expect(throws: ConfigurationError.invalid) { try configuration.validate() }
    }

    @Test func schema46MigratesLightingButRejectsNewBrightnessValues() throws {
        var legacy = Configuration(schemaVersion: 46)
        legacy.keyboardLighting = [KeyboardLightingSettings(deviceKey: "keyboard", brightness: 25, color: 0x112233)]
        let migrated = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(legacy)).migrated()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion)
        #expect(migrated.keyboardLighting == legacy.keyboardLighting)
        legacy.keyboardLighting[0].brightness = 13
        #expect(throws: ConfigurationError.invalid) { try legacy.migrated() }
    }

    @MainActor @Test func colorWellConvertsSRGBWithoutAlpha() throws {
        let value: UInt32 = 0x2080FF
        #expect(KeyboardLightingControls.rgb(KeyboardLightingControls.color(value)) == value)
    }

    @Test func measuredModelAndPortableBrightnessRangeAreIdentified() {
        #expect(KeyboardLighting.supportsDevice(named: "G915 TKL LIGHTSPEED Wireless RGB Mechanical Gaming Keyboard"))
        #expect(KeyboardLighting.supportsDevice(named: "G915 X LIGHTSPEED") == false)
        #expect(KeyboardLighting.supportsDevice(named: nil) == false)
        for value in KeyboardLightingSettings.brightnessValues {
            #expect(KeyboardLightingSettings(deviceKey: "keyboard", brightness: value).isValid)
        }
        for value in [0, 101] {
            #expect(KeyboardLightingSettings(deviceKey: "keyboard", brightness: value).isValid == false)
        }
    }
}
