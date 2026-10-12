import SwiftUI

/// Calm permission content surfaces; navigation retains the system material.
struct PermissionCard<Content: View>: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    var insets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    var severity: EditorFeedbackSeverity?
    var isRaised = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(insets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12).fill(surface)
                    .shadow(color: isRaised && severity == nil && !reduceTransparency
                            ? Color(.permissionCardShadow) : .clear, radius: 10, x: 0, y: 3)
            }
            .overlay {
                if let severity {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(severity.color.opacity(contrast == .increased ? 1 : 0.12))
                } else if contrast == .increased {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(Color(nsColor: .separatorColor))
                } else if isRaised {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(Color(.permissionCardBorder), lineWidth: 0.5)
                }
            }
    }

    private var surface: AnyShapeStyle {
        if let severity { return AnyShapeStyle(severity.surface) }
        guard isRaised && !reduceTransparency else { return AnyShapeStyle(Color(.permissionSurface)) }
        return AnyShapeStyle(LinearGradient(colors: [Color(.permissionCardTop), Color(.permissionCardBottom)],
                                            startPoint: .top, endPoint: .bottom)
            .shadow(.inner(color: .white.opacity(colorScheme == .light ? 0.7 : 0.06), radius: 0, x: 0, y: 1)))
    }
}
