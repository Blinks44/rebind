import SwiftUI

struct EditorFeedback<Actions: View>: View {
    let severity: EditorFeedbackSeverity
    let title: LocalizedStringResource
    var message: LocalizedStringResource?
    @ViewBuilder var actions: Actions
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: severity.symbol).font(.system(size: 13, weight: .medium))
                .foregroundStyle(severity.color).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Theme.calloutStrong).foregroundStyle(severity.textColor)
                    .fixedSize(horizontal: false, vertical: true)
                if let message {
                    Text(message).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                actions.modifier(EditorSecondaryButton()).padding(.top, 6)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 14).frame(maxWidth: .infinity, alignment: .leading)
        .background(severity.surface, in: .rect(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(severity.color.opacity(contrast == .increased ? 1 : 0.25))
        }
        .accessibilityElement(children: .contain)
    }
}

extension EditorFeedback where Actions == EmptyView {
    init(severity: EditorFeedbackSeverity, title: LocalizedStringResource,
         message: LocalizedStringResource? = nil) {
        self.severity = severity
        self.title = title
        self.message = message
        actions = EmptyView()
    }
}
