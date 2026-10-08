import Foundation

nonisolated enum WorkspaceTarget: Equatable, Sendable {
    case application(ApplicationTarget, activateOnly: Bool)
    case document(URL)
}

nonisolated struct WorkspaceRequest: Equatable, Sendable {
    var dispatch: ActionDispatch
    var target: WorkspaceTarget
}

nonisolated enum WorkspacePreparation {
    // File metadata is read on the action thread, never inside the event tap or
    // by the UI polling callback. No content is opened during preparation.
    static func prepare(_ action: WorkspaceAction) -> WorkspaceTarget? {
        guard action.isSupported else { return nil }
        switch action {
        case .openApplication(let target), .activateApplication(let target):
            let url = target.url.standardizedFileURL.resolvingSymlinksInPath()
            guard let bundle = Bundle(url: url), bundle.bundleIdentifier == target.bundleIdentifier,
                  bundle.infoDictionary?["CFBundlePackageType"] as? String == "APPL" else { return nil }
            let activateOnly: Bool
            if case .activateApplication = action { activateOnly = true } else { activateOnly = false }
            return .application(ApplicationTarget(url: url, bundleIdentifier: target.bundleIdentifier), activateOnly: activateOnly)
        case .openURL(let url): return .document(url)
        case .openFile(let url):
            let url = url.standardizedFileURL.resolvingSymlinksInPath()
            guard WorkspaceAction.isLocalFile(url), url.pathExtension.lowercased() != "app",
                  (try? url.checkResourceIsReachable()) == true else { return nil }
            return .document(url)
        }
    }
}
