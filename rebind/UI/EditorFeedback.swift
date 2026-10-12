import SwiftUI

struct EditorFeedback<Actions: View>: View {
    let severity: EditorFeedbackSeverity
    let title: LocalizedStringResource
    var message: LocalizedStringResource?
    @ViewBuilder var actions: Actions
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: severity.symbol)
                    .foregroundStyle(severity.color).accessibilityHidden(true)
                Text(title).font(.headline).fixedSize(horizontal: false, vertical: true)
            }
            if let message {
                Text(message).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            actions.modifier(EditorSecondaryButton())
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(severity.surface, in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(severity.color.opacity(contrast == .increased ? 1 : 0.12))
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
