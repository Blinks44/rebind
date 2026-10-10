import ApplicationServices
import Testing
@testable import rebind

struct WindowCycleExecutorTests {
    @Test(arguments: [true, false]) func repeatedForwardAndReverseCycleAllThreeWindows(mainChangesFocus: Bool) {
        let client = FakeCycleAccessibility()
        client.mainChangesFocus = mainChangesFocus
        var state = WindowCycleState<String>()
        for expected in ["B", "C", "A", "B"] {
            #expect(run(.next, state: &state, client: client) == .performed)
            #expect(client.focused == expected)
        }
        for expected in ["A", "C", "B"] {
            #expect(run(.previous, state: &state, client: client) == .performed)
            #expect(client.focused == expected)
        }
        #expect(state.windows == ["A", "B", "C"])
        #expect(client.mutations.prefix(4) == ["main B", "raise B", "main C", "raise C"])
    }

    @Test func minimizedModalForeignAndNonstandardWindowsAreExcluded() {
        let client = FakeCycleAccessibility()
        client.list = ["A", "minimized", "modal", "foreign", "panel", "unreadable", "B"]
        client.minimized = ["minimized"]
        client.modal = ["modal"]
        client.foreign = ["foreign"]
        client.nonstandard = ["panel"]
        client.unknown = ["unreadable"]
        var state = WindowCycleState<String>()
        #expect(run(.next, state: &state, client: client) == .performed)
        #expect(client.focused == "B" && state.windows == ["A", "B"])
    }

    @Test(arguments: 0...8) func unsupportedPermissionAndFocusContextsNeverMutate(_ scenario: Int) {
        let client = FakeCycleAccessibility()
        switch scenario {
        case 0: client.trusted = false
        case 1: client.application = nil
        case 2: client.pid = 99
        case 3: client.pid = 0
        case 4: client.focused = nil
        case 5: client.list = nil
        case 6: client.list = []
        case 7: client.modal = ["A"]
        default: client.list = Array(repeating: "B", count: 33)
        }
        var state = WindowCycleState<String>()
        #expect(run(.next, state: &state, client: client) == .unavailable)
        #expect(client.mutations.isEmpty && state.windows.isEmpty)
    }

    @Test func oneEligibleWindowMakesNoAXMutation() {
        let client = FakeCycleAccessibility()
        client.list = ["A", "minimized"]
        client.minimized = ["minimized"]
        var state = WindowCycleState<String>()
        #expect(run(.previous, state: &state, client: client) == .performed)
        #expect(client.mutations.isEmpty && client.focused == "A")
    }

    @Test(arguments: [true, false]) func readOnlyMainOrMissingRaisePreventAllWrites(readOnly: Bool) {
        let client = FakeCycleAccessibility()
        client.settable = !readOnly
        client.raiseSupported = readOnly
        var state = WindowCycleState<String>()
        #expect(run(.next, state: &state, client: client) == .unavailable)
        #expect(client.mutations.isEmpty)
    }

    @Test(arguments: 0...2) func appFocusAndCancellationChangesDuringCapabilityReadsPreventMutation(_ change: Int) {
        let client = FakeCycleAccessibility()
        var allowed = true
        client.beforeCapabilities = {
            if change == 0 { client.application = "other" }
            else if change == 1 { client.focused = "C" }
            else { allowed = false }
        }
        var state = WindowCycleState<String>()
        #expect(run(.next, state: &state, client: client, allowed: { allowed }) == (change == 2 ? .cancelled : .unavailable))
        #expect(client.mutations.isEmpty)
    }

    @Test(arguments: 0...3) func changesAfterMainWriteStopBeforeRaiseAndDoNotCommitOrder(_ change: Int) {
        let client = FakeCycleAccessibility()
        var allowed = true
        client.afterMain = {
            switch change {
            case 0: allowed = false
            case 1: client.trusted = false
            case 2: client.focused = "C"
            default: client.minimized = ["B"]
            }
        }
        var state = WindowCycleState<String>()
        #expect(run(.next, state: &state, client: client, allowed: { allowed }) == (change == 0 ? .cancelled : .unavailable))
        #expect(client.mutations == ["main B"] && state.windows.isEmpty)
    }

