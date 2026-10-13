import Foundation
import Testing
@testable import rebind

@MainActor struct ApplicationQuitTests {
    private let target = ApplicationTarget(url: URL(filePath: "/Applications/Example.app"), bundleIdentifier: "org.example.app")

    private var identity: QuitApplicationIdentity {
        .init(processID: 100, bundleIdentifier: target.bundleIdentifier, url: target.url, isRegular: true, isTerminated: false)
    }

    @Test func onlyOneExactRegularCopyReceivesANormalQuit() {
        let client = QuitClient(identities: [identity])
        #expect(ApplicationQuitExecutor.perform(target, client: client, ownPID: 99, canPerform: { true }) == .performed)
        #expect(client.requests == [0])
        #expect(client.identities[0].isTerminated == false) // Accepted request is not an exit acknowledgement.
    }

    @Test(arguments: 0...7) func unsafeOrDifferentInstancesAreNeverQuit(_ scenario: Int) {
        var candidate = identity
        switch scenario {
        case 0: candidate.processID = 99
        case 1: candidate.processID = 0
        case 2: candidate.isRegular = false
        case 3: candidate.isTerminated = true
        case 4: candidate.bundleIdentifier = "org.example.other"
        case 5: candidate.url = URL(filePath: "/Users/example/Applications/Example.app")
        case 6: candidate.url = nil
        default: candidate.bundleIdentifier = nil
        }
        let client = QuitClient(identities: [candidate])
        #expect(ApplicationQuitExecutor.perform(target, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.requests.isEmpty)
    }

    @Test(arguments: [0, 2]) func missingOrAmbiguousCopiesAreNotArbitrarilySelected(_ count: Int) {
        let client = QuitClient(identities: Array(repeating: identity, count: count))
        #expect(ApplicationQuitExecutor.perform(target, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.requests.isEmpty)
    }

    @Test func selfTargetIsRejectedBeforeEnumerating() {
        var ownTarget = target
        ownTarget.bundleIdentifier = "blinks44.rebind"
        let client = QuitClient(identities: [identity])
        #expect(ApplicationQuitExecutor.perform(ownTarget, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.reads == 0 && client.requests.isEmpty)
    }

    @Test func appExitBetweenSelectionAndMutationPreventsQuit() {
        let client = QuitClient(identities: [identity])
        client.onIdentityRead = { if client.reads == 2 { client.identities[0].isTerminated = true } }
        #expect(ApplicationQuitExecutor.perform(target, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.requests.isEmpty)
    }

    @Test(arguments: [true, false]) func cancellationBeforeAndAfterSelectionPreventsQuit(_ initial: Bool) {
        let client = QuitClient(identities: [identity])
        #expect(ApplicationQuitExecutor.perform(target, client: client, ownPID: 99,
            canPerform: { initial ? false : client.reads == 0 }) == .cancelled)
        #expect(client.requests.isEmpty)
    }

    @Test func rejectedRequestReportsOnceWithoutForceOrRetry() {
        let client = QuitClient(identities: [identity])
        client.accepted = false
        #expect(ApplicationQuitExecutor.perform(target, client: client, ownPID: 99, canPerform: { true }) == .unavailable)
        #expect(client.requests == [0])
    }
}

@MainActor private final class QuitClient: ApplicationQuitClient {
    var identities: [QuitApplicationIdentity]
    var applications: [Int] { Array(identities.indices) }
    var reads = 0
    var requests: [Int] = []
    var accepted = true
    var onIdentityRead: (() -> Void)?
    init(identities: [QuitApplicationIdentity]) { self.identities = identities }
    func identity(of application: Int) -> QuitApplicationIdentity {
        reads += 1
        onIdentityRead?()
        return identities[application]
    }
    func terminate(_ application: Int) -> Bool { requests.append(application); return accepted }
}
