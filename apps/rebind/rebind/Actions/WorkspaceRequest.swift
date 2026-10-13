import AppKit

nonisolated enum WorkspaceTarget: Equatable, Sendable {
    case application(ApplicationTarget, activateOnly: Bool)
    case document(URL)
    case quitApplication(ApplicationTarget)
    case previousApplication
}

nonisolated struct WorkspaceRequest: Equatable, Sendable {
    var dispatch: ActionDispatch
    var target: WorkspaceTarget
}

nonisolated enum WorkspacePreparation {
    // File metadata is read on the action thread, never inside the event tap or
    // by the UI polling callback. No content is opened during preparation.
    static func prepare(_ action: WorkspaceAction,
                        settingsApplication: () -> URL? = {
                            NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences")
                        }) -> WorkspaceTarget? {
        guard action.isSupported else { return nil }
        switch action {
        case .openApplication(let target), .activateApplication(let target), .quitApplication(let target):
            let url = target.url.standardizedFileURL.resolvingSymlinksInPath()
            guard let bundle = Bundle(url: url), bundle.bundleIdentifier == target.bundleIdentifier,
                  bundle.infoDictionary?["CFBundlePackageType"] as? String == "APPL" else { return nil }
            let prepared = ApplicationTarget(url: url, bundleIdentifier: target.bundleIdentifier)
            if case .quitApplication = action { return .quitApplication(prepared) }
            let activateOnly: Bool
            if case .activateApplication = action { activateOnly = true } else { activateOnly = false }
            return .application(prepared, activateOnly: activateOnly)
        case .previousApplication: return .previousApplication
        case .openSystemSettings:
            // Public Launch Services lookup; no pane URL/private scheme or hardcoded app path.
            guard let url = settingsApplication() else { return nil }
            return prepare(.openApplication(ApplicationTarget(url: url, bundleIdentifier: "com.apple.systempreferences")))
        case .openURL(let url): return .document(url)
        case .openFile(let url):
            let url = url.standardizedFileURL.resolvingSymlinksInPath()
            guard WorkspaceAction.isLocalFile(url), url.pathExtension.lowercased() != "app",
                  (try? url.checkResourceIsReachable()) == true else { return nil }
            return .document(url)
        }
    }
}
