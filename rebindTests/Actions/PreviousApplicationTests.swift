import AppKit
import Testing
import Synchronization
@testable import rebind

@MainActor struct PreviousApplicationTests {
    @Test func multipleActivationNotificationsPrecedeFrontmostPropertyUpdate() async {
        let client = SwitchClient()
        client.frontmost = nil
        let (tracker, center) = makeTracker(client)
        tracker.start()
        defer { tracker.stop() }
        postActivation(1, to: center)
        client.frontmost = 1
        postActivation(2, to: center) // AppKit's foreground property still reports app 1.
        postActivation(3, to: center) // Its cached property has not advanced this run-loop turn.
        client.frontmost = 3
        #expect(await tracker.perform(canPerform: { true }) == .performed)
        #expect(client.requests == [2])

        postActivation(2, to: center) // It still reports app 3 during this notification.
        client.frontmost = 2
        #expect(await tracker.perform(canPerform: { true }) == .performed)
        #expect(client.requests == [2, 3])
    }

    @Test func notificationBridgeIgnoresOwnIneligibleAndMalformedEvents() async {
        let client = SwitchClient()
        client.frontmost = 1
        let (tracker, center) = makeTracker(client)
        tracker.start()
        defer { tracker.stop() }
        postActivation(2, to: center)
        client.frontmost = 2
        postActivation(2, to: center)
        postActivation(99, to: center)
        postActivation(4, to: center)
        center.post(name: NSWorkspace.didActivateApplicationNotification, object: nil)
        #expect(await tracker.perform(canPerform: { true }) == .performed)
        #expect(client.requests == [1])
    }

    @Test func stoppingAndRestartingObserverDropsPreviousSessionHistory() async {
        let client = SwitchClient()
        client.frontmost = 1
        let (tracker, center) = makeTracker(client)
        tracker.start()
        tracker.start() // Registration is idempotent.
        postActivation(2, to: center)
        client.frontmost = 2
        tracker.stop()
        postActivation(3, to: center)
        #expect(await tracker.perform(canPerform: { true }) == .unavailable)
        tracker.start()
        defer { tracker.stop() }
        #expect(await tracker.perform(canPerform: { true }) == .unavailable)
        #expect(client.requests.isEmpty)
        postActivation(1, to: center)
        client.frontmost = 1
        #expect(await tracker.perform(canPerform: { true }) == .performed)
        #expect(client.requests == [2])
    }

    @Test func reentrantNativeActivationUpdatesLiveHistoryWithoutExclusiveAccess() async {
        let client = SwitchClient()
        client.frontmost = 1
        let (tracker, center) = makeTracker(client)
        tracker.start()
        defer { client.onActivation = nil; tracker.stop() }
        postActivation(2, to: center)
        client.frontmost = 2
        client.onActivation = {
            postActivation($0, to: center)
            client.frontmost = $0
        }
        #expect(await tracker.perform(canPerform: { true }) == .performed)
        #expect(await tracker.perform(canPerform: { true }) == .performed)
        #expect(client.requests == [1, 2])
    }

    @Test func observedActivationsToggleAndDuplicateNotificationsDoNotLosePrevious() async {
        var history = ApplicationActivationHistory<Int>()
        let client = SwitchClient()
        history.observe(1)
        history.observe(2)
        history.observe(2)
        #expect(await PreviousApplicationExecutor.perform(history: &history, client: client, canPerform: { true }) == .performed)
        #expect(client.requests == [1])
        #expect(history.current == 2 && history.previous == 1)
        client.frontmost = 1
        history.observe(1)
        #expect(await PreviousApplicationExecutor.perform(history: &history, client: client, canPerform: { true }) == .performed)
        #expect(client.requests == [1, 2])
    }

    @Test func delayedNotificationIsReconciledWithCurrentFrontmostApp() async {
        var history = ApplicationActivationHistory<Int>()
        history.observe(1)
        let client = SwitchClient()
        #expect(await PreviousApplicationExecutor.perform(history: &history, client: client, canPerform: { true }) == .performed)
        #expect(client.requests == [1] && history.current == 2)
    }

