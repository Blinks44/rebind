import AppKit
import Carbon
import CoreGraphics

@MainActor final class WorkspaceActionExecutor {
    private let mailbox: EngineMailbox
    private let openApplication: (URL) async throws -> Void
    private let openDocument: (URL) async throws -> Void
    private let activateApplication: (ApplicationTarget) -> Bool
    private let quitApplication: (ApplicationTarget, () -> Bool) -> WindowActionResult
    private let previousApplication: (@escaping @Sendable () -> Bool) async -> WindowActionResult
    private let performAppleShortcut: @Sendable (AppleShortcutTarget, @escaping @Sendable () -> Bool) async -> AppleShortcutRunResult
    private let secureInput: @Sendable () -> Bool
    private let postingAllowed: @Sendable () -> Bool

    init(mailbox: EngineMailbox,
         previousApplication: @escaping (@escaping @Sendable () -> Bool) async -> WindowActionResult,
         openApplication: @escaping (URL) async throws -> Void = { try await NativeWorkspace.openApplication($0) },
         openDocument: @escaping (URL) async throws -> Void = { try await NativeWorkspace.openDocument($0) },
         activateApplication: @escaping (ApplicationTarget) -> Bool = { NativeWorkspace.activateApplication($0) },
         quitApplication: @escaping (ApplicationTarget, () -> Bool) -> WindowActionResult = {
             ApplicationQuitExecutor.perform($0, canPerform: $1)
         },
         performAppleShortcut: @escaping @Sendable (AppleShortcutTarget, @escaping @Sendable () -> Bool) async -> AppleShortcutRunResult = {
             await AppleShortcuts.run($0, canPerform: $1)
         },
         secureInput: @escaping @Sendable () -> Bool = { IsSecureEventInputEnabled() },
         postingAllowed: @escaping @Sendable () -> Bool = { CGPreflightPostEventAccess() }) {
        self.mailbox = mailbox
        self.openApplication = openApplication
        self.openDocument = openDocument
        self.activateApplication = activateApplication
        self.quitApplication = quitApplication
        self.previousApplication = previousApplication
        self.performAppleShortcut = performAppleShortcut
        self.secureInput = secureInput
        self.postingAllowed = postingAllowed
    }

    func service() async {
        guard let request = mailbox.claimWorkspace() else { return }
        var failed = false
        defer { mailbox.finishWorkspace(request, failed: failed) }
        guard !Task.isCancelled, mailbox.dispatchIsCurrent(request.dispatch) else { return }
        guard !secureInput() else { mailbox.captureLost(status: .secureInput); return }
        guard postingAllowed() else { mailbox.captureLost(status: .permissionRequired); return }
        guard mailbox.dispatchIsCurrent(request.dispatch) else { return }
        do {
            switch request.target {
            case .appleShortcut(let target):
                let mailbox = mailbox, postingAllowed = postingAllowed, secureInput = secureInput
                let result = await performAppleShortcut(target) {
                    !Task.isCancelled && mailbox.dispatchIsCurrent(request.dispatch)
                        && postingAllowed() && !secureInput()
                }
                guard result != .cancelled else { return }
                failed = result == .failed
            case .application(let target, activateOnly: true): failed = !activateApplication(target)
            case .application(let target, activateOnly: false): try await openApplication(target.url)
            case .quitApplication(let target):
                let result = quitApplication(target) {
                    !Task.isCancelled && self.mailbox.dispatchIsCurrent(request.dispatch)
                        && self.postingAllowed() && !self.secureInput()
                }
                guard result != .cancelled else { return }
                failed = result == .unavailable
            case .previousApplication:
                let mailbox = mailbox, postingAllowed = postingAllowed, secureInput = secureInput
                let result = await previousApplication {
                    !Task.isCancelled && mailbox.dispatchIsCurrent(request.dispatch)
                        && postingAllowed() && !secureInput()
                }
                guard result != .cancelled else { return }
                failed = result == .unavailable
            case .document(let url): try await openDocument(url)
            }
        } catch is CancellationError {
            // A cancelled waiter does not imply Launch Services recalled an
            // accepted request. Never retry or report a stale failure.
        } catch { failed = true }
        // finishWorkspace checks the generation again after await. A response
        // from an old profile cannot overwrite the new profile's error state.
    }
}

@MainActor private enum NativeWorkspace {
    static func openApplication(_ url: URL) async throws {
        _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration())
    }

    static func openDocument(_ url: URL) async throws {
        _ = try await NSWorkspace.shared.open(url, configuration: configuration())
    }

    static func activateApplication(_ target: ApplicationTarget) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            !$0.isTerminated && target.matchesRunningApplication(bundleIdentifier: $0.bundleIdentifier, url: $0.bundleURL)
        }) else { return false }
        // No deprecated ignoringOtherApps option and no cold launch fallback.
        return app.activate(options: [])
    }

    private static func configuration() -> NSWorkspace.OpenConfiguration {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = false
        configuration.allowsRunningApplicationSubstitution = false
        configuration.promptsUserIfNeeded = false
        configuration.addsToRecentItems = false
        return configuration
    }
}
