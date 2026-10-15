import Foundation

/// Read-only battery queries adapted from razer-battery (MIT) and SteelMouse (MIT).
/// Profiles, source revisions and full licenses are recorded in ThirdPartyNotices and DEVICE-003.
nonisolated enum VendorBatteryProtocol {
    enum Family: Equatable, Sendable {
        case razer(transaction: UInt8)
        case steelSeries(command: UInt8, directPercentage: Bool)
        case rival
    }

    struct Profile: Equatable, Sendable {
        let interface: Int
        let family: Family

        var isFeatureProtocol: Bool {
            if case .razer = family { return true }
            return false
        }

        func acceptsInterface(number: Int?, usages: [(page: Int, usage: Int)], featureSize: Int, outputSize: Int) -> Bool {
            guard number == interface, !usages.contains(where: { $0.page == 1 && $0.usage == 6 }) else { return false }
            if isFeatureProtocol { return featureSize >= 90 }
            // Interrupt replies must come from a vendor control collection, never mouse
            // motion or key reports that could happen to resemble a battery response.
            return outputSize > 0 && outputSize <= 512 && usages.contains { $0.page >= 0xFF00 }
                && !usages.contains { $0.page == 1 && $0.usage == 2 }
        }
    }

    static func profile(vendorID: Int, productID: Int) -> Profile? {
        switch vendorID {
        case 0x1532: razerProfiles[productID]
        case 0x1038: steelSeriesProfiles[productID]
        default: nil
        }
    }

    static func razerRequest(transaction: UInt8, charging: Bool = false) -> [UInt8] {
        var report = [UInt8](repeating: 0, count: 90)
        report[1] = transaction
        report[5] = 2
        report[6] = 7
        report[7] = charging ? 0x84 : 0x80
        report[88] = report[2..<88].reduce(0, ^)
        return report
    }

    static func razerValue(_ response: [UInt8], transaction: UInt8, charging: Bool = false) -> UInt8? {
        guard response.count == 90, response[0] == 2, response[1] == transaction,
              response[2] == 0, response[3] == 0, response[4] == 0, response[5] >= 2,
              response[6] == 7, response[7] == (charging ? 0x84 : 0x80),
              response[88] == response[2..<88].reduce(0, ^) else { return nil }
        let value = response[9]
        return charging && value > 1 ? nil : value
    }

    static func steelSeriesRequest(for family: Family) -> [UInt8]? {
        switch family {
        case .razer: nil
        case .steelSeries(let command, _): [command]
        case .rival: [0xAA, 1]
        }
    }

    static func steelSeriesReading(_ response: [UInt8], family: Family) -> PeripheralBatteryReading? {
        guard !response.isEmpty, response.contains(where: { $0 != 0 }) else { return nil }
        // IOHIDDevice callbacks omit report ID 0; some firmwares include it in the payload.
        let bytes = response.first == 0 ? Array(response.dropFirst()) : response
        switch family {
        case .razer: return nil
        case .steelSeries(let command, let direct):
            guard bytes.count >= 2, bytes[0] == command else { return nil }
            let raw = bytes.count >= 3 && bytes[1] == 0 ? bytes[2] : bytes[1]
            let value = Int(raw & 0x7F)
            guard value > 0, value <= (direct ? 100 : 21) else { return nil }
            return PeripheralBatteryReading(percentage: direct ? value : (value - 1) * 5, isCharging: raw & 0x80 != 0)
        case .rival:
            let level: UInt8
            let charging: UInt8
            if bytes.count >= 4, bytes[0] == 0xAA, bytes[1] == 1 {
                (level, charging) = (bytes[2], bytes[3])
            } else if bytes.count >= 3, bytes[0] == 0xAA {
                (level, charging) = (bytes[1], bytes[2])
            } else if bytes.count >= 3, bytes[1] == 0 {
                (level, charging) = (bytes[0], bytes[2])
            } else if response.count >= 3, response[1] == 0 {
                // Direct macOS response: [percentage, high byte (0), charging].
                (level, charging) = (response[0], response[2])
            } else { return nil }
            guard level <= 100, charging <= 1 else { return nil }
            return PeripheralBatteryReading(percentage: Int(level), isCharging: charging == 1)
        }
    }
}

nonisolated extension VendorBatteryProtocol {
    /// Known USB mouse/receiver profiles only; never apply these commands by vendor alone.
    static let razerProfiles: [Int: Profile] = [
        0x00B6: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x00B7: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x00B8: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x007C: Profile(interface: 2, family: .razer(transaction: 0x3f)),
        0x009C: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x007A: Profile(interface: 2, family: .razer(transaction: 0x3f)),
        0x007B: Profile(interface: 2, family: .razer(transaction: 0x3f)),
        0x00A5: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x00C2: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x00C3: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x00BA: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x0088: Profile(interface: 2, family: .razer(transaction: 0x3f)),
        0x00AA: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x00B9: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x008F: Profile(interface: 2, family: .razer(transaction: 0x1f)),
        0x00B3: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x0094: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x0072: Profile(interface: 2, family: .razer(transaction: 0x3f)),
        0x00AF: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x00C0: Profile(interface: 0, family: .razer(transaction: 0x1f)),
        0x00A6: Profile(interface: 0, family: .razer(transaction: 0x1F)),
        0x00B5: Profile(interface: 0, family: .razer(transaction: 0x1F)),
    ]

    static let steelSeriesProfiles: [Int: Profile] = [
        0x183a: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: false)),
        0x187a: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: false)),
        0x1838: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: false)),
        0x1878: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: false)),
        0x1890: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: true)),
        0x1892: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: true)),
        0x1854: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: false)),
        0x185e: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: false)),
        0x1862: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: false)),
        0x1852: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: false)),
        0x185c: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: false)),
        0x1860: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: false)),
        0x185a: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: false)),
        0x1876: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: false)),
        0x1858: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: false)),
        0x1874: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: false)),
        0x1842: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: false)),
        0x184a: Profile(interface: 3, family: .steelSeries(command: 0x92, directPercentage: false)),
        0x1840: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: false)),
        0x1848: Profile(interface: 3, family: .steelSeries(command: 0xD2, directPercentage: false)),
        0x1830: Profile(interface: 3, family: .rival),
        0x1872: Profile(interface: 3, family: .rival),
        0x172b: Profile(interface: 3, family: .rival),
        0x1726: Profile(interface: 3, family: .rival),
    ]
}
