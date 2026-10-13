import CoreGraphics

nonisolated struct ModifierSet: OptionSet, Codable, Hashable, Sendable {
    let rawValue: UInt8
    static let command = Self(rawValue: 1)
    static let control = Self(rawValue: 2)
    static let option = Self(rawValue: 4)
    static let shift = Self(rawValue: 8)
    // Preserve the observed Fn flag for exact matching, but do not enable Fn rules
    // before hardware research. Dropping it could silently match a different chord.
    static let function = Self(rawValue: 16)
    static let supported: Self = [.command, .control, .option, .shift]

    init(rawValue: UInt8) { self.rawValue = rawValue }

    init(flags: CGEventFlags) {
        self = []
        for (modifier, flag) in Self.flagPairs where flags.contains(flag) {
            insert(modifier)
        }
    }

    var flags: CGEventFlags {
        Self.flagPairs.reduce(into: CGEventFlags()) { result, pair in
            if contains(pair.0) { result.insert(pair.1) }
        }
    }

    var glyphs: String {
        [(Self.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
            .filter { contains($0.0) }.map(\.1).joined()
    }

    private static let flagPairs: [(Self, CGEventFlags)] = [
        (.command, .maskCommand), (.control, .maskControl),
        (.option, .maskAlternate), (.shift, .maskShift), (.function, .maskSecondaryFn)
    ]
}
