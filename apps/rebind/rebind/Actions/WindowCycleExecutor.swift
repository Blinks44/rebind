import ApplicationServices
import Darwin

nonisolated protocol WindowCyclingAccessibility: WindowAccessibility {
    func windows(of application: Element, limit: Int) -> [Element]?
    func isStandardWindow(_ element: Element) -> Bool
    func isMinimized(_ element: Element) -> Bool?
    func isModal(_ element: Element) -> Bool?
    func canRaise(_ element: Element) -> Bool
    func raise(_ element: Element) -> Bool
}

nonisolated enum WindowCycleExecutor {
    static func perform(_ action: WindowCycleAction, revision: UInt64,
                        state: inout WindowCycleState<AXUIElement>, canPerform: () -> Bool) -> WindowActionResult {
        perform(action, revision: revision, state: &state, client: AXWindowAccessibility(),
                ownPID: getpid(), canPerform: canPerform)
    }

    static func perform<Client: WindowCyclingAccessibility>(_ action: WindowCycleAction, revision: UInt64,
        state: inout WindowCycleState<Client.Element>, client: Client, ownPID: pid_t,
        canPerform: () -> Bool) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard client.trusted, let app = client.application, let pid = client.processID(of: app),
              pid > 0, pid != ownPID, let focused = client.element(kAXFocusedWindowAttribute, of: app),
              let observed = client.windows(of: app, limit: WindowCycleState<Client.Element>.maximumWindows),
              observed.count <= WindowCycleState<Client.Element>.maximumWindows else { return .unavailable }

        func eligible(_ window: Client.Element) -> Bool {
            client.processID(of: window) == pid && client.isWindow(window) && client.isStandardWindow(window)
                && client.isMinimized(window) == false && client.isModal(window) == false
        }
        let candidates = observed.filter(eligible)
        guard let order = state.order(application: app, revision: revision, observed: candidates),
              let target = WindowCycleState<Client.Element>.target(action, focused: focused, order: order) else { return .unavailable }

        func gate(allowTargetFocus: Bool = false) -> WindowActionResult? {
            guard canPerform() else { return .cancelled }
            guard client.trusted, client.application == app,
                  let current = client.element(kAXFocusedWindowAttribute, of: app),
                  current == focused || (allowTargetFocus && current == target),
                  eligible(focused), eligible(target) else { return .unavailable }
            // AX reads can wait. This last check is immediately before mutation.
            guard client.trusted else { return .unavailable }
            return canPerform() ? nil : .cancelled
        }
        if let result = gate() { return result }
        // One eligible window is a successful no-op, without a needless AX write.
        if target != focused {
            guard client.isSettable(kAXMainAttribute, of: target), client.canRaise(target) else { return .unavailable }
            if let result = gate() { return result }
            guard client.setTrue(kAXMainAttribute, of: target) else { return .unavailable }
            // Main doesn't guarantee keyboard focus; raise, then check actual focus.
            // A partial change may remain if the second step is cancelled/rejected.
            if let result = gate(allowTargetFocus: true) { return result }
            guard client.raise(target) else { return .unavailable }
            guard canPerform() else { return .cancelled }
            guard client.trusted, client.application == app,
                  client.element(kAXFocusedWindowAttribute, of: app) == target else { return .unavailable }
        }
        state.commit(application: app, revision: revision, order: order)
        return .performed
    }
}
