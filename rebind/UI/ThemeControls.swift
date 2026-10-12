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
            .background {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.keycapTop, Theme.keycapBottom], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Theme.keycapLedge, radius: 0, y: 2)
                    .shadow(color: Theme.shadowRaised, radius: 2, y: 3)
            }
            .overlay { RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Theme.keycapBorder) }
    }
}

/// Flat chip for triggers that are not a physical key or button: gestures, wheel and taps.
struct TriggerChip: View {
    let label: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.iconSecondary).frame(width: 16, height: 16)
            Text(label).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary).lineLimit(1)
        }
        .padding(.leading, 10).padding(.trailing, 12).frame(height: 36)
        .background(Theme.neutralSoft, in: .rect(cornerRadius: 10, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Theme.neutralBorder) }
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

/// Accent capsule for the one primary action of a screen: 36 pt, or 28 pt with `.controlSize(.small)`.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        let isSmall = controlSize == .small || controlSize == .mini
        configuration.label
            .font(isSmall ? Theme.calloutStrong : Theme.bodyBold).foregroundStyle(.white)
            .padding(.horizontal, isSmall ? 14 : 17)
            .frame(height: isSmall ? EditorMetrics.buttonHeight : Theme.controlHeight)
            .background {
                Capsule(style: .circular).fill(Theme.accentFill)
                    .overlay {
                        Capsule(style: .circular).fill(LinearGradient(stops: [.init(color: .white.opacity(0.24), location: 0),
                                                              .init(color: .white.opacity(0), location: 0.55)],
                                                      startPoint: .top, endPoint: .bottom))
                    }
                    .shadow(color: Theme.accentGlow, radius: 8, y: 6)
            }
            .overlay { Capsule(style: .circular).strokeBorder(.white.opacity(0.3)) }
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .contentShape(.capsule)
    }
}

/// The design-system switch: 38 × 22 track with an 18 pt knob, after its label.
struct ThemeSwitchStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: ToggleStyleConfiguration) -> some View {
        HStack(spacing: 16) {
            configuration.label
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
        .buttonStyle(.plain)
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

/// Soft red capsule for a destructive action that still asks for confirmation.
struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .font(Theme.bodyStrong).foregroundStyle(Theme.dangerText)
            .padding(.horizontal, 18).frame(height: Theme.controlHeight)
            .background {
                Capsule(style: .circular).fill(Theme.danger.opacity(0.12)).strokeBorder(Theme.danger.opacity(0.25))
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45)
            .contentShape(.capsule)
    }
}
