import Foundation
import Testing
@testable import rebind

@MainActor struct LoginItemModelTests {
    @Test(arguments: [LoginItemStatus.off, .enabled, .requiresApproval, .unavailable])
    func readingAndOpeningSettingsNeverRegistersOrGrantsApproval(status: LoginItemStatus) {
        let service = LoginItemServiceStub(status: status)
        let model = LoginItemModel(service: service)
        model.refresh()
        model.openLoginItems()
        model.refresh()
        #expect(model.status == status)
        #expect(service.registrationCount == 0 && service.removalCount == 0)
        #expect(service.openCount == 1)
    }

    @Test(arguments: [LoginItemStatus.enabled, .requiresApproval], [true, false])
    func registrationReadsActualStateEvenWhenNativeOperationThrows(result: LoginItemStatus, throwsError: Bool) async {
        let service = LoginItemServiceStub()
        service.registrationResult = result
        service.rejectsRegistration = throwsError
        let model = LoginItemModel(service: service)
        await model.setEnabled(true)
        #expect(model.status == result)
        #expect(model.failedOperation == nil && model.operation == nil)
        #expect(model.showsToggle == (result == .enabled))
        #expect(service.registrationCount == 1)
    }

    @Test func failedRegistrationKeepsOffAndRetryUsesExplicitOperation() async {
        let service = LoginItemServiceStub()
        service.registrationResult = .off
        service.rejectsRegistration = true
        let model = LoginItemModel(service: service)
        await model.setEnabled(true)
        #expect(model.status == .off && model.failedOperation == .enable)
        #expect(model.description == .loginEnableFailed)
        #expect(model.showsToggle == false)
        model.refresh()
        #expect(service.registrationCount == 1)
        service.registrationResult = .enabled
        service.rejectsRegistration = false
        await model.retry()
        #expect(model.status == .enabled && model.failedOperation == nil)
        #expect(service.registrationCount == 2)
    }

    @Test(arguments: [LoginItemStatus.enabled, .requiresApproval])
    func approvalAndEnabledItemsCanBeRemoved(status: LoginItemStatus) async {
        let service = LoginItemServiceStub(status: status)
        let model = LoginItemModel(service: service)
        await model.setEnabled(false)
        #expect(model.status == .off && model.failedOperation == nil)
        #expect(service.removalCount == 1 && service.registrationCount == 0)
    }

    @Test(arguments: [LoginItemStatus.enabled, .requiresApproval])
    func failedRemovalDescribesActualOnOrApprovalState(result: LoginItemStatus) async {
        let service = LoginItemServiceStub(status: .enabled)
        service.removalResult = result
        service.rejectsRemoval = true
        let model = LoginItemModel(service: service)
        await model.setEnabled(false)
        #expect(model.status == result && model.failedOperation == .disable)
        #expect(model.description == (result == .enabled ? .loginDisableFailed : .loginApprovalDisableFailed))
        service.removalResult = .off
        service.rejectsRemoval = false
        await model.retry()
        #expect(model.status == .off && model.failedOperation == nil)
        #expect(service.removalCount == 2)
    }

    @Test func thrownRemovalThatReachedOffDoesNotClaimItIsStillOn() async {
        let service = LoginItemServiceStub(status: .enabled)
        service.rejectsRemoval = true
        let model = LoginItemModel(service: service)
        await model.setEnabled(false)
        #expect(model.status == .off && model.failedOperation == nil && model.showsToggle)
    }

    @Test func successfulCallWithoutExpectedStateStillOffersRecovery() async {
        let service = LoginItemServiceStub()
        service.registrationResult = .off
        let model = LoginItemModel(service: service)
        await model.setEnabled(true)
        #expect(model.failedOperation == .enable)
        #expect(model.description == .loginEnableFailed)
    }

    @Test func notFoundAfterOperationNeverClaimsOnOrOff() async {
        let service = LoginItemServiceStub()
        service.registrationResult = .unavailable
        service.rejectsRegistration = true
        let model = LoginItemModel(service: service)
        await model.setEnabled(true)
        #expect(model.status == .unavailable)
        #expect(model.description == .loginUnavailable && model.showsToggle == false)
        await model.retry()
        #expect(service.registrationCount == 1)
    }

    @Test func externalChangeClearsStaleErrorAndDoesNotRetry() async {
        let service = LoginItemServiceStub()
        service.registrationResult = .off
        service.rejectsRegistration = true
        let model = LoginItemModel(service: service)
        await model.setEnabled(true)
        service.status = .requiresApproval
        model.refresh()
        #expect(model.failedOperation == nil && model.status == .requiresApproval)
        service.status = .enabled
        model.refresh()
        #expect(model.status == .enabled && model.showsToggle)
        await model.retry()
        #expect(service.registrationCount == 1 && service.removalCount == 0)
    }

    @Test func removalStaysBusyAcrossAwaitAndRejectsOverlappingChanges() async {
        let service = LoginItemServiceStub(status: .enabled)
        let model = LoginItemModel(service: service)
        service.onRemoval = {
            #expect(model.operation == .disable && model.showsToggle == false)
            #expect(model.description == .loginDisabling)
            model.refresh()
            await model.setEnabled(true)
            await model.setEnabled(false)
            #expect(service.registrationCount == 0 && service.removalCount == 1)
            #expect(model.operation == .disable)
        }
        await model.setEnabled(false)
        #expect(model.operation == nil && model.status == .off)
    }

    @Test(arguments: [LoginItemStatus.enabled, .requiresApproval, .unavailable])
    func enablingAlreadyRegisteredOrUnavailableServiceIsReadOnly(status: LoginItemStatus) async {
        let service = LoginItemServiceStub(status: status)
        let model = LoginItemModel(service: service)
        await model.setEnabled(true)
        #expect(service.registrationCount == 0 && service.removalCount == 0)
        #expect(model.status == status)
    }
}
