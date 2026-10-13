import Testing
@testable import rebind

struct PermissionSetupPresentationTests {
    @Test(arguments: [false, true])
    func initialGuidanceOnlyAppearsWhenNeeded(_ needsSetup: Bool) {
        var presentation = PermissionSetupPresentation()
        presentation.beginIfNeeded(needsSetup: needsSetup)
        #expect(presentation.context == (needsSetup ? .firstRun : nil))
    }

    @Test func dismissedFirstRunIsNotReopenedByViewAppearance() {
        var presentation = PermissionSetupPresentation()
        presentation.beginIfNeeded(needsSetup: true)
        presentation.context = nil
        presentation.beginIfNeeded(needsSetup: true)
        #expect(presentation.context == nil)
    }

    @Test func revocationRecoveryOnlyAppearsOnce() {
        var presentation = PermissionSetupPresentation()
        presentation.permissionsChanged(wasAllowed: true, isAllowed: false, canPresent: true)
        #expect(presentation.context == .recovery)
        presentation.context = nil
        presentation.permissionsChanged(wasAllowed: false, isAllowed: false, canPresent: true)
        presentation.permissionsChanged(wasAllowed: false, isAllowed: true, canPresent: true)
        presentation.permissionsChanged(wasAllowed: true, isAllowed: false, canPresent: true)
        #expect(presentation.context == nil)
    }

    @Test func missingAccessAtStartupAndActiveEditorsDoNotOpenRecovery() {
        var presentation = PermissionSetupPresentation()
        presentation.permissionsChanged(wasAllowed: false, isAllowed: false, canPresent: true)
        #expect(presentation.context == nil)
        presentation.permissionsChanged(wasAllowed: true, isAllowed: false, canPresent: false)
        #expect(presentation.context == nil)
    }

    @Test func lossDuringFirstRunDoesNotReplaceTheExistingSheet() {
        var presentation = PermissionSetupPresentation()
        presentation.beginIfNeeded(needsSetup: true)
        presentation.permissionsChanged(wasAllowed: true, isAllowed: false, canPresent: true)
        #expect(presentation.context == .firstRun)
    }
}