    @Test(arguments: 0...2) func nativeRejectionOrWrongReadbackDoesNotRetryOrClaimFocus(_ stage: Int) {
        let client = FakeCycleAccessibility()
        client.mainSucceeds = stage != 0
        client.raiseSucceeds = stage != 1
        client.raiseChangesFocus = stage != 2
        var state = WindowCycleState<String>()
        #expect(run(.next, state: &state, client: client) == .unavailable)
        #expect(client.mutations == (stage == 0 ? ["main B"] : ["main B", "raise B"]))
        #expect(state.windows.isEmpty)
    }

    @Test func failedRequestRetainsPreviouslyEstablishedOrder() {
        let client = FakeCycleAccessibility()
        var state = WindowCycleState<String>()
        #expect(run(.next, state: &state, client: client) == .performed)
        client.raiseSucceeds = false
        #expect(run(.next, state: &state, client: client) == .unavailable)
        #expect(state.windows == ["A", "B", "C"] && client.focused == "B")
        client.raiseSucceeds = true
        #expect(run(.next, state: &state, client: client) == .performed)
        #expect(client.focused == "C")
    }

    private func run(_ action: WindowCycleAction, state: inout WindowCycleState<String>,
                     client: FakeCycleAccessibility, allowed: () -> Bool = { true }) -> WindowActionResult {
        WindowCycleExecutor.perform(action, revision: 4, state: &state, client: client, ownPID: 99, canPerform: allowed)
    }
}

nonisolated private final class FakeCycleAccessibility: WindowCyclingAccessibility {
    var trusted = true
    var application: String? = "app"
    var pid: pid_t = 1
    var focused: String? = "A"
    var list: [String]? = ["A", "B", "C"]
    var minimized: Set<String> = [], modal: Set<String> = [], foreign: Set<String> = []
    var nonstandard: Set<String> = [], unknown: Set<String> = []
    var settable = true, raiseSupported = true, mainSucceeds = true, raiseSucceeds = true
    var mainChangesFocus = false, raiseChangesFocus = true
    var mutations: [String] = []
    var beforeCapabilities: (() -> Void)?
    var afterMain: (() -> Void)?

    func processID(of element: String) -> pid_t? { element == "app" ? pid : (foreign.contains(element) ? 2 : 1) }
    func element(_ attribute: String, of element: String) -> String? { attribute == kAXFocusedWindowAttribute ? focused : nil }
    func windows(of application: String, limit: Int) -> [String]? { list }
    func isWindow(_ element: String) -> Bool { element != "app" }
    func isStandardWindow(_ element: String) -> Bool { !nonstandard.contains(element) }
    func isMinimized(_ element: String) -> Bool? { unknown.contains(element) ? nil : minimized.contains(element) }
    func isModal(_ element: String) -> Bool? { unknown.contains(element) ? nil : modal.contains(element) }
    func isSettable(_ attribute: String, of element: String) -> Bool { beforeCapabilities?(); return settable }
    func isEnabled(_ element: String) -> Bool { true }
    func canRaise(_ element: String) -> Bool { raiseSupported }
    func press(_ element: String) -> Bool { Issue.record("Cycle pressed a button"); return false }
    func setTrue(_ attribute: String, of element: String) -> Bool {
        #expect(attribute == kAXMainAttribute)
        mutations.append("main \(element)")
        if mainSucceeds && mainChangesFocus { focused = element }
        afterMain?()
        return mainSucceeds
    }
    func raise(_ element: String) -> Bool {
        mutations.append("raise \(element)")
        if raiseSucceeds {
            if raiseChangesFocus { focused = element }
            // AX may report front-to-back order; this must not cause A↔B toggling.
            list = [element] + (list ?? []).filter { $0 != element }
        }
        return raiseSucceeds
    }
}
