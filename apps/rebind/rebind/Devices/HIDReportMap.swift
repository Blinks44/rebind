import Foundation

/// Reads only static HID collection metadata, never input reports or typed keys.
/// USB HID 1.11 short-item format; this reader limits descriptors to 4 KiB.
nonisolated enum HIDReportMap {
    static func inputKind(_ data: Data) -> DeviceBattery.Kind? {
        guard !data.isEmpty, data.count <= 4096 else { return nil }
        let bytes = [UInt8](data)
        var offset = 0
        var page: UInt32 = 0
        var pages: [UInt32] = []
        var usage: UInt32?
        var found: DeviceBattery.Kind?
        var depth = 0
        while offset < bytes.count {
            let prefix = bytes[offset]
            offset += 1
            if prefix == 0xFE {
                guard offset + 2 <= bytes.count else { return nil }
                let length = Int(bytes[offset])
                offset += 2
                guard length <= bytes.count - offset else { return nil }
                offset += length
                continue
            }
            let length = [0, 1, 2, 4][Int(prefix & 3)]
            guard length <= bytes.count - offset else { return nil }
            var value: UInt32 = 0
            for index in 0..<length { value |= UInt32(bytes[offset + index]) << (index * 8) }
            offset += length
            let type = (prefix >> 2) & 3
            let tag = prefix >> 4
            if type == 1 {
                switch tag {
                case 0:
                    guard value <= 0xFFFF else { return nil }
                    page = value
                case 10:
                    guard pages.count < 16 else { return nil }
                    pages.append(page)
                case 11:
                    guard let previous = pages.popLast() else { return nil }
                    page = previous
                default: break
                }
            } else if type == 2, tag == 0 {
                usage = length == 4 ? value : page << 16 | value
            } else if type == 0 {
                if tag == 10 {
                    depth += 1
                    guard depth <= 32 else { return nil }
                    if value == 1, let usage {
                        let kind = MouseHardware.batteryKind(page: Int(usage >> 16), usage: Int(usage & 0xFFFF))
                        if kind == .trackpad || found == nil { found = kind }
                    }
                } else if tag == 12 {
                    guard depth > 0 else { return nil }
                    depth -= 1
                }
                usage = nil
            }
        }
        return depth == 0 && pages.isEmpty ? found : nil
    }
}
