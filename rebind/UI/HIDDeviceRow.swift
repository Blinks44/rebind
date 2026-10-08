import SwiftUI

struct HIDDeviceRow: View {
    let device: HIDDeviceInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    if let name = device.product { Text(verbatim: name) }
                    else { Text(.hidUnnamedDevice) }
                } icon: { Image(systemName: symbol) }
                    .font(.headline)
                Spacer()
                Text(.hidConnected).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                if device.kinds.contains(.keyboard) { Text(.hidKeyboard) }
                if device.kinds.contains(.mouse) { Text(.hidPointingDevice) }
                if device.kinds.contains(.trackpad) { Text(.hidTrackpad) }
                Text(transportLabel)
                if let manufacturer = device.manufacturer { Text(verbatim: manufacturer) }
            }.foregroundStyle(.secondary)
            HStack(spacing: 16) {
                if let vendor = device.vendorID, let product = device.productID {
                    LabeledContent { Text(verbatim: "\(hex(vendor)) / \(hex(product))") } label: { Text(.hidVendorProduct) }
                }
                LabeledContent { Text(verbatim: hex(device.id)) } label: { Text(.hidInterfaceID) }
            }.font(.caption).foregroundStyle(.secondary)
            if let usages = device.capabilities.buttonUsages {
                if usages.isEmpty { Text(.hidNoDeclaredButtons) }
                else {
                    LabeledContent {
                        Text(verbatim: usages.map { $0.formatted() }.joined(separator: ", "))
                            .textSelection(.enabled)
                    } label: { Text(.hidDeclaredButtons) }
                }
            } else { Text(.hidCapabilitiesUnavailable).foregroundStyle(.secondary) }
        }.padding(.vertical, 8)
    }

    private var symbol: String {
        if device.kinds.contains(.trackpad) { return "rectangle.and.hand.point.up.left" }
        if device.kinds.contains(.mouse) { return "computermouse" }
        return "keyboard"
    }

    private var transportLabel: LocalizedStringResource {
        switch device.transport {
        case .usb: .hidUSB
        case .bluetooth: .hidBluetooth
        case .builtIn: .hidBuiltIn
        case .virtual: .hidVirtual
        case .other: .hidOtherTransport
        }
    }

    private func hex<T: BinaryInteger>(_ value: T) -> String { "0x" + String(value, radix: 16, uppercase: true) }
}
