import SwiftUI

/// Connected mice: smooth scrolling for each, plus the hardware settings a Logitech mouse reports.
struct DevicesSettingsView: View {
    let model: AppModel

    private var mice: [ConnectedMouse] { model.mouseHardware.mice }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.settingsDevices).font(Theme.headline).accessibilityAddTraits(.isHeader)
                    Text(.devicesDescription).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                // Only an app that rewrites these settings affects this tab (it also disables the controls).
                let controllers = Set(mice.compactMap { controller(of: $0) })
                if !controllers.isEmpty { CompanionBanner(apps: CompanionApp.known.filter(controllers.contains)) }
                if !mice.isEmpty {
                    ForEach(mice) { mouse in
                        MouseCard(mouse: mouse, stored: model.configuration.mouseHardware.first { $0.deviceKey == mouse.deviceKey },
                                  hardwareLocked: controller(of: mouse) != nil,
                                  save: model.setMouseHardware)
                            .disabled(model.storageLocked)
                    }
                } else {
                    emptyState.frame(maxWidth: .infinity).padding(.top, 88)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .detailMargins().padding(.bottom, 32)
        }
        .onAppear { model.mouseHardware.refresh() }
    }

    private func controller(of mouse: ConnectedMouse) -> CompanionApp? {
        model.companionApps.controller(ofVendor: mouse.vendorID, gaming: mouse.hardware?.hasOnboardProfiles ?? false)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Image(systemName: "computermouse").font(.system(size: 24, weight: .medium)).foregroundStyle(Theme.accent)
                .frame(width: 56, height: 56)
                .background(Theme.accentTint, in: .rect(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)
            Text(.devicesEmptyTitle).font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                .padding(.top, 20)
            Text(.devicesEmptyDescription).font(Theme.body).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center).frame(maxWidth: 420).padding(.top, 8)
        }
    }
}

/// One mouse: its name and battery, the hardware settings it reports, then smooth scrolling.
private struct MouseCard: View {
    let mouse: ConnectedMouse
    let stored: MouseHardwareSettings?
    /// A companion app rewrites the hardware settings; smooth scrolling is Rebind's own.
    let hardwareLocked: Bool
    let save: (MouseHardwareSettings) -> Void

    private var settings: MouseHardwareSettings { stored ?? MouseHardwareSettings(deviceKey: mouse.deviceKey) }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                identity
                if let hardware = mouse.hardware {
                    Group {
                        if let mode = hardware.wheelMode {
                            separator
                            wheel(mode: mode, sensitivity: hardware.smartShiftSensitivity)
                        }
                        if let enabled = hardware.highResolutionWheel {
                            separator
                            toggle(.devicesHighResolutionWheel, .devicesHighResolutionWheelDescription, isOn: enabled) {
                                var updated = settings
                                updated.highResolutionWheel = $0
                                save(updated)
                            }
                        }
                        if let dpi = hardware.dpi {
                            separator
                            pointerSpeed(dpi: dpi, supported: hardware.supportedDPI)
                        }
                        if hardware.hasGestureButton {
                            separator
                            toggle(.devicesGestureButton, .devicesGestureButtonDescription,
                                   isOn: settings.usesGestureButton == true) {
                                var updated = settings
                                updated.usesGestureButton = $0
                                save(updated)
                            }
                        }
                    }
                    .disabled(hardwareLocked)
                }
                separator
                smoothScrolling
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var separator: some View { Theme.separator.frame(height: 1).padding(.vertical, 16) }

