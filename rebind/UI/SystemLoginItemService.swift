import ServiceManagement

/// Uses the main app login item; no helper, plist or persisted OS-state mirror.
@MainActor struct SystemLoginItemService: LoginItemService {
    var status: LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .notRegistered: .off
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .unavailable
        @unknown default: .unavailable
        }
    }

    func register() throws { try SMAppService.mainApp.register() }
    func unregister() async throws { try await SMAppService.mainApp.unregister() }
    func openLoginItems() { SMAppService.openSystemSettingsLoginItems() }
}
