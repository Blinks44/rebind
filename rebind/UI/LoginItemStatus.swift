/// Actual OS registration state, independent of remapping preferences.
nonisolated enum LoginItemStatus: Sendable, Equatable {
    case off, enabled, requiresApproval, unavailable
}