    @Test func fromRebindReturnsToLastExternalAppWithoutAddingRebind() async {
        var history = ApplicationActivationHistory<Int>()
        history.observe(1)
        history.observe(2)
        let client = SwitchClient()
        client.frontmost = 99
        #expect(await PreviousApplicationExecutor.perform(history: &history, client: client, canPerform: { true }) == .performed)
        #expect(client.requests == [2] && history.current == 2 && history.previous == 1)
    }

    @Test(arguments: 0...4) func missingExitedOrBackgroundTargetsNeverActivate(_ scenario: Int) async {
        var history = ApplicationActivationHistory<Int>()
        let client = SwitchClient()
        if scenario != 0 { history.observe(1) }
        history.observe(2)
        switch scenario {
        case 1: client.eligible = [2] // Previous object ended, even if a new instance of that app exists.
        case 2: client.frontmost = nil
        case 3: client.frontmost = 3; client.eligible = [1, 2] // Accessory/background foreground.
        case 4: history.clear()
        default: break
        }
        #expect(await PreviousApplicationExecutor.perform(history: &history, client: client, canPerform: { true }) == .unavailable)
        #expect(client.requests.isEmpty)
    }

    @Test(arguments: [true, false]) func cancellationBeforeOrAfterTargetSelectionPreventsActivation(_ initial: Bool) async {
        var history = ApplicationActivationHistory<Int>()
        history.observe(1)
        let client = SwitchClient()
        let gates = Mutex(0)
        #expect(await PreviousApplicationExecutor.perform(history: &history, client: client, canPerform: {
            return gates.withLock { count in
                count += 1
                return !initial && count == 1
            }
        }) == .cancelled)
        #expect(client.requests.isEmpty)
    }

    @Test(arguments: [true, false]) func focusChangeOrExitDuringSelectionPreventsActivation(_ focusChanges: Bool) async {
        var history = ApplicationActivationHistory<Int>()
        history.observe(1)
        let client = SwitchClient()
        client.onEligibility = { if $0 == 1 {
            if focusChanges { client.frontmost = 3 } else { client.eligible.remove(1) }
        } }
        #expect(await PreviousApplicationExecutor.perform(history: &history, client: client, canPerform: { true }) == .unavailable)
        #expect(client.requests.isEmpty)
    }

    @Test func rejectedRequestDoesNotRetryOrOptimisticallyChangeHistory() async {
        var history = ApplicationActivationHistory<Int>()
        history.observe(1)
        let client = SwitchClient()
        client.accepted = false
        #expect(await PreviousApplicationExecutor.perform(history: &history, client: client, canPerform: { true }) == .unavailable)
        #expect(client.requests == [1] && history.current == 2 && history.previous == 1)
    }

    @Test func historyContainsOnlyLastTwoAndClearRemovesBoth() async {
        var history = ApplicationActivationHistory<Int>()
        for app in 1...100 { history.observe(app) }
        #expect(history.current == 100 && history.previous == 99)
        history.clear()
        #expect(history.current == nil && history.previous == nil)
    }
}

@MainActor private final class SwitchClient: PreviousApplicationClient {
    var frontmost: Int? = 2
    var frontmostApplication: Int? { frontmost }
    var eligible: Set<Int> = [1, 2, 3]
    var requests: [Int] = []
    var accepted = true
    var onEligibility: ((Int) -> Void)?
    var onActivation: ((Int) -> Void)?
    func isOwnApplication(_ application: Int) -> Bool { application == 99 }
    func isEligible(_ application: Int) -> Bool {
        onEligibility?(application)
        return eligible.contains(application)
    }
    func activate(_ application: Int, from source: Int,
                  canPerform: @escaping @Sendable () -> Bool) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard frontmost == source else { return .unavailable }
        requests.append(application)
        if accepted { onActivation?(application) }
        return accepted ? .performed : .unavailable
    }
}

@MainActor private func makeTracker(_ client: SwitchClient) -> (PreviousApplicationTracker<SwitchClient>, NotificationCenter) {
    let center = NotificationCenter()
    return (PreviousApplicationTracker(client: client, notificationCenter: center) {
        $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? Int
    }, center)
}

@MainActor private func postActivation(_ application: Int, to center: NotificationCenter) {
    center.post(name: NSWorkspace.didActivateApplicationNotification, object: nil,
                userInfo: [NSWorkspace.applicationUserInfoKey: application])
}
