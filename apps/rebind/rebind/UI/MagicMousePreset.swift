import Foundation

/// Hardware-observed candidate pool, kept separate from trackpad presets.
nonisolated enum MagicMousePreset: Int, CaseIterable, Hashable, Sendable {
    case oneFingerTap = 1
    case leftSideTap = 7
    case rightSideTap = 8
    case twoFingerTap = 2
    case threeFingerTap = 3

    case twoFingerClick = 9
    case threeFingerClick = 4
    case twoFingerScrollUp = 5
    case twoFingerScrollDown = 6
    case threeFingerScrollUp = 10
    case threeFingerScrollDown = 11

    var trigger: InputTrigger {
        switch self {
        case .oneFingerTap, .twoFingerTap, .threeFingerTap: .magicMouseTap(fingers: rawValue)
        case .leftSideTap: .magicMouseSideTap(.left)
        case .rightSideTap: .magicMouseSideTap(.right)
        case .twoFingerClick: .magicMouseClick(fingers: 2)
        case .threeFingerClick: .magicMouseClick(fingers: 3)
        case .twoFingerScrollUp: .magicMouseScroll(.up)
        case .twoFingerScrollDown: .magicMouseScroll(.down)
        case .threeFingerScrollUp: .magicMouseThreeFingerScroll(.up)
        case .threeFingerScrollDown: .magicMouseThreeFingerScroll(.down)
        }
    }
    var help: LocalizedStringResource {
        switch self {
        case .twoFingerClick, .threeFingerClick: .magicMouseClickHelp
        case .twoFingerScrollUp, .twoFingerScrollDown: .magicMouseScrollHelp
        case .threeFingerScrollUp, .threeFingerScrollDown: .magicMouseThreeFingerScrollHelp
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
        case .twoFingerClick: .magicMouseTwoFingerClick
        case .threeFingerClick: .magicMouseThreeFingerClick
        case .twoFingerScrollUp: .magicMouseTwoFingerScrollUp
        case .twoFingerScrollDown: .magicMouseTwoFingerScrollDown
        case .threeFingerScrollUp: .magicMouseThreeFingerScrollUp
        case .threeFingerScrollDown: .magicMouseThreeFingerScrollDown
        }
    }
    var systemGestureHelp: LocalizedStringResource? {
        switch self {
        case .oneFingerTap, .leftSideTap, .rightSideTap: .magicMouseOneFingerConflict
        case .twoFingerTap: .magicMouseTwoFingerConflict
        case .threeFingerTap, .twoFingerClick, .threeFingerClick, .twoFingerScrollUp, .twoFingerScrollDown, .threeFingerScrollUp,
            .threeFingerScrollDown:
            nil
        }
    }

    init?(trigger: InputTrigger) {
        guard let preset = Self.allCases.first(where: { $0.trigger == trigger }) else { return nil }
        self = preset
    }
}
