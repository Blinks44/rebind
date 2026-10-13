/// Complete tap presets supported by the experimental native engine.
/// General one- and two-finger single taps are out of scope and intentionally absent;
/// a one-finger tap counts only inside a corner region.
nonisolated enum TrackpadTapGesture: Hashable, Sendable {
    case single(TrackpadSingleTap)
    case double(TrackpadSingleTap)
    case twoFingerDouble
    case corner(TrackpadCorner)

    var trigger: InputTrigger {
        switch self {
        case .single(let tap): tap.trigger
        case .double(.threeFinger): .threeFingerDoubleTap
        case .double(.fourFinger): .fourFingerDoubleTap
        case .twoFingerDouble: .twoFingerDoubleTap
        case .corner(let corner): .cornerTap(corner)
        }
    }

    /// Double-tap identities revalidate the injected system interval at dispatch.
    var isDoubleTap: Bool {
        switch self {
        case .single, .corner: false
        case .double, .twoFingerDouble: true
        }
    }
}
