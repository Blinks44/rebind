import SwiftUI

/// Raised keycap. Short glyphs use the 16 pt rounded face; named keys and buttons use 12 pt.
struct Keycap: View {
    let label: String

    private var isGlyph: Bool { label.count <= 3 }

    var body: some View {
        Text(label)
            .font(.system(size: isGlyph ? 16 : 12, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.keycapText)
            .lineLimit(1)
            .padding(.horizontal, isGlyph ? 10 : 14)
            .frame(minWidth: 36).frame(height: 36)
            .keycapSurface()
    }
}

/// Keycap for a trigger that is not a keyboard key; the leading symbol names the input type
/// (mouse button, direction or touch).
struct TriggerChip: View {
    let label: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.iconSecondary).frame(width: 16, height: 16)
            Text(label).font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.keycapText).lineLimit(1)
        }
        .padding(.leading, 12).padding(.trailing, 14).frame(height: 36)
        .keycapSurface()
    }
}

private extension View {
    /// The raised keycap face: top-lit gradient, ledge, soft shadow and hairline.
    func keycapSurface() -> some View {
        background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(colors: [Theme.keycapTop, Theme.keycapBottom], startPoint: .top, endPoint: .bottom))
                .shadow(color: Theme.keycapLedge, radius: 0, y: 2)
                .shadow(color: Theme.shadowRaised, radius: 2, y: 3)
        }
        .overlay { RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Theme.keycapBorder) }
    }
}

/// Accent tile that carries an action symbol.
struct ActionTile: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.accent)
            .frame(width: 32, height: 32)
            .background(Theme.accentTint, in: .rect(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// The design-system switch: 38 × 22 track with an 18 pt knob, after its label.
struct ThemeSwitchStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.labelsVisibility) private var labelsVisibility

    func makeBody(configuration: ToggleStyleConfiguration) -> some View {
        HStack(spacing: 16) {
            // A custom style must honor `.labelsHidden()` itself; the label still names the switch for VoiceOver.
            if labelsVisibility != .hidden { configuration.label }
            track(configuration)
        }
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }

    private func track(_ configuration: ToggleStyleConfiguration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Capsule(style: .circular).fill(configuration.isOn ? Theme.accent : Theme.toggleOff)
                .overlay { if !configuration.isOn { Capsule(style: .circular).strokeBorder(Theme.borderSubtle) } }
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle().fill(.white).shadow(color: Theme.shadowKnob, radius: 1.5, y: 1)
                        .frame(width: 18, height: 18).padding(2)
                }
                .frame(width: 38, height: 22)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isOn)
        }
        .buttonStyle(KeyboardButtonStyle(KeyboardPlainAppearance()))
        .keyboardFocusRing()
        .opacity(isEnabled ? 1 : 0.45)
    }
}

/// Runtime state capsule: a colored dot with a short label.
struct StatusPill: View {
    enum Kind { case on, paused, attention, error }
    let kind: Kind

    private var title: LocalizedStringResource {
        switch kind {
        case .on: .statusRemappingOn
        case .paused: .statusPaused
        case .attention: .statusPermissionNeeded
        case .error: .statusStopped
        }
    }

    private var color: Color {
        switch kind {
        case .on: Theme.success
        case .paused: Theme.neutral
        case .attention: Theme.warning
        case .error: Theme.danger
        }
    }

    private var textColor: Color {
        switch kind {
        case .on: Theme.successText
        case .paused: Theme.textSecondary
        case .attention: Theme.warningText
        case .error: Theme.dangerText
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
                .padding(3).background(color.opacity(0.25), in: .circle)
            Text(title).font(Theme.calloutStrong).foregroundStyle(textColor).lineLimit(1)
        }
        .padding(.leading, 12).padding(.trailing, 14).frame(height: 32)
        .background(color.opacity(0.12), in: .capsule)
        .overlay { Capsule(style: .circular).strokeBorder(color.opacity(0.25)) }
        .contentShape(.capsule)
    }
}

/// Uppercase label above a group of controls in sheets and Settings.
struct SectionLabel: View {
    let title: LocalizedStringResource

