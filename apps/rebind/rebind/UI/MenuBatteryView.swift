import AppKit

/// Full-width menu content, with the same 14 pt outer insets as the pointer-speed row.
/// The enclosing NSMenuItem retains its title and action for native keyboard selection.
final class MenuBatteryView: NSView {
    let nameLabel: NSTextField
    let levelLabel: NSTextField
    let batteryImage: NSImageView
    private let deviceImage: NSImageView
    private let low: Bool
    var isHighlighted = false {
        didSet {
            updateColors()
            needsDisplay = true
            if isHighlighted { window?.makeFirstResponder(self) }
        }
    }

    init(battery: DeviceBattery, name: String, language: AppLanguage, accessibilityLabel: String) {
        let font = NSFont.menuFont(ofSize: 0)
        nameLabel = NSTextField(labelWithString: name)
        levelLabel = NSTextField(labelWithString: AppLocalization.string(.batteryMenuLevel(battery.percentage), language: language))
        batteryImage = NSImageView(image: NSImage(systemSymbolName: battery.symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 16, weight: .regular)) ?? NSImage())
        deviceImage = NSImageView(image: NSImage(systemSymbolName: battery.kind.symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(scale: .small)) ?? NSImage())
        low = battery.percentage <= 15 && !battery.isCharging
        nameLabel.font = font
        levelLabel.font = font
        let nameWidth = nameLabel.intrinsicContentSize.width
        let levelWidth = levelLabel.intrinsicContentSize.width
        super.init(frame: NSRect(x: 0, y: 0, width: max(240, ceil(36 + nameWidth + 24 + levelWidth + 8 + 24 + 14)), height: 24))
        autoresizingMask = .width
        nameLabel.font = font
        levelLabel.font = font
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        levelLabel.alignment = .right
        for view in [deviceImage, nameLabel, levelLabel, batteryImage] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setAccessibilityElement(false)
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            deviceImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            deviceImage.widthAnchor.constraint(equalToConstant: 16),
            deviceImage.heightAnchor.constraint(equalToConstant: 16),
            deviceImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            levelLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 24),
            levelLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),
            batteryImage.leadingAnchor.constraint(equalTo: levelLabel.trailingAnchor, constant: 8),
            batteryImage.widthAnchor.constraint(equalToConstant: 24),
            batteryImage.heightAnchor.constraint(equalToConstant: 16),
            batteryImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            batteryImage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.menuItem)
        setAccessibilityLabel(accessibilityLabel)
        updateColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { isHighlighted = true }
    override func mouseExited(with event: NSEvent) { isHighlighted = false }
    override func mouseUp(with event: NSEvent) {
        if bounds.contains(convert(event.locationInWindow, from: nil)) { _ = accessibilityPerformPress() }
    }

    // Only accept keyboard focus after menu navigation selects this row. Otherwise AppKit
    // selects the first focusable custom row as soon as the menu opens.
    override var acceptsFirstResponder: Bool { isHighlighted }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 49, 76: _ = accessibilityPerformPress()
        default: super.keyDown(with: event)
        }
    }

    override func accessibilityPerformPress() -> Bool {
        guard let item = enclosingMenuItem, item.isEnabled, let menu = item.menu,
              let index = menu.items.firstIndex(of: item), item.action != nil else { return false }
        menu.cancelTracking()
        menu.performActionForItem(at: index)
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHighlighted {
            NSColor.selectedContentBackgroundColor.setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 5, dy: 0), xRadius: 4, yRadius: 4).fill()
        }
    }

    private func updateColors() {
        let primary: NSColor = isHighlighted ? .selectedMenuItemTextColor : .labelColor
        let secondary: NSColor = isHighlighted ? .selectedMenuItemTextColor : .secondaryLabelColor
        nameLabel.textColor = primary
        deviceImage.contentTintColor = primary
        levelLabel.textColor = low && !isHighlighted ? .systemRed : secondary
        batteryImage.contentTintColor = secondary
    }
}
