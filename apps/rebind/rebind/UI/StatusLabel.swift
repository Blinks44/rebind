import SwiftUI

/// A readable grant status that remains meaningful without color.
struct StatusLabel: View {
    let title: LocalizedStringResource
    let status: LocalizedStringResource
    var isWarning = false
    var isPrimary = false
    var isVerified = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(isPrimary ? Theme.titleSmall : Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 16)
                statusText
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(isPrimary ? Theme.titleSmall : Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                statusText
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var statusText: some View {
        Text(status).font(Theme.calloutStrong)
            .foregroundStyle(isWarning ? Theme.warningText
                             : isVerified ? Theme.successText : Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
