/// Complete tap presets supported by the experimental native engine.
/// A general two-finger single tap is out of scope and intentionally absent.
nonisolated enum TrackpadTapGesture: Hashable, Sendable {
    case single(TrackpadSingleTap)
    case double(TrackpadSingleTap)
    case twoFingerDouble

    var trigger: InputTrigger {
        switch self {
        case .single(let tap): tap.trigger
        case .double(.threeFinger): .threeFingerDoubleTap
        case .double(.fourFinger): .fourFingerDoubleTap
        case .twoFingerDouble: .twoFingerDoubleTap
        }
    }

    /// Double-tap identities revalidate the injected system interval at dispatch.
    var isDoubleTap: Bool {
        switch self {
        case .single: false
        case .double, .twoFingerDouble: true
        }
    }
}
