import AppKit
import SwiftUI

/// Executable tokens of the Sketch design system (Light/Dark Color Variables, type and radii).
/// Sketch remains the source; add a token here only when a view needs it.
enum Theme {
    // Background
    static let canvasTop = Color(light: 0xF5F7FB, dark: 0x15171C)
    static let canvasBottom = Color(light: 0xEDF1F8, dark: 0x101217)
    static let canvasGlow = Color(light: 0xDCE7FF, 0.55, dark: 0x22346B, 0.4)

    // Surfaces and borders
    static let sidebarSurface = Color(light: 0xFFFFFF, 0.58, dark: 0xFFFFFF, 0.07)
    static let cardSurface = Color(light: 0xFFFFFF, 0.85, dark: 0xFFFFFF, 0.055)
    static let controlSurface = Color(light: 0xFFFFFF, 0.62, dark: 0xFFFFFF, 0.09)
    static let sheetSurface = Color(light: 0xFBFCFE, dark: 0x1D2027)
    static let insetSurface = Color(light: 0x0F172A, 0.04, dark: 0x000000, 0.22)
    static let hoverSurface = Color(light: 0x0F172A, 0.04, dark: 0xFFFFFF, 0.06)
    static let borderHighlight = Color(light: 0xFFFFFF, 0.8, dark: 0xFFFFFF, 0.12)
    static let borderControl = Color(light: 0xFFFFFF, 0.7, dark: 0xFFFFFF, 0.12)
    static let borderSubtle = Color(light: 0x0F172A, 0.06, dark: 0xFFFFFF, 0.09)
    static let borderStrong = Color(light: 0x0F172A, 0.12, dark: 0xFFFFFF, 0.18)
    static let separator = Color(light: 0x0F172A, 0.07, dark: 0xFFFFFF, 0.08)

    // Text and icons
    static let textPrimary = Color(light: 0x111318, dark: 0xF2F4F8)
    static let textSecondary = Color(light: 0x3C3C43, 0.75, dark: 0xEBEBF5, 0.6)
    static let textTertiary = Color(light: 0x3C3C43, 0.3, dark: 0xEBEBF5, 0.3)
    static let iconSecondary = Color(light: 0x3C3C43, 0.7, dark: 0xEBEBF5, 0.7)
    static let iconTertiary = Color(light: 0x3C3C43, 0.4, dark: 0xEBEBF5, 0.4)

    // Accent
    static let accent = Color(light: 0x2F66F5, dark: 0x6E94FF)
    static let accentFill = Color(light: 0x2F66F5, dark: 0x3B6AF0)
    static let accentSoft = Color(light: 0x2F66F5, 0.12, dark: 0x6E94FF, 0.2)
    static let accentTint = Color(light: 0x2F66F5, 0.1, dark: 0x6E94FF, 0.18)
    static let accentGlow = Color(light: 0x2F66F5, 0.28, dark: 0x6E94FF, 0.25)

    // State
    static let success = Color(light: 0x1E9E5A, dark: 0x3DD68C)
    static let successText = Color(light: 0x15704A, dark: 0x3DD68C)
    static let warning = Color(light: 0xD98A00, dark: 0xFFB84D)
    static let warningText = Color(light: 0x8A5300, dark: 0xFFC46B)
    static let danger = Color(light: 0xE5484D, dark: 0xFF6B6E)
    static let dangerText = Color(light: 0xB4232A, dark: 0xFF8A8C)
    static let neutral = Color(light: 0x6B7280, dark: 0x9AA1B0)
    static let neutralSoft = Color(light: 0x0F172A, 0.06, dark: 0xFFFFFF, 0.08)
    static let neutralBorder = Color(light: 0x0F172A, 0.1, dark: 0xFFFFFF, 0.14)

    // Keycap and toggle
    static let keycapTop = Color(light: 0xFFFFFF, dark: 0x3A3E48)
    static let keycapBottom = Color(light: 0xEEF1F6, dark: 0x2B2E36)
    static let keycapLedge = Color(light: 0xD3D9E4, dark: 0x14161B)
    static let keycapBorder = Color(light: 0x0F172A, 0.1, dark: 0xFFFFFF, 0.12)
    static let keycapText = Color(light: 0x1B2230, dark: 0xF2F4F8)
    static let toggleOff = Color(light: 0x787880, 0.16, dark: 0xFFFFFF, 0.16)

    // Shadows (Sketch blur is twice the SwiftUI radius)
    static let shadowAmbient = Color(light: 0x0F172A, 0.04, dark: 0x000000, 0.16)
    static let shadowSoft = Color(light: 0x0F172A, 0.07, dark: 0x000000, 0.32)
    static let shadowRaised = Color(light: 0x0F172A, 0.08, dark: 0x000000, 0.32)
    static let shadowKnob = Color(light: 0x0F172A, 0.2, dark: 0x000000, 0.55)

    // Typography
    static let largeTitle = Font.system(size: 30, weight: .semibold)
    static let title = Font.system(size: 22, weight: .semibold)
    static let headline = Font.system(size: 15, weight: .medium)
    static let body = Font.system(size: 14)
    static let bodyStrong = Font.system(size: 14, weight: .medium)
    static let bodyBold = Font.system(size: 14, weight: .semibold)
    static let callout = Font.system(size: 13)
    static let calloutStrong = Font.system(size: 13, weight: .medium)
    static let caption = Font.system(size: 12)
    static let titleSmall = Font.system(size: 17, weight: .semibold)
    static let overline = Font.system(size: 11, weight: .semibold)

    // Geometry
    static let controlHeight: CGFloat = 36
    static let smallControlHeight: CGFloat = 28
    static let compactControlHeight: CGFloat = 24
    static let rowHeight: CGFloat = 72
    static let cardRadius: CGFloat = 22
}

extension Color {
    /// An appearance-adaptive color from `0xRRGGBB` values.
    init(light: UInt32, _ lightOpacity: Double = 1, dark: UInt32, _ darkOpacity: Double = 1) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let hex = isDark ? dark : light
            return NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: isDark ? darkOpacity : lightOpacity)
        })
    }
}

/// Window background: vertical canvas gradient with the soft top-left glow.
struct ThemeCanvas: View {
    var body: some View {
        LinearGradient(colors: [Theme.canvasTop, Theme.canvasBottom], startPoint: .top, endPoint: .bottom)
            .overlay(alignment: .topLeading) {
                RadialGradient(colors: [Theme.canvasGlow, Theme.canvasGlow.opacity(0)],
                               center: .center, startRadius: 0, endRadius: 520)
                    .frame(width: 1040, height: 1040).offset(x: -340, y: -520)
            }
            .clipped()
    }
}

/// White raised capsule shared by the search field, selectors and secondary buttons.
struct ControlSurface: ViewModifier {
    /// Text fields pass their focus state to swap the hairline for the accent border.
    var isFocused = false
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        // Circular capsules only: on macOS 27 the default continuous capsule draws a broken
        // outline (a missing top or bottom edge), most visibly on the focused search field.
        content.background {
            Capsule(style: .circular).fill(Theme.controlSurface)
                .strokeBorder(isFocused ? Theme.accent : contrast == .increased ? Theme.borderStrong : Theme.borderControl,
                              lineWidth: isFocused ? 1.5 : 1)
                .shadow(color: Theme.shadowSoft, radius: 7, y: 4)
        }
    }
}
