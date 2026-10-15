import SwiftUI

struct DeviceIdentityView: View {
    let name: String
    let original: String
    let subtitle: String
    let kind: DeviceBattery.Kind
    let battery: DeviceBattery?
    let rename: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kind.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.iconSecondary)
                .frame(width: 32, height: 32).insetSurface(cornerRadius: 10).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: name).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                if name != original {
                    Text(verbatim: original).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !subtitle.isEmpty {
                    Text(verbatim: subtitle).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer(minLength: 12)
            if let battery {
                Label {
                    Text(battery.isCharging ? .devicesBatteryCharging(battery.percentage) : .devicesBattery(battery.percentage))
                } icon: { Image(systemName: battery.symbol) }
                .font(Theme.callout)
                .foregroundStyle(battery.percentage <= 15 && !battery.isCharging ? Theme.warningText : Theme.textSecondary)
                .fixedSize()
            }
            Button(.renameDevice, systemImage: "pencil", action: rename)
                .labelStyle(.iconOnly).secondaryButton().controlSize(.small)
                .help(.renameDevice)
                .accessibilityValue(Text(verbatim: name))
        }
    }
}
