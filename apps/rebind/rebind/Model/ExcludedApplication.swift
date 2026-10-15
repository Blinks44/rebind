import Foundation

/// An app in which Rebind skips what the user turned off while it is in front.
nonisolated struct ExcludedApplication: Codable, Equatable, Sendable {
    var target: ApplicationTarget
    /// Bindings, gestures and wheel direction/speed keep working in this app.
    var allowsBindings = false
    var allowsSmoothScrolling = false

    var bundleIdentifier: String { target.bundleIdentifier }
}
