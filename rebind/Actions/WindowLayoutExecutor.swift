import ApplicationServices
import Darwin

nonisolated protocol WindowLayoutAccessibility: WindowAccessibility {
    func isStandardWindow(_ element: Element) -> Bool
    func isMinimized(_ element: Element) -> Bool?
    func frame(of element: Element) -> CGRect?
    func setPosition(_ position: CGPoint, of element: Element) -> Bool
    func setSize(_ size: CGSize, of element: Element) -> Bool
}

nonisolated enum WindowLayoutExecutor {
    static func perform(_ action: WindowLayoutAction, displays: [WindowDisplay], canPerform: () -> Bool) -> WindowActionResult {
        perform(action, displays: displays, client: AXWindowAccessibility(), ownPID: getpid(), canPerform: canPerform)
    }

    static func perform<Client: WindowLayoutAccessibility>(_ action: WindowLayoutAction, displays: [WindowDisplay],
                                                          client: Client, ownPID: pid_t,
                                                          canPerform: () -> Bool) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard client.trusted, let app = client.application, let pid = client.processID(of: app), pid > 0, pid != ownPID,
              let window = client.element(kAXFocusedWindowAttribute, of: app), client.processID(of: window) == pid,
              client.isWindow(window), client.isStandardWindow(window), client.isMinimized(window) == false,
              let current = client.frame(of: window),
              let target = WindowLayoutGeometry.target(action, window: current, displays: displays),
              WindowLayoutGeometry.valid(target), client.isSettable(kAXPositionAttribute, of: window),
              action == .center || client.isSettable(kAXSizeAttribute, of: window) else { return .unavailable }

        func gate() -> WindowActionResult? {
            guard canPerform() else { return .cancelled }
            guard client.trusted, client.application == app,
                  client.element(kAXFocusedWindowAttribute, of: app) == window,
                  client.isMinimized(window) == false else { return .unavailable }
            // AX reads can block; check cancellation again immediately before mutation.
            guard client.trusted else { return .unavailable }
            return canPerform() ? nil : .cancelled
        }
        // Separate AX writes are not atomic. On failure/cancellation we stop:
        // rolling back could mutate a window after focus or permission changed.
        if let result = gate() { return result }
        if action != .center {
            guard client.setSize(target.size, of: window) else { return .unavailable }
            if let result = gate() { return result }
        }
        guard client.setPosition(target.origin, of: window) else { return .unavailable }
        if action != .center {
            if let result = gate() { return result }
            // macOS may constrain the first resize at the old position.
            guard client.setSize(target.size, of: window) else { return .unavailable }
        }
        if let result = gate() { return result }
        guard let actual = client.frame(of: window), WindowLayoutGeometry.approximatelyEqual(actual, target) else { return .unavailable }
        return .performed
    }
}
