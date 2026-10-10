import AppKit
import ApplicationServices
import Darwin

@MainActor struct NativePreviousApplicationClient: PreviousApplicationClient {
    var frontmostApplication: NSRunningApplication? { NSWorkspace.shared.frontmostApplication }
    func isOwnApplication(_ application: NSRunningApplication) -> Bool {
        application.processIdentifier == getpid() || application.bundleIdentifier == "blinks44.rebind"
    }
    func isEligible(_ application: NSRunningApplication) -> Bool {
        application.processIdentifier > 0 && !isOwnApplication(application)
            && !application.isTerminated && application.activationPolicy == .regular
    }
    func activate(_ application: NSRunningApplication, from source: NSRunningApplication,
                  canPerform: @escaping @Sendable () -> Bool) async -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard isEligible(application), !source.isTerminated,
              frontmostApplication == source else { return .unavailable }
        // Creation does not query the target. Each handle is transferred once;
        // no NSRunningApplication object or shared history crosses actor boundaries.
        let targetElement = AXUIElementCreateApplication(application.processIdentifier)
        let sourceElement = AXUIElementCreateApplication(source.processIdentifier)
        return await ApplicationActivationExecutor.perform(target: targetElement, source: sourceElement,
            authorize: {
                guard canPerform() else { return .cancelled }
                guard self.isEligible(application), !source.isTerminated,
                      self.frontmostApplication == source else { return .unavailable }
                return .performed
            }, canPerform: canPerform)
    }
}
