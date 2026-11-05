import AppKit
import Testing

@testable import rebind

@MainActor struct MenuBarBatteryTests {
    private let rows: [(battery: DeviceBattery, name: String)] = [
        (DeviceBattery(id: "mouse", name: "MX Master 3S", kind: .mouse, percentage: 80, isCharging: true), "MX Master 3S"),
        (
            DeviceBattery(id: "keyboard", name: "G915 TKL", kind: .keyboard, percentage: 10, isCharging: false),
            String(repeating: "Клавиатура ", count: 6).trimmingCharacters(in: .whitespaces)
        ),
    ]

    @Test(arguments: AppLanguage.allCases)
    func chargeFollowsTheMenuTrailingEdgeWhenWidened(language: AppLanguage) throws {
        let items = MenuBarController.batteryItems(rows, language: language)
        for (item, row) in zip(items, rows) {
            let view = try #require(item.view as? MenuBatteryView)
            let window = NSWindow(contentRect: view.frame, styleMask: [], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = view
            defer { window.close() }
            let width = view.frame.width
            for extra: CGFloat in [0, 120] {
                window.setContentSize(NSSize(width: width + extra, height: 24))
                view.layoutSubtreeIfNeeded()
                #expect(abs(view.batteryImage.frame.maxX - (view.bounds.maxX - 14)) < 0.5)
                #expect(
                    view.levelLabel.alignmentRect(forFrame: view.levelLabel.frame).minX >= view.nameLabel.alignmentRect(
                        forFrame: view.nameLabel.frame
                    ).maxX + 23.5)
                #expect(view.nameLabel.stringValue == row.name)
                #expect(
                    view.levelLabel.stringValue == AppLocalization.string(.batteryMenuLevel(row.battery.percentage), language: language))
                #expect(view.batteryImage.image != nil)
            }
            #expect(view.accessibilityRole() == .menuItem)
            #expect(view.accessibilityLabel() == item.accessibilityLabel())
        }
    }

    @Test func keyboardFocusRequiresASelectedRow() throws {
        let item = try #require(MenuBarController.batteryItems(rows, language: .en).first)
        let view = try #require(item.view as? MenuBatteryView)
        #expect(view.isHighlighted == false)
        #expect(view.acceptsFirstResponder == false)
        view.isHighlighted = true
        #expect(view.acceptsFirstResponder)
        view.isHighlighted = false
        #expect(view.acceptsFirstResponder == false)
    }

    @Test func accessiblePressPerformsTheEnclosingMenuAction() throws {
        let item = try #require(MenuBarController.batteryItems(rows, language: .en).first)
        let view = try #require(item.view as? MenuBatteryView)
        let menu = NSMenu()
        menu.autoenablesItems = false
        let target = BatteryMenuActionTarget()
        item.target = target
        item.action = #selector(BatteryMenuActionTarget.openDevices)
        menu.addItem(item)
        #expect(view.accessibilityPerformPress())
        #expect(target.calls == 1)
        item.isEnabled = false
        #expect(view.accessibilityPerformPress() == false)
        #expect(target.calls == 1)
    }

    @Test(arguments: AppLanguage.allCases)
    func accessibilityLabelNamesTheDeviceAndItsCharge(language: AppLanguage) {
        let items = MenuBarController.batteryItems(rows, language: language)
        let charging = AppLocalization.string(.devicesBatteryCharging(80), language: language)
        let level = AppLocalization.string(.devicesBattery(10), language: language)
        #expect(items[0].accessibilityLabel() == "MX Master 3S, \(charging)")
        #expect(items[1].accessibilityLabel() == "\(rows[1].name), \(level)")
    }
}

@MainActor private final class BatteryMenuActionTarget: NSObject {
    var calls = 0
    @objc func openDevices() { calls += 1 }
}
