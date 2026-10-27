import AppKit
import Darwin

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
    /// Whether it manages gaming mice with onboard profiles and gaming-keyboard lighting.
    var managesGamingMice = false

    /// Only identifiers checked against an installed bundle or the vendor's published ones.
    /// Logi Options+: com.logi.optionsplus (published) and its `logioptionsplus_agent` helper.
    /// G HUB: com.logi.ghub (also its launchd-started `lghub_system_tray`) and com.logi.ghub.agent,
    /// read from an installed G HUB on 2026-10-15 and rechecked 2026-10-18.
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

/// Follows companion apps as they launch and quit. Their device helpers (G HUB's agent,
/// the Options+ agent) are started by launchd, not Launch Services, so they never appear in
/// `NSWorkspace.runningApplications`; the whole process list is read instead. macOS has no public
/// launch notification for such processes. Scan every ten seconds only while relevant hardware
/// is connected; Launch Services changes and a newly connected vendor trigger one at once.
@MainActor @Observable final class CompanionAppMonitor {
    private(set) var running: [CompanionApp] = []
    @ObservationIgnored private var observation: NSKeyValueObservation?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var connectedVendors: Set<Int> = []
    @ObservationIgnored private let executablePaths: () -> [String]
    /// Bundle identifiers by executable path; a process's bundle never changes.
    @ObservationIgnored private var bundleIdentifiers: [String: String?] = [:]
    /// Called after the set of running apps changes.
    @ObservationIgnored var changed: () -> Void = {}

    init(executablePaths: @escaping () -> [String] = { CompanionAppMonitor.executablePaths() },
         initiallyRunning: [CompanionApp] = []) {
        self.executablePaths = executablePaths
        running = initiallyRunning
    }

    func start() {
        guard observation == nil else { return }
        refresh()
        observation = NSWorkspace.shared.observe(\.runningApplications) { [weak self] _, _ in
            Task { @MainActor in self?.refresh() }
        }
        updateTimer()
    }

    /// Called from HID discovery before probing/writing a newly connected device.
    func setConnectedVendors(_ vendors: Set<Int>) {
        let relevant = vendors.intersection(CompanionApp.known.map(\.vendorID))
        guard relevant != connectedVendors else { return }
        connectedVendors = relevant
        refresh()
        updateTimer()
    }

    private func updateTimer() {
        timer?.invalidate()
        timer = nil
        guard observation != nil, !connectedVendors.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        timer?.tolerance = 2
    }

    func stop() {
        observation?.invalidate()
        observation = nil
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        guard !connectedVendors.isEmpty else {
            if !running.isEmpty { running = []; changed() }
            return
        }
        let paths = executablePaths()
        let processes = paths.map { path in
            let bundleIdentifier = bundleIdentifiers[path] ?? {
                let identifier = Self.bundleIdentifier(ofExecutable: path)
                bundleIdentifiers[path] = identifier
                return identifier
            }()
            return (bundleIdentifier: bundleIdentifier, executableName: Optional((path as NSString).lastPathComponent))
        }
        let found = CompanionApp.running(in: processes, known: CompanionApp.known.filter { connectedVendors.contains($0.vendorID) })
        guard found != running else { return }
        running = found
        changed()
    }

    /// The running app that rewrites hardware settings of this mouse, if any: Options+ for every
    /// Logitech mouse, G HUB for gaming mice with onboard profiles.
    func controller(ofVendor vendorID: Int, gaming: Bool = false) -> CompanionApp? {
        running.first { $0.vendorID == vendorID && ($0.controlsHardwareSettings || (gaming && $0.managesGamingMice)) }
    }

    /// The executable of every process this user can see.
    private nonisolated static func executablePaths() -> [String] {
        let capacity = proc_listallpids(nil, 0)
        guard capacity > 0 else { return [] }
        // Room for processes that start between the two calls.
        var pids = [pid_t](repeating: 0, count: Int(capacity) + 64)
        let count = pids.withUnsafeMutableBytes { proc_listallpids($0.baseAddress, Int32($0.count)) }
        guard count > 0 else { return [] }
        var buffer = [UInt8](repeating: 0, count: Int(MAXPATHLEN) * 4)
        return pids.prefix(Int(count)).compactMap { pid in
            let length = pid > 0 ? proc_pidpath(pid, &buffer, UInt32(buffer.count)) : 0
            return length > 0 ? String(decoding: buffer.prefix(Int(length)), as: UTF8.self) : nil
        }
    }

    /// The identifier of the innermost bundle whose `Contents/MacOS` holds the executable.
    nonisolated static func bundleIdentifier(ofExecutable path: String) -> String? {
        guard let range = path.range(of: "/Contents/MacOS/", options: .backwards) else { return nil }
        return Bundle(path: String(path[..<range.lowerBound]))?.bundleIdentifier
    }
}
