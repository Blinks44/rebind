import Foundation

/// Offline catalog revision; installed entries become ordinary editable bindings.
nonisolated enum StarterSetup: String, CaseIterable, Identifiable, Sendable {
    static let catalogVersion = 1
    case browser, windows, magicMouse, mouse
    var id: String { rawValue }

    func entries(safari: ApplicationTarget?) -> [StarterSetupEntry] {
        let browserTarget =
            safari ?? ApplicationTarget(url: URL(filePath: "/Applications/Safari.app"), bundleIdentifier: "com.apple.Safari")
        switch self {
        case .browser:
            return [
                entry("back", .mouseButton(3), .control, .shortcut(KeyboardShortcut(keyCode: 33, modifiers: .command)), app: browserTarget),
                entry(
                    "forward", .mouseButton(4), .control, .shortcut(KeyboardShortcut(keyCode: 30, modifiers: .command)), app: browserTarget),
                entry(
                    "reload", .mouseButton(2), .control, .shortcut(KeyboardShortcut(keyCode: 15, modifiers: .command)), app: browserTarget),
            ]
        case .windows:
            return [
                entry("left", .key(123), [.control, .option], .windowLayout(.leftHalf)),
                entry("right", .key(124), [.control, .option], .windowLayout(.rightHalf)),
                entry("fill", .key(126), [.control, .option], .windowLayout(.fill)),
            ]
        case .magicMouse:
            return [
                entry("mission", .magicMouseTap(fingers: 3), [], .dock(.missionControl)),
                entry("windows", .magicMouseClick(fingers: 2), [], .dock(.applicationWindows)),
                entry("desktop", .magicMouseClick(fingers: 3), [], .dock(.showDesktop)),
            ]
        case .mouse:
            return [
                entry("copy", .mouseButton(3), .control, .shortcut(KeyboardShortcut(keyCode: 8, modifiers: .command))),
                entry("paste", .mouseButton(4), .control, .shortcut(KeyboardShortcut(keyCode: 9, modifiers: .command))),
                entry("mission", .mouseButton(2), .control, .dock(.missionControl)),
            ]
        }
    }

    private func entry(
        _ id: String, _ trigger: InputTrigger, _ modifiers: ModifierSet, _ action: RebindAction, app: ApplicationTarget? = nil
    ) -> StarterSetupEntry {
        StarterSetupEntry(
            id: rawValue + "." + id,
            binding: Binding(scope: trigger.scope, trigger: trigger, modifiers: modifiers, action: action, application: app))
    }
}

nonisolated struct StarterSetupEntry: Identifiable, Sendable {
    let id: String
    let binding: Binding
}

nonisolated struct StarterSetupReview: Sendable {
    enum Availability: Equatable, Sendable {
        case available, alreadyAdded
        case conflict(Binding)
        case missingApplication
    }
    struct Row: Identifiable, Sendable {
        let entry: StarterSetupEntry
        let availability: Availability
        var id: String { entry.id }
    }
    let configuration: Configuration
    let destinationID: UUID?
    let rows: [Row]
    let selectedIDs: Set<String>

    init(setup: StarterSetup, selectedIDs: Set<String>, destinationID: UUID?, configuration: Configuration, safari: ApplicationTarget?) {
        self.configuration = configuration
        self.destinationID = destinationID
        self.selectedIDs = selectedIDs
        let existing = configuration.profiles.first { $0.id == destinationID }?.bindings ?? []
        rows = setup.entries(safari: safari).map { entry in
            let availability: Availability
            if setup == .browser && safari == nil {
                availability = .missingApplication
            } else if let used = existing.first(where: { Self.overlaps($0, entry.binding) }) {
                availability = Self.sameMapping(used, entry.binding) ? .alreadyAdded : .conflict(used)
            } else {
                availability = .available
            }
            return Row(entry: entry, availability: availability)
        }
    }

    var additions: [Binding] {
        rows.filter { selectedIDs.contains($0.id) && $0.availability == .available }.map { $0.entry.binding }
    }
    var skippedCount: Int { rows.filter { $0.availability != .available }.count }

    /// Reserve disabled inputs too. General/app-specific overlaps are skipped rather than
    /// silently introducing an override; distinct app-specific scopes remain independent.
    private static func overlaps(_ lhs: Binding, _ rhs: Binding) -> Bool {
        let appOverlaps =
            lhs.application == nil || rhs.application == nil || lhs.application?.bundleIdentifier == rhs.application?.bundleIdentifier
        guard appOverlaps else { return false }
        if lhs.matchKey == rhs.matchKey { return true }
        var pair = [lhs, rhs]
        pair[0].isEnabled = true
        pair[1].isEnabled = true
        do {
            try Configuration(bindings: pair).validate()
            return false
        } catch ConfigurationError.conflict { return true } catch { return false }
    }

    private static func sameMapping(_ lhs: Binding, _ rhs: Binding) -> Bool {
        var normalized = lhs
        normalized.id = rhs.id
        normalized.isEnabled = rhs.isEnabled
        normalized.note = rhs.note
        normalized.application = lhs.application?.bundleIdentifier == rhs.application?.bundleIdentifier ? rhs.application : lhs.application
        return normalized == rhs
    }

    func installing(name: String) throws -> (configuration: Configuration, result: StarterSetupResult) {
        guard !additions.isEmpty, selectedIDs.isSubset(of: Set(rows.map(\.id))) else { throw ConfigurationError.invalid }
        var updated = configuration
        let profileID: UUID
        if let destinationID {
            guard let index = updated.profiles.firstIndex(where: { $0.id == destinationID }) else {
                throw ConfigurationError.profileInvalid
            }
            profileID = destinationID
            updated.profiles[index].bindings.append(contentsOf: additions.map { $0.duplicated() })
        } else {
            guard updated.profiles.count < Configuration.maximumProfiles else { throw ConfigurationError.profileLimit }
            let profile = RuleProfile(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines), bindings: additions.map { $0.duplicated() })
            profileID = profile.id
            updated.profiles.append(profile)
        }
        try updated.validate()
        return (updated, StarterSetupResult(profileID: profileID, addedCount: additions.count, createdProfile: destinationID == nil))
    }
}

nonisolated struct StarterSetupResult: Sendable {
    let profileID: UUID
    let addedCount: Int
    let createdProfile: Bool
}
