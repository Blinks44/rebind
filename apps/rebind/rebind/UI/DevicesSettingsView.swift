import SwiftUI

/// Connected mice and the hardware settings each one supports (Logitech HID++ for now).
struct DevicesSettingsView: View {
    let model: AppModel

    private var mice: [ConnectedMouse] { model.mouseHardware.mice }
    private var hasSettings: Bool { mice.contains { $0.hardware != nil } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.settingsDevices).font(Theme.headline).accessibilityAddTraits(.isHeader)
                    Text(.devicesDescription).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                // Only an app that rewrites these settings affects this tab (it also disables the controls).
                let controllers = model.mouseCompanionApps.filter(\.controlsHardwareSettings)
                if !controllers.isEmpty { CompanionBanner(apps: controllers) }
                if hasSettings {
                    ForEach(mice) { mouse in
                        MouseCard(mouse: mouse, stored: model.configuration.mouseHardware.first { $0.deviceKey == mouse.deviceKey },
                                  save: model.setMouseHardware)
                            .disabled(model.storageLocked || model.companionApps.controller(ofVendor: mouse.vendorID) != nil)
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

/// One mouse: its name, then a row for each setting it reports, or a short note when it has none.
private struct MouseCard: View {
    let mouse: ConnectedMouse
    let stored: MouseHardwareSettings?
    let save: (MouseHardwareSettings) -> Void

    private var settings: MouseHardwareSettings { stored ?? MouseHardwareSettings(deviceKey: mouse.deviceKey) }

    var body: some View {
        Card {
            if let hardware = mouse.hardware {
                VStack(alignment: .leading, spacing: 0) {
                    identity
                    if let mode = hardware.wheelMode {
                        separator
                        wheel(mode: mode, sensitivity: hardware.smartShiftSensitivity)
                    }
                    if let dpi = hardware.dpi {
                        separator
                        pointerSpeed(dpi: dpi, supported: hardware.supportedDPI)
                    }
                }
            } else {
                HStack(spacing: 16) {
                    identity
                    Spacer(minLength: 12)
                    Text(.devicesNoExtraSettings).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
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

    private func label(_ title: LocalizedStringResource, _ description: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.body).foregroundStyle(Theme.textPrimary)
            Text(description).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A setting chosen from the values a mouse accepts. The mouse is written once a drag ends,
/// not on every step of it; without a list of values only the current one is shown.
private struct SettingSlider: View {
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    let value: Int
    let values: [Int]
    var valueLabel: ((Int) -> LocalizedStringResource)?
    let commit: (Int) -> Void
    @State private var draft: Int?
    @State private var dragging = false

    private var shown: Int { draft ?? value }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Theme.body).foregroundStyle(Theme.textPrimary)
                Text(description).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let valueLabel {
                Text(valueLabel(shown)).font(Theme.callout).monospacedDigit().foregroundStyle(Theme.textSecondary)
            }
            if values.count > 1 {
                Slider(value: index, in: 0...Double(values.count - 1), step: 1) { editing in
                    dragging = editing
                    if !editing { send() }
                }
                .tint(Theme.accent)
                .frame(width: 240)
                .accessibilityLabel(Text(title))
                .accessibilityValue(Text(verbatim: String(shown)))
            }
        }
    }

    private var index: SwiftUI.Binding<Double> {
        SwiftUI.Binding(
            get: { Double(values.firstIndex(of: shown) ?? Self.nearest(to: shown, in: values)) },
            set: { position in
                draft = values[min(max(Int(position.rounded()), 0), values.count - 1)]
                // Arrow keys change the value without a drag.
                if !dragging { send() }
            })
    }

    private func send() {
        guard let sent = draft else { return }
        draft = nil
        if sent != value { commit(sent) }
    }

    static func nearest(to value: Int, in values: [Int]) -> Int {
        values.indices.min { abs(values[$0] - value) < abs(values[$1] - value) } ?? 0
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
