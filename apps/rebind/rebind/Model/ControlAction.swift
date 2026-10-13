/// Actions that change Rebind itself rather than send input.
nonisolated enum ControlAction: String, Codable, CaseIterable, Hashable, Sendable {
    case pause, nextProfile, previousProfile
}
