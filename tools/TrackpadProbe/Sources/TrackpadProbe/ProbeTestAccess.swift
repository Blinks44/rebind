// A request is not a grant. Keep actual preflight results separate from the
// next explicit onboarding step; AX and posting can disagree on macOS.
struct ProbeTestAccess: Equatable, Sendable {
    enum Request: String, Sendable {
        case accessibility, eventPosting = "event-posting"
    }

    let accessibility: Bool
    let posting: Bool

    var allowed: Bool { accessibility && posting }

    var nextRequest: Request? {
        if !accessibility { return .accessibility }
        if !posting { return .eventPosting }
        return nil
    }
}
