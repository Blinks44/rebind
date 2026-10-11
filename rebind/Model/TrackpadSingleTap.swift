/// Complete single-tap identities supported by the experimental native engine.
nonisolated enum TrackpadSingleTap: Int, CaseIterable, Sendable {
    case threeFinger = 3
    case fourFinger = 4

    var trigger: InputTrigger {
        switch self {
        case .threeFinger: .threeFingerTap
        case .fourFinger: .fourFingerTap
        }
    }
}
