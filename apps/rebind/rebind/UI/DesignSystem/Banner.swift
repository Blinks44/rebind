import SwiftUI

struct Banner<Actions: View>: View {
    let severity: BannerSeverity
    let title: LocalizedStringResource
    var message: LocalizedStringResource?
    /// Shows a close button that hides the banner.
    var dismiss: (() -> Void)?
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
                actions.padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let dismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.iconSecondary).frame(width: 22, height: 22).contentShape(.rect)
                }
                .buttonStyle(KeyboardButtonStyle(KeyboardPlainAppearance())).keyboardFocusRing(Circle())
                .accessibilityLabel(Text(.bannerHide)).help(Text(.bannerHide))
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

extension Banner where Actions == EmptyView {
    init(severity: BannerSeverity, title: LocalizedStringResource,
         message: LocalizedStringResource? = nil, dismiss: (() -> Void)? = nil) {
        self.severity = severity
        self.title = title
        self.message = message
        self.dismiss = dismiss
        actions = EmptyView()
    }
}
enum BannerSeverity {
    case error, warning, success, information, neutral

    var symbol: String {
        switch self {
        case .error: "xmark.circle"
        case .warning: "exclamationmark.triangle"
        case .success: "checkmark.circle"
        case .information: "info.circle"
        case .neutral: "pause.circle"
        }
    }

    var color: Color {
        switch self {
        case .error: Theme.danger
        case .warning: Theme.warning
        case .success: Theme.success
        case .information: Theme.accent
        case .neutral: Theme.neutral
        }
    }

    var textColor: Color {
        switch self {
        case .error: Theme.dangerText
        case .warning: Theme.warningText
        case .success: Theme.successText
        case .information: Theme.accent
        case .neutral: Theme.textPrimary
        }
    }

    var surface: Color { color.opacity(0.12) }
}
