import SwiftUI

struct EditorSelectorLabel: View {
    let title: LocalizedStringResource
    var symbol: String?
    var height: CGFloat = EditorMetrics.selectorHeight
    var horizontalInset: CGFloat = 16
    var singleLine = false

    var body: some View {
        HStack(spacing: 12) {
            if let symbol {
                Image(systemName: symbol).foregroundStyle(Theme.accent).accessibilityHidden(true)
            }
            Text(title).lineLimit(singleLine ? 1 : nil).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.iconSecondary).accessibilityHidden(true)
        }
        .font(EditorTypography.label)
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, horizontalInset)
        .frame(maxWidth: .infinity, minHeight: height)
        .contentShape(.rect)
    }
}
