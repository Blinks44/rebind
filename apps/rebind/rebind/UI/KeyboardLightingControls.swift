import AppKit
import SwiftUI

/// The shared-color controls from Sketch 66–69, composed inside the existing device card.
struct KeyboardLightingControls: View {
    let state: KeyboardLightingState
    let settings: KeyboardLightingSettings
    let battery: DeviceBattery?
    let failed: Bool
    let save: (KeyboardLightingSettings) -> Void

    private var lowBatteryActive: Bool {
        settings.isEnabled && settings.lowBattery != .keepColor
            && battery.map { $0.percentage < 10 && !$0.isCharging } == true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if state.isExperimental {
                Text(.lightingExperimental).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if state.supportsPower {
                Toggle(isOn: SwiftUI.Binding(get: { settings.isEnabled }, set: { value in
                    var updated = settings
                    updated.isEnabled = value
                    save(updated)
                })) { label(.lightingTitle, state.isExperimental ? .lightingDeviceDescription : .lightingDescription) }
                    .toggleStyle(ThemeSwitchStyle())
            }

            if settings.isEnabled || !state.supportsPower {
                if !state.brightnessValues.isEmpty {
                    SettingSlider(title: .lightingBrightness,
                                  description: state.isExperimental ? .lightingDeviceBrightnessDescription : .lightingBrightnessDescription,
                                  value: lowBatteryActive ? settings.brightness : max(1, state.brightness),
                                  values: state.brightnessValues, valueLabel: { .lightingPercentValue($0) }) { value in
                        var updated = settings
                        updated.brightness = value
                        save(updated)
                    }
                }
                HStack {
                    label(.lightingColor, state.isExperimental ? .lightingDeviceColorDescription : .lightingColorDescription)
                    ColorPicker(selection: SwiftUI.Binding(get: { Self.color(settings.color ?? 0x2CC7E7) }, set: { color in
                        guard let rgb = Self.rgb(color) else { return }
                        var updated = settings
                        updated.color = rgb
                        save(updated)
                    }), supportsOpacity: false) { Text(.lightingColor) }
                        .labelsHidden()
                        .accessibilityLabel(Text(.lightingColor))
                        .accessibilityValue(settings.color.map { String(format: "#%06X", $0) } ?? "")
                        .help(Text(state.isExperimental ? .lightingDeviceColorDescription : .lightingColorDescription))
                        .frame(width: 44)
                }
                if let policy = state.powerPolicy {
                    HStack {
                        label(.lightingIdleTitle, .lightingIdleDescription)
                        MenuSelector(selection: SwiftUI.Binding(get: { settings.idleTimeout }, set: { value in
                            var updated = settings
                            updated.idleTimeout = value
                            // Capture the device's own policy once, so Device default can restore it.
                            if value != nil, updated.devicePowerPolicy == nil { updated.devicePowerPolicy = policy }
                            save(updated)
                        }), title: .lightingIdleTitle, choices: [nil] + KeyboardLightingSettings.idleTimeouts,
                        label: Self.idleLabel)
                        .fixedSize()
                    }
                }
            }

            if battery != nil, state.supportsLowBattery {
                Theme.separator.frame(height: 1).padding(.vertical, 1)
                VStack(alignment: .leading, spacing: 12) {
                    label(.lightingLowBattery, lowBatteryActive ? .lightingLowBatteryActive : .lightingLowBatteryDescription)
                    SegmentedPicker(selection: SwiftUI.Binding(get: { settings.lowBattery }, set: { value in
                        var updated = settings
                        updated.lowBattery = value
                        save(updated)
                    }), title: .lightingLowBattery,
                    options: state.supportsBlinking ? KeyboardLightingSettings.LowBattery.allCases : [.keepColor, .red],
                    label: \.label, fillsWidth: true)
                }
            }
            if failed {
                Label(.lightingWriteFailed, systemImage: "exclamationmark.triangle")
                    .font(Theme.caption).foregroundStyle(Theme.warningText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func label(_ title: LocalizedStringResource, _ description: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.body).foregroundStyle(Theme.textPrimary)
            Text(description).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static func idleLabel(_ seconds: Int?) -> LocalizedStringResource {
        guard let seconds else { return .lightingIdleDeviceDefault }
        return seconds < 60 ? .lightingIdleSeconds(seconds) : .lightingIdleMinutes(seconds / 60)
    }

    static func color(_ rgb: UInt32) -> Color {
        Color(.sRGB, red: Double((rgb >> 16) & 255) / 255,
              green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255, opacity: 1)
    }

    static func rgb(_ color: Color) -> UInt32? {
        guard let value = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        let r = UInt32((min(max(value.redComponent, 0), 1) * 255).rounded())
        let g = UInt32((min(max(value.greenComponent, 0), 1) * 255).rounded())
        let b = UInt32((min(max(value.blueComponent, 0), 1) * 255).rounded())
        return r << 16 | g << 8 | b
    }
}

extension KeyboardLightingSettings.LowBattery {
    var label: LocalizedStringResource {
        switch self {
        case .keepColor: .lightingKeepColor
        case .red: .lightingRed
        case .blinkingRed: .lightingBlinkingRed
        }
    }
}
