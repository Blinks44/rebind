import SwiftUI

/// A readable grant status that remains meaningful without color.
struct PermissionStatusLabel: View {
    let title: LocalizedStringResource
    let status: LocalizedStringResource
    var isWarning = false
    var isPrimary = false
    var isVerified = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(isPrimary ? .title3.weight(.semibold) : .headline)
                Spacer(minLength: 16)
                statusText
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(isPrimary ? .title3.weight(.semibold) : .headline)
                statusText
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var statusText: some View {
        Text(status).font(Theme.callout)
            .foregroundStyle(isWarning ? Theme.warningText
                             : isVerified ? Theme.successText : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
