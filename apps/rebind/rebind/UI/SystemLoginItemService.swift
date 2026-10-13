import ServiceManagement

/// Uses the main app login item; no helper, plist or persisted OS-state mirror.
@MainActor struct SystemLoginItemService: LoginItemService {
    /// macOS reports `.notFound` for an app that has never been registered, although
    /// registering it works. Only after an attempt does `.notFound` mean "unavailable".
    private static var attemptedRegistration = false

    var status: LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .notRegistered: .off
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: Self.attemptedRegistration ? .unavailable : .off
        @unknown default: .unavailable
        }
    }

    func register() throws {
        Self.attemptedRegistration = true
        try SMAppService.mainApp.register()
    }

    func unregister() async throws { try await SMAppService.mainApp.unregister() }
    func openLoginItems() { SMAppService.openSystemSettingsLoginItems() }
}
