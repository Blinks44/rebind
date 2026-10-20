import Foundation

/// Hardware-observed candidate pool, kept separate from trackpad presets.
nonisolated enum MagicMousePreset: Int, CaseIterable, Hashable, Sendable {
    case oneFingerTap = 1, twoFingerTap = 2, threeFingerTap = 3

    case threeFingerClick = 4, twoFingerScrollUp = 5, twoFingerScrollDown = 6

    var trigger: InputTrigger {
        switch self {
        case .oneFingerTap, .twoFingerTap, .threeFingerTap: .magicMouseTap(fingers: rawValue)
        case .threeFingerClick: .magicMouseClick(fingers: 3)
        case .twoFingerScrollUp: .magicMouseScroll(.up)
        case .twoFingerScrollDown: .magicMouseScroll(.down)
        }
    }
    var help: LocalizedStringResource {
        switch self {
        case .threeFingerClick: .magicMouseClickHelp
        case .twoFingerScrollUp, .twoFingerScrollDown: .magicMouseScrollHelp
        default: .magicMouseTapHelp
        }
    }
    var title: LocalizedStringResource {
        switch self {
        case .oneFingerTap: .magicMouseOneFingerTap
        case .twoFingerTap: .magicMouseTwoFingerTap
        case .threeFingerTap: .magicMouseThreeFingerTap
        case .threeFingerClick: .magicMouseThreeFingerClick
        case .twoFingerScrollUp: .magicMouseTwoFingerScrollUp
        case .twoFingerScrollDown: .magicMouseTwoFingerScrollDown
        }
    }
    var systemGestureHelp: LocalizedStringResource? {
        switch self {
        case .oneFingerTap: .magicMouseOneFingerConflict
        case .twoFingerTap: .magicMouseTwoFingerConflict
        case .threeFingerTap, .threeFingerClick, .twoFingerScrollUp, .twoFingerScrollDown: nil
        }
    }

    init?(trigger: InputTrigger) {
        guard let preset = Self.allCases.first(where: { $0.trigger == trigger }) else { return nil }
        self = preset
    }
}
