import Foundation
import IOKit.hid

/// Descriptor metadata only. Declared usages are not evidence of delivered events.
nonisolated struct HIDCapabilities: Equatable, Sendable {
    var buttonUsages: [UInt32]?
    var declaresTrackpad = false

    init(buttonUsages: [UInt32]? = nil, declaresTrackpad: Bool = false) {
        self.buttonUsages = buttonUsages.map { Array(Set($0.filter { $0 > 0 })).sorted() }
        self.declaresTrackpad = declaresTrackpad
    }

    init(elementDescriptions: [[String: Any]]?) {
        guard let elementDescriptions else { self.init(); return }
        var buttons = Set<UInt32>()
        var trackpad = false
        var hasInputDescription = false
        // Apple's public Elements property is hierarchical. Walk iteratively so
        // collection nesting cannot consume the call stack; never read values.
        var pending = elementDescriptions
        while let element = pending.popLast() {
            let page = Self.number(element[kIOHIDElementUsagePageKey])
            let usage = Self.number(element[kIOHIDElementUsageKey])
            let type = Self.number(element[kIOHIDElementTypeKey])
            if let type, (kIOHIDElementTypeInput_Misc.rawValue...kIOHIDElementTypeInput_ScanCodes.rawValue).contains(type),
               page != nil, usage != nil { hasInputDescription = true }
            if page == UInt32(kHIDPage_Digitizer), usage == UInt32(kHIDUsage_Dig_TouchPad),
               type == kIOHIDElementTypeCollection.rawValue { trackpad = true }
            if page == UInt32(kHIDPage_Button), let usage, usage > 0,
               let type, (kIOHIDElementTypeInput_Misc.rawValue...kIOHIDElementTypeInput_ScanCodes.rawValue).contains(type),
               (element[kIOHIDElementIsArrayKey] as? NSNumber)?.boolValue != true {
                buttons.insert(usage)
            }
            if let children = element[kIOHIDElementKey] as? [[String: Any]] { pending.append(contentsOf: children) }
        }
        // Some systems expose only collection headers. An empty result from
        // that incomplete description cannot establish absence of buttons.
        self.init(buttonUsages: hasInputDescription ? Array(buttons) : nil, declaresTrackpad: trackpad)
    }

    private static func number(_ value: Any?) -> UInt32? {
        guard let number = value as? NSNumber else { return nil }
        let value = number.doubleValue
        guard value.isFinite, value >= 0, value <= Double(UInt32.max), value.rounded(.towardZero) == value else { return nil }
        return UInt32(value)
    }
}
