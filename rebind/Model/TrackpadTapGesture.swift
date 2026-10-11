/// Complete tap presets supported by the experimental native engine.
nonisolated enum TrackpadTapGesture: Hashable, Sendable {
    case single(TrackpadSingleTap)
    case double(TrackpadSingleTap)

    var trigger: InputTrigger {
        switch self {
        case .single(let tap): tap.trigger
        case .double(.threeFinger): .threeFingerDoubleTap
        case .double(.fourFinger): .fourFingerDoubleTap
        }
    }
}
