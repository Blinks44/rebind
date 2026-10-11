import Testing
@testable import rebind

struct GeneralRuntimePresentationTests {
    @Test(arguments: [EngineStatus.paused, .active, .permissionRequired, .secureInput, .tapFailed, .interrupted, .outputFailed])
    func deliberatePauseNeverClaimsActiveOrOffersRetry(status: EngineStatus) {
        let state = GeneralRuntimePresentation(isEnabled: false, permissions: InputPermissions(),
            status: status, isSuspended: false, storageLocked: false)
        #expect(state == .paused)
    }

    @Test(arguments: [EngineStatus.paused, .active, .permissionRequired, .secureInput, .tapFailed, .interrupted, .outputFailed])
    func missingAccessNeverClaimsActiveOrEngineRetry(status: EngineStatus) {
        let state = GeneralRuntimePresentation(isEnabled: true, permissions: InputPermissions(),
            status: status, isSuspended: false, storageLocked: false)
        #expect(state == .missingAccess)
    }

    @Test(arguments: [
        (EngineStatus.active, GeneralRuntimePresentation.active),
        (.paused, .starting), (.permissionRequired, .starting), (.secureInput, .secureInput),
        (.tapFailed, .engineError), (.interrupted, .engineError), (.outputFailed, .engineError)
    ])
    func runningStateComesFromCaptureWithActualGrants(status: EngineStatus, expected: GeneralRuntimePresentation) {
        let state = GeneralRuntimePresentation(isEnabled: true,
            permissions: InputPermissions(accessibility: true, posting: true),
            status: status, isSuspended: false, storageLocked: false)
        #expect(state == expected)
    }

    @Test func staleActiveStatusCannotOverrideSuspensionOrStorageLock() {
        let grants = InputPermissions(accessibility: true, posting: true)
        #expect(GeneralRuntimePresentation(isEnabled: true, permissions: grants,
            status: .active, isSuspended: true, storageLocked: false) == .suspended)
        #expect(GeneralRuntimePresentation(isEnabled: true, permissions: grants,
            status: .active, isSuspended: false, storageLocked: true) == .storageLocked)
    }
}
