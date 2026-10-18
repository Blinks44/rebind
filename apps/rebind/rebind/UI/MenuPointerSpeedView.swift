import AppKit

/// One mouse's pointer speed in the Menu Bar menu: its symbol, name and DPI above a slider, as
/// the system Sound menu shows a volume. The slider steps through the mouse's own DPI list
/// and hands the choice over once a drag ends, like the slider in Settings → Devices.
final class MenuPointerSpeedView: NSView {
    private let values: [Int]
    private let valueText: (Int) -> String
    private let commit: (Int) -> Void
    private let valueLabel = NSTextField(labelWithString: "")
    let slider = NSSlider()
    private var committed: Int

    /// `note` replaces the value while the slider is disabled for a reason the user can fix,
    /// such as a companion app that owns the mouse's settings.
    init(name: String, dpi: Int, values: [Int], enabled: Bool, note: String? = nil, accessibilityLabel: String,
         valueText: @escaping (Int) -> String, commit: @escaping (Int) -> Void) {
        self.values = values
        self.valueText = valueText
        self.commit = commit
        committed = values[SettingSlider.nearest(to: dpi, in: values)]
        super.init(frame: NSRect(x: 0, y: 0, width: 240, height: 48))
        autoresizingMask = .width

        let font = NSFont.menuFont(ofSize: 0)
        let icon = NSImageView(image: NSImage(systemSymbolName: DeviceBattery.Kind.mouse.symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(scale: .small)) ?? NSImage())
        icon.contentTintColor = enabled ? .labelColor : .disabledControlTextColor
        let nameLabel = NSTextField(labelWithString: name)
        nameLabel.font = font
        nameLabel.textColor = enabled ? .labelColor : .disabledControlTextColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.font = .monospacedDigitSystemFont(ofSize: font.pointSize, weight: .regular)
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.alignment = .right

        // No tick marks: a tick per value would draw a solid comb for a 12,000 DPI sensor.
        slider.minValue = 0
        slider.maxValue = Double(values.count - 1)
        slider.doubleValue = Double(values.firstIndex(of: committed) ?? 0)
        slider.isContinuous = true
        slider.isEnabled = enabled
        // A menu's window never becomes key, so the slider would draw its inactive gray fill.
        if enabled { slider.trackFillColor = .controlAccentColor }
        slider.target = self
        slider.action = #selector(sliderMoved)
        slider.setAccessibilityLabel(accessibilityLabel)

        for view in [icon, nameLabel, valueLabel, slider] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        // The insets of the menu's own items, so the name lines up with the battery names above.
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            valueLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),
            slider.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: valueLabel.trailingAnchor),
            slider.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
        show(committed)
        if let note {
            valueLabel.stringValue = note
            valueLabel.lineBreakMode = .byTruncatingTail
            // The name stays readable; a long note gives way first.
            valueLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
            slider.setAccessibilityHelp(note)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    var shownValue: Int { values[min(max(Int(slider.doubleValue.rounded()), 0), values.count - 1)] }

    @objc private func sliderMoved() {
        let value = shownValue
        show(value)
        // Arrow keys and scrolling change the value without a drag; a drag commits on release.
        if NSApp.currentEvent?.type != .leftMouseDragged, value != committed {
            committed = value
            commit(value)
        }
    }

    private func show(_ value: Int) {
        let text = valueText(value)
        valueLabel.stringValue = text
        slider.setAccessibilityValueDescription(text)
    }
}
