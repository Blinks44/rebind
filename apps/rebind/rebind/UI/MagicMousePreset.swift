import Foundation

/// Hardware-observed candidate pool, kept separate from trackpad presets.
nonisolated enum MagicMousePreset: Int, CaseIterable, Hashable, Sendable {
    case oneFingerTap = 1
    case leftSideTap = 7
    case rightSideTap = 8
    case twoFingerTap = 2
    case threeFingerTap = 3

    case threeFingerClick = 4
    case twoFingerScrollUp = 5
    case twoFingerScrollDown = 6

    var trigger: InputTrigger {
        switch self {
        case .oneFingerTap, .twoFingerTap, .threeFingerTap: .magicMouseTap(fingers: rawValue)
        case .leftSideTap: .magicMouseSideTap(.left)
        case .rightSideTap: .magicMouseSideTap(.right)
        case .threeFingerClick: .magicMouseClick(fingers: 3)
        case .twoFingerScrollUp: .magicMouseScroll(.up)
        case .twoFingerScrollDown: .magicMouseScroll(.down)
        }
    }
    var help: LocalizedStringResource {
        switch self {
        case .threeFingerClick: .magicMouseClickHelp
        case .twoFingerScrollUp, .twoFingerScrollDown: .magicMouseScrollHelp
        case .leftSideTap, .rightSideTap: .magicMouseSideTapHelp
        default: .magicMouseTapHelp
        }
    }
    var title: LocalizedStringResource {
        switch self {
        case .oneFingerTap: .magicMouseOneFingerTap
        case .leftSideTap: .magicMouseLeftSideTap
        case .rightSideTap: .magicMouseRightSideTap
        case .twoFingerTap: .magicMouseTwoFingerTap
        case .threeFingerTap: .magicMouseThreeFingerTap
        case .threeFingerClick: .magicMouseThreeFingerClick
        case .twoFingerScrollUp: .magicMouseTwoFingerScrollUp
        case .twoFingerScrollDown: .magicMouseTwoFingerScrollDown
        }
    }
    var systemGestureHelp: LocalizedStringResource? {
        switch self {
        case .oneFingerTap, .leftSideTap, .rightSideTap: .magicMouseOneFingerConflict
        case .twoFingerTap: .magicMouseTwoFingerConflict
        case .threeFingerTap, .threeFingerClick, .twoFingerScrollUp, .twoFingerScrollDown: nil
        }
    }

    init?(trigger: InputTrigger) {
        guard let preset = Self.allCases.first(where: { $0.trigger == trigger }) else { return nil }
        self = preset
    }
}
