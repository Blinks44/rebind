import AppKit
import SwiftUI

/// The Menu Bar item and its menu. AppKit rather than `MenuBarExtra`: a SwiftUI menu drops tab
/// stops and, with the macOS 27 SDK, item images, so a battery row could not show its device
/// symbol and the charge at the right edge, the way the system's Bluetooth menu does.
final class MenuBarController: NSObject, NSMenuDelegate {
    private let model: AppModel
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var visibilityObservation: NSKeyValueObservation?
    /// Set by `SceneActions`, which has SwiftUI's environment.
    fileprivate var openSettings: (() -> Void)?

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
            button.addSubview(NSHostingView(rootView: SceneActions(controller: self)))
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
        menu.addItem(item(text(.settingsTitle), #selector(openSettingsWindow)))

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
            item.image = NSImage(systemSymbolName: row.battery.kind.symbol, accessibilityDescription: nil)
            if #available(macOS 27, *) { item.preferredImageVisibility = .visible }
            let state = AppLocalization.string(row.battery.isCharging ? .devicesBatteryCharging(row.battery.percentage)
                                                   : .devicesBattery(row.battery.percentage), language: language)
            item.setAccessibilityLabel("\(row.name), \(state)")
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
        attachment.image = NSImage(systemSymbolName: battery.symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: font.pointSize, weight: .regular))
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
        RebindAppDelegate.showWindow { [openSettings] in openSettings?() }
    }
}

/// Hands SwiftUI's window actions to AppKit. It lives in the Menu Bar button, which exists from
/// launch on, even when no window does.
private struct SceneActions: View {
    let controller: MenuBarController
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
            .onAppear {
                RebindAppDelegate.openMainWindow = { openWindow(id: "main") }
                controller.openSettings = { openSettings() }
            }
    }
}
