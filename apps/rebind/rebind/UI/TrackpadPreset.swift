import Foundation

/// Curated complete presets backed by the current tap engine, rather than arbitrary gesture parameters.
nonisolated enum TrackpadPreset: Hashable, CaseIterable, Identifiable, Sendable {
    case threeFingerTap, fourFingerTap, twoFingerDoubleTap, threeFingerDoubleTap, fourFingerDoubleTap
    case click(fingers: Int)
    case cornerTap(TrackpadCorner)

    static let allCases: [Self] = [.threeFingerTap, .fourFingerTap, .twoFingerDoubleTap, .threeFingerDoubleTap,
                                   .fourFingerDoubleTap] + (2...4).map(Self.click)
        + TrackpadCorner.allCases.map(Self.cornerTap)

    var id: Self { self }

    init?(trigger: InputTrigger) {
        guard let preset = Self.allCases.first(where: { $0.trigger == trigger }) else { return nil }
        self = preset
    }

    var trigger: InputTrigger {
        switch self {
        case .threeFingerTap: .threeFingerTap
        case .fourFingerTap: .fourFingerTap
        case .twoFingerDoubleTap: .twoFingerDoubleTap
        case .threeFingerDoubleTap: .threeFingerDoubleTap
        case .fourFingerDoubleTap: .fourFingerDoubleTap
        case .click(let fingers): .trackpadClick(fingers: fingers)
        case .cornerTap(let corner): .cornerTap(corner)
        }
    }

    static func clickTitle(fingers: Int) -> LocalizedStringResource {
        switch fingers {
        case 2: .trackpadTwoFingerClick
        case 3: .trackpadThreeFingerClick
        default: .trackpadFourFingerClick
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .threeFingerTap: .threeFingerTap
        case .fourFingerTap: .fourFingerTap
        case .twoFingerDoubleTap: .twoFingerDoubleTap
        case .threeFingerDoubleTap: .threeFingerDoubleTap
        case .fourFingerDoubleTap: .fourFingerDoubleTap
        case .click(let fingers): Self.clickTitle(fingers: fingers)
        case .cornerTap(let corner): corner.title
        }
    }

    var explanation: LocalizedStringResource {
        switch self {
        case .threeFingerTap: .trackpadThreeFingerTapHelp
        case .fourFingerTap: .trackpadFourFingerTapHelp
        case .twoFingerDoubleTap: .trackpadTwoFingerDoubleTapHelp
        case .threeFingerDoubleTap: .trackpadThreeFingerDoubleTapHelp
        case .fourFingerDoubleTap: .trackpadFourFingerDoubleTapHelp
        case .click: .trackpadClickHelp
        case .cornerTap: .trackpadCornerTapHelp
        }
    }

    var systemGestureHelp: LocalizedStringResource {
        switch self {
        case .threeFingerTap: .trackpadLookUpHelp
        case .twoFingerDoubleTap: .trackpadSmartZoomHelp
        case .threeFingerDoubleTap: .trackpadZoomHelp
        case .fourFingerTap, .fourFingerDoubleTap: .trackpadSystemGestureHelp
        case .click(fingers: 2): .trackpadSecondaryClickHelp
        case .click: .trackpadMultiFingerClickHelp
        case .cornerTap: .trackpadTapToClickHelp
        }
    }
}
