import ApplicationServices
import Darwin

nonisolated enum ApplicationActivationExecutor {
    // Transfer newly created, exclusively owned AX handles; AppKit history stays
    // on MainActor. IPC runs on the concurrent executor, never the UI or input tap.
    @concurrent static func perform(target: sending AXUIElement, source: sending AXUIElement,
                                   authorize: @escaping @MainActor @Sendable () -> WindowActionResult,
                                   canPerform: @escaping @Sendable () -> Bool) async -> WindowActionResult {
        await perform(target: target, source: source, client: AXWindowAccessibility(),
                      ownPID: getpid(), authorize: authorize, canPerform: canPerform)
    }

    nonisolated(nonsending) static func perform<Client: WindowAccessibility>(
        target: Client.Element, source: Client.Element, client: Client, ownPID: pid_t,
        authorize: @MainActor () -> WindowActionResult,
        canPerform: @Sendable () -> Bool
    ) async -> WindowActionResult {
        guard !Task.isCancelled, canPerform() else { return .cancelled }
        guard client.trusted, let pid = client.processID(of: target), pid > 0, pid != ownPID,
              target != source, client.application == source,
              client.isSettable(kAXFrontmostAttribute, of: target) else { return .unavailable }
        // AX reads can wait for another process. Revalidate retained AppKit
        // instances on their actor, then lifecycle again immediately before writing.
        let authorization = await authorize()
        guard authorization == .performed else { return authorization }
        guard client.application == source, client.trusted else { return .unavailable }
        guard !Task.isCancelled, canPerform() else { return .cancelled }
        guard client.setTrue(kAXFrontmostAttribute, of: target) else { return .unavailable }
        // Request acceptance alone is insufficient. Only read back focus; never
        // retry activation, launch an app or raise/restore a particular window.
        for attempt in 0...5 {
            guard !Task.isCancelled, canPerform() else { return .cancelled }
            guard client.trusted else { return .unavailable }
            guard let focused = client.application else { return .unavailable }
            if focused == target { return .performed }
            guard focused == source, attempt < 5 else { return .unavailable }
            do { try await Task.sleep(for: .milliseconds(20)) }
            catch { return .cancelled }
        }
        return .unavailable
    }
}
