import Foundation

/// Hardware-observed candidate pool, kept separate from trackpad presets.
nonisolated enum MagicMousePreset: Int, CaseIterable, Hashable, Sendable {
    case oneFingerTap = 1, twoFingerTap = 2

    var trigger: InputTrigger { .magicMouseTap(fingers: rawValue) }
    var title: LocalizedStringResource { self == .oneFingerTap ? .magicMouseOneFingerTap : .magicMouseTwoFingerTap }
    var systemGestureHelp: LocalizedStringResource {
        self == .oneFingerTap ? .magicMouseOneFingerConflict : .magicMouseTwoFingerConflict
    }

    init?(trigger: InputTrigger) {
        guard case .magicMouseTap(let fingers) = trigger else { return nil }
        self.init(rawValue: fingers)
    }
}