    private var identity: some View {
        HStack(spacing: 12) {
            Image(systemName: "computermouse").font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.iconSecondary)
                .frame(width: 32, height: 32).insetSurface(cornerRadius: 10).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: mouse.name).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if !subtitle.isEmpty {
                    Text(verbatim: subtitle).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer(minLength: 12)
            if let hardware = mouse.hardware, let percentage = hardware.batteryPercentage {
                let charging = hardware.batteryCharging
                Label {
                    Text(charging ? .devicesBatteryCharging(percentage) : .devicesBattery(percentage))
                } icon: {
                    Image(systemName: DeviceBattery(id: "", name: "", kind: .mouse, percentage: percentage,
                                                    isCharging: charging).symbol)
                }
                .font(Theme.callout).foregroundStyle(percentage <= 15 && !charging ? Theme.warningText : Theme.textSecondary)
            }
        }
    }

    private var subtitle: String {
        let transport: LocalizedStringResource? = switch mouse.transport {
        case .bluetooth: .devicesTransportBluetooth
        case .usb: .devicesTransportUSB
        case .receiver: .devicesTransportReceiver
        case .other: nil
        }
        return [mouse.manufacturer, transport.map { AppLocalization.string($0) }].compactMap { $0 }.joined(separator: " · ")
    }

    @ViewBuilder private var smoothScrolling: some View {
        toggle(.smoothScrollingTitle, .smoothScrollingDescription, isOn: settings.smoothScrolling == true) {
            var updated = settings
            updated.smoothScrolling = $0
            save(updated)
        }
        if settings.smoothScrolling == true {
            SettingSlider(title: .smoothScrollingDistance,
                          description: .smoothScrollingDistanceDescription(SmoothScrollingDistance.standard),
                          value: settings.smoothScrollingDistance ?? SmoothScrollingDistance.standard,
                          values: Array(stride(from: SmoothScrollingDistance.range.lowerBound,
                                               through: SmoothScrollingDistance.range.upperBound,
                                               by: SmoothScrollingDistance.step)),
                          valueLabel: { .smoothScrollingDistanceValue($0) }) { value in
                var updated = settings
                updated.smoothScrollingDistance = value
                save(updated)
            }
            .padding(.top, 16)
            VStack(alignment: .leading, spacing: 8) {
                Text(.smoothScrollingGlide).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                SegmentedPicker(selection: SwiftUI.Binding(get: { settings.smoothScrollingGlide ?? .standard }, set: {
                                    var updated = settings
                                    updated.smoothScrollingGlide = $0
                                    save(updated)
                                }),
                                title: .smoothScrollingGlide, options: SmoothScrollingGlide.allCases, label: \.label,
                                fillsWidth: true)
            }
            .padding(.top, 16)
        }
    }

    @ViewBuilder private func wheel(mode: WheelMode, sensitivity: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            label(.devicesScrollWheel, .devicesScrollWheelDescription)
            SegmentedPicker(selection: SwiftUI.Binding(get: { mode }, set: { mode in
                                var updated = settings
                                updated.wheelMode = mode
                                updated.smartShiftSensitivity = updated.smartShiftSensitivity ?? sensitivity
                                save(updated)
                            }),
                            title: .devicesScrollWheel, options: WheelMode.allCases, label: \.label, fillsWidth: true)
        }
        if mode == .smartShift {
            SettingSlider(title: .devicesSmartShiftSensitivity, description: .devicesSmartShiftSensitivityDescription,
                          value: sensitivity, values: Array(MouseHardwareSettings.sensitivityRange)) { value in
                var updated = settings
                updated.wheelMode = .smartShift
                updated.smartShiftSensitivity = value
                save(updated)
            }
            .padding(.top, 16)
        }
    }

    private func pointerSpeed(dpi: Int, supported: [Int]) -> some View {
        SettingSlider(title: .devicesPointerSpeed, description: .devicesPointerSpeedDescription, value: dpi,
                      values: supported, valueLabel: { .devicesDPIValue($0) }) { value in
            var updated = settings
            updated.dpi = value
            save(updated)
        }
    }

    private func toggle(_ title: LocalizedStringResource, _ description: LocalizedStringResource, isOn: Bool,
                        set: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: SwiftUI.Binding(get: { isOn }, set: set)) { label(title, description) }
            .toggleStyle(ThemeSwitchStyle())
    }

    private func label(_ title: LocalizedStringResource, _ description: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.body).foregroundStyle(Theme.textPrimary)
            Text(description).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension SmoothScrollingGlide {
    var label: LocalizedStringResource {
        switch self {
        case .short: .glideShort
        case .standard: .glideStandard
        case .long: .glideLong
        }
    }
}

extension WheelMode {
    var label: LocalizedStringResource {
        switch self {
        case .smartShift: .wheelModeSmartShift
        case .alwaysClick: .wheelModeAlwaysClick
        case .alwaysFreeSpin: .wheelModeAlwaysFreeSpin
        }
    }
}
