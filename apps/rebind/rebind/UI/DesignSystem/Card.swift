import SwiftUI

/// Raised content card of the design system; a severity tints it as a state surface.
struct Card<Content: View>: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var insets = EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
    var severity: BannerSeverity?
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
        content
            .padding(insets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                shape.fill(severity?.surface ?? Theme.cardSurface)
                    .shadow(color: severity == nil ? Theme.shadowAmbient : .clear, radius: 16, y: 12)
            }
            .overlay { shape.strokeBorder(border) }
    }

    private var border: Color {
        if let severity { return severity.color.opacity(contrast == .increased ? 1 : 0.25) }
        return contrast == .increased ? Theme.borderStrong : Theme.borderSubtle
    }
}

extension View {
    /// Recessed surface with a hairline, for a row of controls inside a card or sheet.
    func insetSurface(cornerRadius: CGFloat = 14) -> some View {
        background(Theme.insetSurface, in: .rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(Theme.borderSubtle) }
    }

    /// Horizontal margins of the main window's detail column.
    func detailMargins() -> some View { padding(.leading, 32).padding(.trailing, 40) }
}
