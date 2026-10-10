import Testing
@testable import TrackpadProbe

struct ProbeTestAccessTests {
    @Test func permissionRequestRequiresASeparateExplicitMode() throws {
        let options = try ProbeOptions(arguments: ["--request-test-access"])
        #expect(options == .requestTestAccess)
        #expect(!options.postsTestShortcut && !options.observesButtons)
        #expect(try ProbeOptions(arguments: []) == .check)
        for arguments in [
            ["--request-test-access", "--seconds", "20"],
            ["--test-four-finger-close", "--request-test-access"],
            ["--capture-clicks-default", "--request-test-access"]
        ] {
            #expect(throws: ProbeOptions.InvalidArguments.self) { try ProbeOptions(arguments: arguments) }
        }
    }

    @Test(arguments: [
        ProbeTestAccess(accessibility: false, posting: false),
        ProbeTestAccess(accessibility: false, posting: true),
        ProbeTestAccess(accessibility: true, posting: false),
        ProbeTestAccess(accessibility: true, posting: true)
    ])
    func actualGrantsDetermineTheNextRequest(access: ProbeTestAccess) {
        #expect(access.allowed == (access.accessibility && access.posting))
        if !access.accessibility {
            #expect(access.nextRequest == .accessibility)
        } else if !access.posting {
            #expect(access.nextRequest == .eventPosting)
        } else {
            #expect(access.nextRequest == nil)
        }
    }

    @Test func accessibilityGrantAloneDoesNotPermitTheAction() {
        let denied = ProbeTestAccess(accessibility: false, posting: false)
        let axGranted = ProbeTestAccess(accessibility: true, posting: false)
        let ready = ProbeTestAccess(accessibility: true, posting: true)
        #expect(denied.nextRequest == .accessibility && !denied.allowed)
        #expect(axGranted.nextRequest == .eventPosting && !axGranted.allowed)
        #expect(ready.allowed && ready.nextRequest == nil)
        // Revocation must return to the actual missing stage, not remembered
        // request success or the last ready snapshot.
        #expect(!denied.allowed && denied.nextRequest == .accessibility)
    }
}
