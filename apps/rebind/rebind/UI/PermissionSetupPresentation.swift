/// Keeps setup and revocation guidance bounded to one main-window lifetime.
nonisolated struct PermissionSetupPresentation: Sendable {
    var context: PermissionSetupContext?
    private var hasEvaluatedFirstRun = false
    private var hasPresentedRecovery = false

    /// Evaluates first-run guidance once, allowing dismissed setup to stay closed.
    mutating func beginIfNeeded(needsSetup: Bool) {
        guard !hasEvaluatedFirstRun else { return }
        hasEvaluatedFirstRun = true
        if needsSetup { context = .firstRun }
    }

    /// Presents one recovery only when access was lost and no other task is being edited.
    mutating func permissionsChanged(wasAllowed: Bool, isAllowed: Bool, canPresent: Bool) {
        guard wasAllowed, !isAllowed, canPresent, !hasPresentedRecovery, context == nil else { return }
        hasPresentedRecovery = true
        context = .recovery
    }
}
