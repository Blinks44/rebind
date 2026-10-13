/// Identifies an explicit first-run or one-time grant-recovery presentation.
nonisolated enum PermissionSetupContext: String, Identifiable, Sendable {
    case firstRun, recovery
    var id: Self { self }
}
