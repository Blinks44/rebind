import SwiftUI

struct HoldDurationRow: View {
    @SwiftUI.Binding var milliseconds: UInt32

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PermissionCard {
                VStack(alignment: .leading, spacing: 12) {
                    Stepper(value: $milliseconds, in: 100...5000, step: 100) {
                        HStack(spacing: 12) {
                            Text(.holdDurationTitle)
                            Spacer(minLength: 12)
                            Text(.holdValue(Int32(milliseconds))).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel(Text(.holdDurationTitle))
                    .accessibilityValue(Text(.holdValue(Int32(milliseconds))))
                    .accessibilityHint(Text(.holdDurationDescription))
                    Text(.holdDurationDescription).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text(.holdRange).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
