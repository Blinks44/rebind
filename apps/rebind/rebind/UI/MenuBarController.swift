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
        model.refreshActionError()
        let language = model.activeLanguage
        func text(_ resource: LocalizedStringResource) -> String { AppLocalization.string(resource, language: language) }
        let configuration = model.configuration
        menu.removeAllItems()
        menu.addItem(Self.item(text(model.statusText), enabled: false))
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
        settings.keyEquivalent = ","
        settings.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
        if #available(macOS 27, *) { settings.preferredImageVisibility = .visible }
        menu.addItem(settings)

        let batteries = configuration.showsBatteryInMenu ? model.mouseHardware.batteries : []
        if !batteries.isEmpty {
            menu.addItem(.separator())
            menu.addItem(.sectionHeader(title: text(.batteryMenuTitle)))
            let rows = batteries.map { ($0, configuration.deviceName(for: $0.deviceKey, original: $0.name)) }
            for row in Self.batteryItems(rows, language: language) {
                row.action = #selector(openDevices)
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
        menu.addItem(item(text(.checkForUpdates), #selector(checkForUpdates),
                          enabled: RebindAppDelegate.updater.canCheckForUpdates))
        let quit = NSMenuItem(title: text(.quitRebind), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        // Measure the ordinary menu first: error text must never determine its width.
        if let error = model.error {
            menu.insertItem(Self.errorItem(text(error), textWidth: max(0, menu.size.width - 48)), at: 1)
        }
    }

    static func errorItem(_ message: String, textWidth: CGFloat) -> NSMenuItem {
        let font = NSFont.menuFont(ofSize: 0)
        // Keep a native menu item (including its disabled semantics), abbreviating only its
        // visible title. Character boundaries preserve composed characters in every language.
        var title = message.components(separatedBy: .newlines).joined(separator: " ")
        if (title as NSString).size(withAttributes: [.font: font]).width > textWidth {
            while !title.isEmpty && ((title + "…") as NSString).size(withAttributes: [.font: font]).width > textWidth {
                title.removeLast()
            }
            title += "…"
        }
        let item = Self.item(title, enabled: false)
        item.toolTip = message
        item.setAccessibilityLabel(message)
        return item
    }

    /// A full-width row lets the battery reach the same trailing inset as the DPI value.
    static func batteryItems(_ batteries: [(battery: DeviceBattery, name: String)], language: AppLanguage) -> [NSMenuItem] {
        batteries.map { row in
            let item = NSMenuItem(title: row.name, action: nil, keyEquivalent: "")
            let state = AppLocalization.string(row.battery.isCharging ? .devicesBatteryCharging(row.battery.percentage)
                                                   : .devicesBattery(row.battery.percentage), language: language)
            let label = "\(row.name), \(state)"
            item.setAccessibilityLabel(label)
            item.view = MenuBatteryView(battery: row.battery, name: row.name, language: language, accessibilityLabel: label)
            return item
        }
    }

    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        for row in menu.items {
            (row.view as? MenuBatteryView)?.isHighlighted = row === item
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

    @objc private func checkForUpdates() {
        RebindAppDelegate.updater.checkForUpdates()
    }

    @objc private func openMainWindow() {
        RebindAppDelegate.mainWindow.show()
    }

    @objc private func selectProfile(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? UUID { model.selectProfile(id) }
    }

    @objc private func toggleBindings() {
        model.setEnabled(!model.configuration.isEnabled)
    }

    @objc private func openSettingsWindow() { showSettings() }

    @objc private func openDevices() {
        model.requestedDestination = .devices
        openMainWindow()
    }

    private func showSettings() {
        model.requestedDestination = .settings(model.settingsSection)
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
                RebindAppDelegate.mainWindow.installSceneOpener {
                    openWindow(id: "main")
                }
            }
    }
}
