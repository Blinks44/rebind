import Testing
@testable import rebind

struct InputPermissionsTests {
    @Test("Granting AX advances to the specific synthesis request without authorizing the engine")
    func permissionStages() {
        var permissions = InputPermissions(listening: true)
        #expect(permissions.requirement == .accessibility)
        permissions.accessibility = true
        #expect(permissions.requirement == .eventPosting)
        #expect(!permissions.allowsRemapping)
        permissions.posting = true
        #expect(permissions.requirement == nil)
        #expect(permissions.allowsRemapping)
        permissions.accessibility = false
        #expect(permissions.requirement == .accessibility)
        #expect(!permissions.allowsRemapping)
    }

    @Test("Accessibility permits remapping without a separate listening grant", arguments: [false, true])
    func accessibilityIsSufficient(listening: Bool) {
        let permissions = InputPermissions(accessibility: true, listening: listening, posting: true)
        #expect(permissions.allowsRemapping)
        #expect(permissions.listening == listening)
    }

    @Test("Listening alone cannot authorize filtering or synthesis", arguments: [false, true])
    func accessibilityIsRequired(posting: Bool) {
        let permissions = InputPermissions(accessibility: false, listening: true, posting: posting)
        #expect(!permissions.allowsRemapping)
    }

    @Test("Denied synthesis blocks remapping even with Accessibility", arguments: [false, true])
    func postingIsRequired(listening: Bool) {
        let permissions = InputPermissions(accessibility: true, listening: listening, posting: false)
        #expect(!permissions.allowsRemapping)
    }
}
