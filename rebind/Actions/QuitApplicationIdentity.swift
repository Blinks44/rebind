import Foundation
import Darwin

nonisolated struct QuitApplicationIdentity: Sendable {
    var processID: pid_t
    var bundleIdentifier: String?
    var url: URL?
    var isRegular: Bool
    var isTerminated: Bool

    func matches(_ target: ApplicationTarget, ownPID: pid_t) -> Bool {
        target.isSupported && processID > 0 && processID != ownPID && isRegular && !isTerminated
            && target.matchesRunningApplication(bundleIdentifier: bundleIdentifier, url: url)
    }
}