    init(_ title: LocalizedStringResource) { self.title = title }

    var body: some View {
        Text(title).font(Theme.overline).textCase(.uppercase).foregroundStyle(Theme.textSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Capsule text field of the design system, optionally with a leading symbol (search).
struct ThemeTextField: View {
    let title: LocalizedStringResource
    @SwiftUI.Binding var text: String
    var prompt: Text?
    var symbol: String?
    var autofocus = false
    var focusRequest: UUID?
    var onSubmit: () -> Void = { }
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.iconSecondary).accessibilityHidden(true)
            }
            TextField(text: $text, prompt: (prompt ?? Text(title)).foregroundStyle(Theme.textTertiary)) { Text(title) }
                .textFieldStyle(.plain).font(Theme.body).foregroundStyle(Theme.textPrimary)
                .focused($isFocused).focusEffectDisabled().onSubmit(onSubmit)
        }
        .padding(.horizontal, symbol == nil ? 16 : 14).frame(height: Theme.controlHeight)
        .modifier(ControlSurface(isFocused: isFocused))
        .onAppear { if autofocus { isFocused = true } }
        .onChange(of: focusRequest) { if focusRequest != nil { isFocused = true } }
    }
}

/// Small round button with one symbol, such as a stepper's minus and plus.
struct CircleIconButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.textPrimary)
                .frame(width: 28, height: 28).contentShape(.circle)
        }
        .buttonStyle(KeyboardButtonStyle(KeyboardPlainAppearance())).modifier(ControlSurface()).keyboardFocusRing(Circle())
    }
}

/// The "…" menu at the end of a row.
struct OptionsMenu<Content: View>: View {
    let label: LocalizedStringResource
    @ViewBuilder var content: Content
    @Environment(\.locale) private var locale

    var body: some View {
        AnchoredMenu(select: { _ in }, makeMenu: { _ in
            NSHostingMenu(rootView: content.environment(\.locale, locale))
        }, drawsSurface: false) {
            Image(systemName: "ellipsis").font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.iconSecondary).frame(width: 28, height: 28).contentShape(.rect)
        }
        .fixedSize()
        .accessibilityLabel(Text(label))
    }
}

/// Segmented control: inset track with one raised segment. Arrow keys move the selection;
/// assistive technologies see a native picker.
struct SegmentedPicker<Value: Hashable>: View {
    @SwiftUI.Binding var selection: Value
    let title: LocalizedStringResource
    let options: [Value]
    let label: (Value) -> LocalizedStringResource
    /// Equal segments across the available width instead of content-sized ones.
    var fillsWidth = false
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var focused: Value?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button { selection = option } label: {
                    Text(label(option)).font(Theme.calloutStrong).lineLimit(1)
                        .foregroundStyle(selection == option ? Theme.textPrimary : Theme.textSecondary)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: Theme.smallControlHeight)
                        .contentShape(.capsule)
                        .background { if selection == option { Color.clear.modifier(ControlSurface()) } }
                }
                .buttonStyle(.plain)
                .focusable(interactions: .edit)
                .onKeyPress(.space) {
                    guard isEnabled else { return .ignored }
                    selection = option
                    return .handled
                }
                .focused($focused, equals: option).keyboardFocusRing(isFocused: focused == option)
            }
        }
        .padding(4)
        .background(Theme.insetSurface, in: .capsule)
        .overlay { Capsule(style: .circular).strokeBorder(Theme.borderSubtle) }
        .opacity(isEnabled ? 1 : 0.45)
        .transaction { $0.animation = nil }
        .onKeyPress(.leftArrow) { move(by: -1) }
        .onKeyPress(.rightArrow) { move(by: 1) }
        .onChange(of: selection) { if focused != nil { focused = selection } }
        .accessibilityRepresentation {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { Text(label($0)).tag($0) }
            }.pickerStyle(.radioGroup)
        }
    }

    private func move(by offset: Int) -> KeyPress.Result {
        guard isEnabled, let index = options.firstIndex(of: focused ?? selection) else { return .ignored }
        let next = options[min(max(index + offset, 0), options.count - 1)]
        selection = next
        focused = next
        return .handled
    }
}
