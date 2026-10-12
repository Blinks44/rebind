import SwiftUI

struct EditorSelectorLabel: View {
    let title: LocalizedStringResource
    var symbol: String?
    var height: CGFloat = EditorMetrics.selectorHeight
    var horizontalInset: CGFloat = 16

    var body: some View {
        HStack(spacing: 12) {
            if let symbol {
                Image(systemName: symbol).foregroundStyle(Color(.editorAccentText)).accessibilityHidden(true)
            }
            Text(title).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
        }
        .font(EditorTypography.label)
        .foregroundStyle(Color(.editorTextPrimary))
        .padding(.horizontal, horizontalInset)
        .frame(maxWidth: .infinity, minHeight: height)
        .contentShape(.rect)
    }
}
