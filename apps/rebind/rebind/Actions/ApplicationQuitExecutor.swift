import AppKit
import Darwin

@MainActor protocol ApplicationQuitClient {
    associatedtype Application
    var applications: [Application] { get }
    func identity(of application: Application) -> QuitApplicationIdentity
    func terminate(_ application: Application) -> Bool
}

@MainActor enum ApplicationQuitExecutor {
    static func perform(_ target: ApplicationTarget, canPerform: () -> Bool) -> WindowActionResult {
        perform(target, client: NativeApplicationQuitClient(), ownPID: getpid(), canPerform: canPerform)
    }

    static func perform<Client: ApplicationQuitClient>(_ target: ApplicationTarget, client: Client,
                                                       ownPID: pid_t, canPerform: () -> Bool) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard target.isSupported else { return .unavailable }
        let matches = client.applications.filter { client.identity(of: $0).matches(target, ownPID: ownPID) }
        // Do not arbitrarily quit one of several instances of the selected copy.
        guard matches.count == 1, let application = matches.first else { return .unavailable }
        guard client.identity(of: application).matches(target, ownPID: ownPID) else { return .unavailable }
        guard canPerform() else { return .cancelled }
        // Accepted Quit can be delayed/cancelled by the app (e.g. save dialog).
        // Never wait for exit, retry, forceTerminate or confirm its dialogs.
        return client.terminate(application) ? .performed : .unavailable
    }
}

@MainActor private struct NativeApplicationQuitClient: ApplicationQuitClient {
    var applications: [NSRunningApplication] { NSWorkspace.shared.runningApplications }

    func identity(of application: NSRunningApplication) -> QuitApplicationIdentity {
        QuitApplicationIdentity(processID: application.processIdentifier, bundleIdentifier: application.bundleIdentifier,
                                url: application.bundleURL, isRegular: application.activationPolicy == .regular,
                                isTerminated: application.isTerminated)
    }

    func terminate(_ application: NSRunningApplication) -> Bool { application.terminate() }
}
