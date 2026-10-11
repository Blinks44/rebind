import Foundation
@testable import rebind

/// No native registration, System Settings opening or permission mutation.
@MainActor final class LoginItemServiceStub: LoginItemService {
    enum Failure: Error { case rejected }

    var status: LoginItemStatus
    var registrationResult: LoginItemStatus = .enabled
    var removalResult: LoginItemStatus = .off
    var rejectsRegistration = false
    var rejectsRemoval = false
    var onRemoval: (() async -> Void)?
    private(set) var registrationCount = 0
    private(set) var removalCount = 0
    private(set) var openCount = 0

    init(status: LoginItemStatus = .off) { self.status = status }

    func register() throws {
        registrationCount += 1
        status = registrationResult
        if rejectsRegistration { throw Failure.rejected }
    }

    func unregister() async throws {
        removalCount += 1
        await onRemoval?()
        status = removalResult
        if rejectsRemoval { throw Failure.rejected }
    }

    func openLoginItems() { openCount += 1 }
}
