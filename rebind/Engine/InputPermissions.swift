import ApplicationServices

nonisolated struct InputPermissions: Equatable, Sendable {
    var accessibility = false
    var listening = false
    var posting = false

    // Accessibility authorizes this active session tap and event synthesis.
    // A separate Input Monitoring grant is not required for this capture path.
    // Tap creation can still fail and is checked by EventTapWorker itself.
    var allowsRemapping: Bool { requirement == nil }

    var requirement: InputPermissionRequirement? {
        if !accessibility { return .accessibility }
        if !posting { return .eventPosting }
        return nil
    }

    static func current() -> Self {
        Self(accessibility: AXIsProcessTrusted(), listening: CGPreflightListenEventAccess(),
             posting: CGPreflightPostEventAccess())
    }
}
