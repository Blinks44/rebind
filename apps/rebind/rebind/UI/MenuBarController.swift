import AppKit
import SwiftUI

/// The Menu Bar item and its menu. AppKit rather than `MenuBarExtra`: a SwiftUI menu drops tab
/// stops and, with the macOS 27 SDK, item images, so a battery row could not show its device
/// symbol and the charge at the right edge, the way the system's Bluetooth menu does.
final class MenuBarController: NSObject, NSMenuDelegate {
    private let model: AppModel
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var visibilityObservation: NSKeyValueObservation?

    init(model: AppModel) {
        self.model = model
        super.init()
        statusItem.autosaveName = "Rebind"
        statusItem.behavior = .removalAllowed
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu
        if let button = statusItem.button {
            button.setAccessibilityLabel("Rebind")
            button.addSubview(NSHostingView(rootView: SceneActions()))
        }
        update()
        // Command-dragging the icon out of the menu bar hides it; keep the preference in step.
        visibilityObservation = statusItem.observe(\.isVisible) { [weak self] _, _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.model.setPresencePreference(\.showsMenuBarIcon, to: self.statusItem.isVisible)
            }
        }
    }

    /// Shows the icon, paused while rules cannot run, and follows later changes.
    private func update() {
        withObservationTracking {
            statusItem.isVisible = model.configuration.showsMenuBarIcon
            statusItem.button?.image = NSImage(named: model.rulesAreRunning ? "RebindMenuBar" : "RebindMenuBarPaused")
        } onChange: { [weak self] in
            Task { @MainActor in self?.update() }
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let language = model.activeLanguage
        func text(_ resource: LocalizedStringResource) -> String { AppLocalization.string(resource, language: language) }
        let configuration = model.configuration
        menu.removeAllItems()
        menu.addItem(Self.item(text(model.statusText), enabled: false))
        // The window may be closed when an action fails; the menu is where it can still be seen.
        if let error = model.error { menu.addItem(Self.item(text(error), enabled: false)) }
        menu.addItem(item(text(.openRebind), #selector(openMainWindow)))

        let profiles = NSMenu()
        profiles.autoenablesItems = false
        for profile in configuration.profiles {
            let choice = item(profile.title, #selector(selectProfile(_:)), enabled: !model.storageLocked)
            choice.representedObject = profile.id
            choice.state = profile.id == configuration.selectedProfileID ? .on : .off
            profiles.addItem(choice)
        }
        let profile = Self.item(text(.profileTitle), enabled: !model.storageLocked)
        profile.submenu = profiles
        menu.addItem(profile)

        menu.addItem(item(text(configuration.isEnabled ? .pauseBindings : .resumeBindings), #selector(toggleBindings),
                          enabled: !(model.storageLocked && !configuration.isEnabled)))
        let settings = item(text(.settingsTitle), #selector(openSettingsWindow))
        settings.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        if #available(macOS 27, *) { settings.preferredImageVisibility = .visible }
        menu.addItem(settings)

        let batteries = configuration.showsBatteryInMenu ? model.mouseHardware.batteries : []
        if !batteries.isEmpty {
            menu.addItem(.separator())
            menu.addItem(.sectionHeader(title: text(.batteryMenuTitle)))
            let rows = batteries.map { ($0, configuration.deviceName(for: $0.deviceKey, original: $0.name)) }
            for row in Self.batteryItems(rows, language: language) {
                row.action = #selector(openDevicesSettings)
                row.target = self
                menu.addItem(row)
            }
        }
        let speeds = pointerSpeedItems(language: language)
        if !speeds.isEmpty {
            menu.addItem(.separator())
            menu.addItem(.sectionHeader(title: text(.devicesPointerSpeed)))
            speeds.forEach(menu.addItem)
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(title: text(.quitRebind), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    /// The device symbol, its name and, at the right edge, the charge and a battery symbol. One
    /// right-aligned tab stop after the longest name keeps the charges of all rows in a column.
    static func batteryItems(_ batteries: [(battery: DeviceBattery, name: String)], language: AppLanguage) -> [NSMenuItem] {
        let font = NSFont.menuFont(ofSize: 0)
        let rows = batteries.map { (battery: $0.battery, name: $0.name, charge: charge($0.battery, font: font, language: language)) }
        let nameWidth = rows.map { ($0.name as NSString).size(withAttributes: [.font: font]).width }.max() ?? 0
        let chargeWidth = rows.map { $0.charge.size().width }.max() ?? 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [NSTextTab(textAlignment: .right, location: (nameWidth + 24 + chargeWidth).rounded(.up))]

        return rows.map { row in
            let title = NSMutableAttributedString(string: row.name + "\t", attributes: [.font: font])
            title.append(row.charge)
            title.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: title.length))
            let item = NSMenuItem(title: row.name, action: nil, keyEquivalent: "")
            item.attributedTitle = title
            // The small scale keeps wide symbols (keyboard, trackpad) within the 16 pt menu image
            // slot, so the menu draws them at their own size instead of resampling them blurry.
            item.image = NSImage(systemSymbolName: row.battery.kind.symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(.init(scale: .small))
            if #available(macOS 27, *) { item.preferredImageVisibility = .visible }
            let state = AppLocalization.string(row.battery.isCharging ? .devicesBatteryCharging(row.battery.percentage)
                                                   : .devicesBattery(row.battery.percentage), language: language)
            item.setAccessibilityLabel("\(row.name), \(state)")
            return item
        }
    }

    /// A DPI slider for each connected mouse that reports a choice of DPI, saved and written as
    /// Settings → Devices does. Disabled while a companion app owns the mouse's settings.
    private func pointerSpeedItems(language: AppLanguage) -> [NSMenuItem] {
        let configuration = model.configuration
        return model.mouseHardware.mice.compactMap { mouse in
            guard let dpi = mouse.hardware?.dpi, let values = mouse.hardware?.supportedDPI, values.count > 1 else { return nil }
            let name = configuration.deviceName(for: mouse.deviceKey, original: mouse.name)
            let companion = model.companionApps.controller(ofVendor: mouse.vendorID, gaming: mouse.hardware?.hasOnboardProfiles ?? false)
            let title = AppLocalization.string(.devicesPointerSpeed, language: language)
            let view = MenuPointerSpeedView(
                name: name, dpi: dpi, values: values, enabled: !model.storageLocked && companion == nil,
                note: companion.map { AppLocalization.string(.companionRunningOne($0.name), language: language) },
                accessibilityLabel: "\(name), \(title)",
                valueText: { AppLocalization.string(.devicesDPIValue($0), language: language) },
                commit: { [model] value in
                    var settings = model.configuration.mouseHardware.first { $0.deviceKey == mouse.deviceKey }
                        ?? MouseHardwareSettings(deviceKey: mouse.deviceKey)
                    settings.dpi = value
                    model.setMouseHardware(settings)
                })
            let item = NSMenuItem()
            item.view = view
            return item
        }
    }

    /// "80%" and the matching battery symbol, the percentage red when the battery is low.
    private static func charge(_ battery: DeviceBattery, font: NSFont, language: AppLanguage) -> NSAttributedString {
        let low = battery.percentage <= 15 && !battery.isCharging
        let charge = NSMutableAttributedString(
            string: AppLocalization.string(.batteryMenuLevel(battery.percentage), language: language) + " ",
            attributes: [.font: font, .foregroundColor: low ? NSColor.systemRed : NSColor.secondaryLabelColor])
        let attachment = NSTextAttachment()
        let image = NSImage(systemSymbolName: battery.symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: font.pointSize, weight: .regular))
        attachment.image = image
        // Whole-point bounds centred on the cap height keep the symbol on the pixel grid.
        if let size = image?.size {
            attachment.bounds = CGRect(x: 0, y: ((font.capHeight - size.height) / 2).rounded(), width: size.width, height: size.height)
        }
        charge.append(NSAttributedString(attachment: attachment))
        charge.addAttribute(.font, value: font, range: NSRange(location: 0, length: charge.length))
        return charge
    }

    private func item(_ title: String, _ action: Selector, enabled: Bool = true) -> NSMenuItem {
        let item = Self.item(title, enabled: enabled)
        item.action = action
        item.target = self
        return item
    }

    private static func item(_ title: String, enabled: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = enabled
        return item
    }

    @objc private func openMainWindow() {
        RebindAppDelegate.showWindow { RebindAppDelegate.openMainWindow?() }
    }

    @objc private func selectProfile(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? UUID { model.selectProfile(id) }
    }

    @objc private func toggleBindings() {
        model.setEnabled(!model.configuration.isEnabled)
    }

    @objc private func openSettingsWindow() { showSettings() }

    @objc private func openDevicesSettings() {
        model.settingsSection = .devices
        showSettings()
    }

    private func showSettings() {
        model.requestedSettingsSection = model.settingsSection
        openMainWindow()
    }
}

/// Hands SwiftUI's window actions to AppKit. It lives in the Menu Bar button, which exists from
/// launch on, even when no window does.
private struct SceneActions: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
            .onAppear {
                RebindAppDelegate.openMainWindow = { openWindow(id: "main") }
            }
    }
}
