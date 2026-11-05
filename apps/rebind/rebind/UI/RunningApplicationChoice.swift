import AppKit

/// Snapshotted when the menu opens; selection keeps the exact identity shown to the user.
struct RunningApplicationChoice {
    let target: ApplicationTarget
    let name: String

    static func available(_ choices: [Self], excluding identifiers: Set<String>) -> [Self] {
        var seen = identifiers
        return choices.filter { $0.target.isSupported && seen.insert($0.target.bundleIdentifier).inserted }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func current(excluding identifiers: Set<String>) -> [Self] {
        let choices = NSWorkspace.shared.runningApplications.compactMap { app -> Self? in
            guard !app.isTerminated, app.activationPolicy == .regular,
                let url = app.bundleURL, let identifier = app.bundleIdentifier
            else { return nil }
            let target = ApplicationTarget(url: url, bundleIdentifier: identifier)
            return Self(target: target, name: target.exclusionDisplayName)
        }
        return available(choices, excluding: identifiers)
    }
}
