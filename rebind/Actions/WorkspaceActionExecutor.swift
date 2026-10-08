import AppKit
import Carbon
import CoreGraphics

@MainActor final class WorkspaceActionExecutor {
    private let mailbox: EngineMailbox
    private let openApplication: (URL) async throws -> Void
    private let openDocument: (URL) async throws -> Void
    private let activateApplication: (ApplicationTarget) -> Bool
    private let secureInput: () -> Bool
    private let postingAllowed: () -> Bool

    init(mailbox: EngineMailbox,
         openApplication: @escaping (URL) async throws -> Void = { try await NativeWorkspace.openApplication($0) },
         openDocument: @escaping (URL) async throws -> Void = { try await NativeWorkspace.openDocument($0) },
         activateApplication: @escaping (ApplicationTarget) -> Bool = { NativeWorkspace.activateApplication($0) },
         secureInput: @escaping () -> Bool = { IsSecureEventInputEnabled() },
         postingAllowed: @escaping () -> Bool = { CGPreflightPostEventAccess() }) {
        self.mailbox = mailbox
        self.openApplication = openApplication
        self.openDocument = openDocument
        self.activateApplication = activateApplication
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
            case .application(let target, activateOnly: true): failed = !activateApplication(target)
            case .application(let target, activateOnly: false): try await openApplication(target.url)
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
