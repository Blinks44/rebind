import Foundation

/// Curated complete presets backed by the current tap engine, rather than arbitrary gesture parameters.
nonisolated enum TrackpadPreset: CaseIterable, Identifiable, Sendable {
    case threeFingerTap, fourFingerTap, threeFingerDoubleTap, fourFingerDoubleTap

    var id: Self { self }

    init?(trigger: InputTrigger) {
        switch trigger {
        case .threeFingerTap: self = .threeFingerTap
        case .fourFingerTap: self = .fourFingerTap
        case .threeFingerDoubleTap: self = .threeFingerDoubleTap
        case .fourFingerDoubleTap: self = .fourFingerDoubleTap
        default: return nil
        }
    }

    var gesture: TrackpadTapGesture {
        switch self {
        case .threeFingerTap: .single(.threeFinger)
        case .fourFingerTap: .single(.fourFinger)
        case .threeFingerDoubleTap: .double(.threeFinger)
        case .fourFingerDoubleTap: .double(.fourFinger)
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .threeFingerTap: .threeFingerTap
        case .fourFingerTap: .fourFingerTap
        case .threeFingerDoubleTap: .threeFingerDoubleTap
        case .fourFingerDoubleTap: .fourFingerDoubleTap
        }
    }

    var explanation: LocalizedStringResource {
        switch self {
        case .threeFingerTap: .trackpadThreeFingerTapHelp
        case .fourFingerTap: .trackpadFourFingerTapHelp
        case .threeFingerDoubleTap: .trackpadThreeFingerDoubleTapHelp
        case .fourFingerDoubleTap: .trackpadFourFingerDoubleTapHelp
        }
    }

    var systemGestureHelp: LocalizedStringResource {
        switch self {
        case .threeFingerTap: .trackpadLookUpHelp
        case .threeFingerDoubleTap: .trackpadZoomHelp
        case .fourFingerTap, .fourFingerDoubleTap: .trackpadSystemGestureHelp
        }
    }
}
