import AppKit

/// A mouse maker's own app that talks to its mice directly. While it runs, it can take
/// extra buttons away from macOS (and so from Rebind) and overwrite wheel and pointer
/// settings, so Rebind says so and does not compete with it.
nonisolated struct CompanionApp: Hashable, Sendable {
    let name: String
    /// USB vendor of the mice it controls.
    let vendorID: Int
    /// Matches the app and its helpers: each process's bundle identifier starts with one of these.
    let bundlePrefixes: [String]
    /// Helpers known only by their executable name.
    let executableNames: [String]
    /// Processes of the vendor that do not control devices, such as an updater.
    var ignoredBundleIdentifiers: [String] = []
    /// Whether it rewrites the wheel and pointer settings of the vendor's everyday mice, which
    /// Rebind then leaves alone. G HUB manages gaming mice only, so it does not lock Devices.
    var controlsHardwareSettings = true
    /// Whether it manages gaming mice with onboard profiles (their DPI and profile mode).
    var managesGamingMice = false

    /// Only identifiers checked against an installed bundle or the vendor's published ones.
    /// Logi Options+: com.logi.optionsplus (published) and its `logioptionsplus_agent` helper.
    /// G HUB: com.logi.ghub and com.logi.ghub.agent, read from an installed G HUB on 2026-10-15.
    /// Other vendors (Razer Synapse, SteelSeries GG, the old Logitech Options) are not listed
    /// until their identifiers are verified the same way.
    static let known = [
        CompanionApp(name: "Logi Options+", vendorID: 0x046D,
                     bundlePrefixes: ["com.logi.optionsplus"], executableNames: ["logioptionsplus_agent"]),
        CompanionApp(name: "Logitech G HUB", vendorID: 0x046D,
                     bundlePrefixes: ["com.logi.ghub"], executableNames: [],
                     ignoredBundleIdentifiers: ["com.logi.ghub.updater"], controlsHardwareSettings: false,
                     managesGamingMice: true)
    ]

    func matches(bundleIdentifier: String?, executableName: String?) -> Bool {
        if let bundleIdentifier, ignoredBundleIdentifiers.contains(bundleIdentifier) { return false }
        if let bundleIdentifier, bundlePrefixes.contains(where: {
            bundleIdentifier == $0 || bundleIdentifier.hasPrefix($0 + ".")
        }) { return true }
        return executableName.map(executableNames.contains) ?? false
    }

    /// The known apps among running processes, each listed once, in `known` order.
    static func running(in processes: [(bundleIdentifier: String?, executableName: String?)],
                        known: [CompanionApp] = known) -> [CompanionApp] {
        known.filter { app in processes.contains { app.matches(bundleIdentifier: $0.bundleIdentifier, executableName: $0.executableName) } }
    }
}

/// Follows companion apps as they launch and quit. Their helpers run in the background,
/// which the launch notifications do not cover, so this observes the process list itself.
@MainActor @Observable final class CompanionAppMonitor {
    private(set) var running: [CompanionApp] = []
    @ObservationIgnored private var observation: NSKeyValueObservation?
    /// Called after the set of running apps changes.
    @ObservationIgnored var changed: () -> Void = {}

    func start() {
        guard observation == nil else { return }
        refresh()
        observation = NSWorkspace.shared.observe(\.runningApplications) { [weak self] _, _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
    }

    func refresh() {
        let processes = NSWorkspace.shared.runningApplications.map {
            (bundleIdentifier: $0.bundleIdentifier, executableName: $0.executableURL?.lastPathComponent)
        }
        let found = CompanionApp.running(in: processes)
        guard found != running else { return }
        running = found
        changed()
    }

    /// The running app that rewrites hardware settings of this mouse, if any: Options+ for every
    /// Logitech mouse, G HUB for gaming mice with onboard profiles.
    func controller(ofVendor vendorID: Int, gaming: Bool = false) -> CompanionApp? {
        running.first { $0.vendorID == vendorID && ($0.controlsHardwareSettings || (gaming && $0.managesGamingMice)) }
    }
}
