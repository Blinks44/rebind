import SwiftUI

/// Hold duration with decrease/increase buttons, in 100 ms steps.
struct HoldDurationRow: View {
    @SwiftUI.Binding var milliseconds: UInt32
    private let range: ClosedRange<UInt32> = 100...5000

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(.holdDurationTitle).font(Theme.body).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 12)
                Text(.holdValue(Int32(milliseconds))).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                    .monospacedDigit().padding(.trailing, 4)
                step("minus", by: -100)
                step("plus", by: 100)
            }
            .padding(.leading, 14).padding(.trailing, 10).frame(minHeight: 48)
            .background(Theme.insetSurface, in: .rect(cornerRadius: 14, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.borderSubtle) }
            .accessibilityRepresentation {
                Stepper(value: $milliseconds, in: range, step: 100) { Text(.holdDurationTitle) }
                    .accessibilityValue(Text(.holdValue(Int32(milliseconds))))
                    .accessibilityHint(Text(.holdDurationDescription))
            }
            Text(.holdDurationDescription).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(.holdRange).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func step(_ symbol: String, by delta: Int) -> some View {
        let next = Int(milliseconds) + delta
        return Button {
            milliseconds = UInt32(min(max(next, Int(range.lowerBound)), Int(range.upperBound)))
        } label: {
            Image(systemName: symbol).font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.textPrimary)
                .frame(width: 28, height: 28).contentShape(.circle)
        }
        .buttonStyle(.plain).modifier(ControlSurface()).keyboardFocusRing(Circle())
        .disabled(!range.contains(UInt32(clamping: next)))
    }
}
