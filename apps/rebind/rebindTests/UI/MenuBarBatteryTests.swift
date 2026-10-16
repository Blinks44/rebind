import AppKit
import Testing
@testable import rebind

@MainActor struct MenuBarBatteryTests {
    private let rows: [(battery: DeviceBattery, name: String)] = [
        (DeviceBattery(id: "mouse", name: "MX Master 3S", kind: .mouse, percentage: 80, isCharging: true), "MX Master 3S"),
        (DeviceBattery(id: "keyboard", name: "G915 TKL", kind: .keyboard, percentage: 10, isCharging: false),
         String(repeating: "Клавиатура ", count: 6).trimmingCharacters(in: .whitespaces)),
    ]

    @Test(arguments: AppLanguage.allCases)
    func rowsShareOneRightAlignedColumnAfterTheLongestName(language: AppLanguage) throws {
        let items = MenuBarController.batteryItems(rows, language: language)
        let font = NSFont.menuFont(ofSize: 0)
        let longest = rows.map { ($0.name as NSString).size(withAttributes: [.font: font]).width }.max() ?? 0
        var locations = Set<CGFloat>()
        for (item, row) in zip(items, rows) {
            let title = try #require(item.attributedTitle)
            #expect(title.string.hasPrefix(row.name + "\t"))
            #expect(title.string.contains(AppLocalization.string(.batteryMenuLevel(row.battery.percentage), language: language)))
            #expect(title.attribute(.attachment, at: title.length - 1, effectiveRange: nil) is NSTextAttachment)
            let paragraph = try #require(title.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
            let stop = try #require(paragraph.tabStops.only)
            #expect(stop.alignment == .right)
            #expect(stop.location > longest)
            locations.insert(stop.location)
            #expect(item.image != nil)
            if #available(macOS 27, *) { #expect(item.preferredImageVisibility == .visible) }
        }
        #expect(locations.count == 1)
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

private extension Array {
    var only: Element? { count == 1 ? first : nil }
}
