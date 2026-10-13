import ApplicationServices
import Synchronization
import Testing
@testable import rebind

@MainActor struct ApplicationActivationTests {
    @Test(arguments: [1, 99]) func changesActualFocusWithoutActivatingRebindFirst(_ source: Int) async {
        let client = ActivationClient()
        client.focused = source
        #expect(await perform(client, source: source) == .performed)
        #expect(client.writes == [2] && client.focused == 2)
    }

    @Test(arguments: 0...5) func unsupportedTargetPermissionAndFocusNeverMutate(_ failure: Int) async {
        let client = ActivationClient()
        switch failure {
        case 0: client.trusted = false
        case 1: client.settable = false
        case 2: client.targetPID = 0
        case 3: client.targetPID = 99
        case 4: client.focused = 3
        default: client.focused = nil
        }
        #expect(await perform(client) == .unavailable)
        #expect(client.writes.isEmpty)
    }

    @Test(arguments: [WindowActionResult.cancelled, .unavailable])
    func mainActorRevalidationRefusesStoppedOrExitedTargets(_ result: WindowActionResult) async {
        let client = ActivationClient()
        #expect(await perform(client, authorize: { result }) == result)
        #expect(client.writes.isEmpty)
    }

    @Test func lifecycleChangeDuringLastFocusReadCancelsBeforeWrite() async {
        let client = ActivationClient()
        let allowed = Mutex(true)
        client.onFocusRead = { if $0 == 2 { allowed.withLock { $0 = false } } }
        #expect(await ApplicationActivationExecutor.perform(target: 2, source: 1, client: client, ownPID: 99,
            authorize: { .performed }, canPerform: { allowed.withLock { $0 } }) == .cancelled)
        #expect(client.writes.isEmpty)
    }

    @Test func focusChangeAcrossActorHopPreventsStaleActivation() async {
        let client = ActivationClient()
        #expect(await perform(client, authorize: { client.focused = 3; return .performed }) == .unavailable)
        #expect(client.writes.isEmpty)
    }

    @Test(arguments: [true, false]) func rejectedOrAcceptedWithoutFocusIsFailureWithoutRetry(_ accepts: Bool) async {
        let client = ActivationClient()
        client.accepts = accepts
        client.focusDelay = nil // Even an accepted write never changes actual focus.
        #expect(await perform(client) == .unavailable)
        #expect(client.writes == [2])
    }

    @Test func delayedFocusIsAcknowledgedByReadbackWithoutAnotherWrite() async {
        let client = ActivationClient()
        client.focusDelay = 2
        #expect(await perform(client) == .performed)
        #expect(client.writes == [2] && client.focused == 2)
    }

    @Test func cancellationAfterAcceptedWriteStopsWaitingWithoutRetry() async {
        let client = ActivationClient()
        let allowed = Mutex(true)
        client.onWrite = { allowed.withLock { $0 = false } }
        #expect(await ApplicationActivationExecutor.perform(target: 2, source: 1, client: client, ownPID: 99,
            authorize: { .performed }, canPerform: { allowed.withLock { $0 } }) == .cancelled)
        #expect(client.writes == [2])
    }

    private func perform(_ client: ActivationClient, source: Int = 1,
                         authorize: @MainActor () -> WindowActionResult = { .performed }) async -> WindowActionResult {
        await ApplicationActivationExecutor.perform(target: 2, source: source, client: client,
            ownPID: 99, authorize: authorize, canPerform: { true })
    }
}

private final class ActivationClient: WindowAccessibility {
    var trusted = true
    var focused: Int? = 1
    var targetPID: Int32? = 2
    var settable = true
    var accepts = true
    var focusDelay: Int? = 0
    var writes: [Int] = []
    var reads = 0
    var onFocusRead: ((Int) -> Void)?
    var onWrite: (() -> Void)?

    var application: Int? {
        reads += 1
        onFocusRead?(reads)
        if !writes.isEmpty, accepts, let delay = focusDelay {
            if delay == 0 { focused = 2 } else { focusDelay = delay - 1 }
        }
        return focused
    }
    func processID(of element: Int) -> Int32? { element == 2 ? targetPID : Int32(element) }
    func isSettable(_ attribute: String, of element: Int) -> Bool {
        #expect(attribute == kAXFrontmostAttribute && element == 2)
        return settable
    }
    func setTrue(_ attribute: String, of element: Int) -> Bool {
        #expect(attribute == kAXFrontmostAttribute && element == 2)
        writes.append(element)
        onWrite?()
        return accepts
    }
    func element(_ attribute: String, of element: Int) -> Int? {
        Issue.record("Application switch read a window or document attribute"); return nil
    }
    func isWindow(_ element: Int) -> Bool { Issue.record("Application switch inspected windows"); return false }
    func isEnabled(_ element: Int) -> Bool { Issue.record("Application switch inspected a button"); return false }
    func press(_ element: Int) -> Bool { Issue.record("Application switch pressed a button"); return false }
}
