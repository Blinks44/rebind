import SwiftUI

struct HIDDevicesView: View {
    let discovery: HIDDeviceDiscovery

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(.hidDevices).font(.title2.bold())
                    Text(.hidDiscoveryHint).foregroundStyle(.secondary)
                }
                Spacer()
                Button(.hidRefresh, systemImage: "arrow.clockwise") { discovery.restart() }
            }.padding(20)
            Divider()
            if discovery.status == .failed {
                ContentUnavailableView(.hidDiscoveryFailed, systemImage: "exclamationmark.triangle",
                                       description: Text(.hidDiscoveryRetryHint))
            } else {
                List(discovery.devices) { device in HIDDeviceRow(device: device) }
                    .overlay {
                        if discovery.devices.isEmpty {
                            ContentUnavailableView(.hidNoDevices, systemImage: "cable.connector",
                                                   description: Text(.hidNoDevicesHint))
                        }
                    }
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text(.hidDeclaredHint)
                Text(.hidReceiverHint)
                Text(.deviceScopeHint)
            }.font(.caption).foregroundStyle(.secondary).padding(16)
        }.navigationTitle("Rebind")
    }
}

