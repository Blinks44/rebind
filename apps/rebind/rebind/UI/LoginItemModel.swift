import Foundation
import Observation

/// Serializes explicit login changes and presents freshly read system state.
@MainActor @Observable final class LoginItemModel {
    enum Operation: Equatable { case enable, disable }

    private(set) var status: LoginItemStatus = .unavailable
    private(set) var operation: Operation?
    private(set) var failedOperation: Operation?
    @ObservationIgnored private let service: any LoginItemService

    init(service: any LoginItemService = SystemLoginItemService()) {
        self.service = service
        status = service.status
    }

    func refresh() {
        let current = service.status
        if current != status { failedOperation = nil }
        status = current
    }

    /// Only an explicit UI action invokes this method; focus refresh never registers.
    func setEnabled(_ enabled: Bool) async {
        guard operation == nil, !Task.isCancelled else { return }
        refresh()
        guard status != .unavailable else { return }
        if enabled && status != .off || !enabled && status == .off {
            failedOperation = nil
            return
        }
        let requested: Operation = enabled ? .enable : .disable
        operation = requested
        failedOperation = nil
        defer { operation = nil }
        do {
            if enabled { try service.register() }
            else { try await service.unregister() }
        } catch {
            // An error does not establish whether OS registration changed.
            // Read the result below, including approval and not-found states.
        }
        status = service.status
        let reachedRequestedState = enabled
            ? status == .enabled || status == .requiresApproval
            : status == .off
        failedOperation = reachedRequestedState ? nil : requested
    }

    func retry() async {
        guard let failedOperation else { return }
        await setEnabled(failedOperation == .enable)
    }

    func openLoginItems() { service.openLoginItems() }

    var description: LocalizedStringResource {
        if let operation { return operation == .enable ? .loginEnabling : .loginDisabling }
        switch status {
        case .unavailable: return .loginUnavailable
        case .requiresApproval:
            return failedOperation == .disable ? .loginApprovalDisableFailed : .loginApprovalDescription
        case .enabled:
            return failedOperation == .disable ? .loginDisableFailed : .launchAtLoginDescription
        case .off:
            return failedOperation == .enable ? .loginEnableFailed : .launchAtLoginDescription
        }
    }

    var showsToggle: Bool {
        operation == nil && failedOperation == nil && (status == .off || status == .enabled)
    }
}
