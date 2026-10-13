import Foundation

nonisolated struct Configuration: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 34
    static let maximumProfiles = 20
    static let maximumExcludedApplications = 50
    var schemaVersion: Int
    var isEnabled: Bool
    /// Records an explicit setup dismissal without changing remapping intent.
    var hasCompletedSetup = false
    var languagePreference: AppLanguagePreference = .system
    /// Where Rebind is visible. With both off, opening the app again shows its window.
    var showsDockIcon = true
    var showsMenuBarIcon = true
    /// Whether launching Rebind (including at login) opens its main window.
    var opensWindowAtLaunch = true
    /// Apps in which Rebind leaves all input alone while they are in front.
    var excludedApplications: [ApplicationTarget] = []
    var pointerGestureDistance = PointerGestureDistance.standard
    /// Stepped mouse wheels only; trackpads and continuous wheels are never changed.
    var reversesMouseWheel = false
    var mouseWheelSpeed = MouseWheelSpeed.standard
    var profiles: [RuleProfile]
    var selectedProfileID: UUID

    init(schemaVersion: Int = Self.currentSchemaVersion, isEnabled: Bool = false, bindings: [Binding] = []) {
        self.schemaVersion = schemaVersion
        self.isEnabled = isEnabled
        profiles = [RuleProfile(id: RuleProfile.defaultID, name: nil, bindings: bindings)]
        selectedProfileID = RuleProfile.defaultID
    }

    var selectedProfile: RuleProfile? { profiles.first { $0.id == selectedProfileID } }

    // Existing rule editing and the engine operate only on the selected profile.
    var bindings: [Binding] {
        get { selectedProfile?.bindings ?? [] }
        set {
            guard let index = profiles.firstIndex(where: { $0.id == selectedProfileID }) else { return }
            profiles[index].bindings = newValue
        }
    }

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else { throw ConfigurationError.incompatible }
        guard !profiles.isEmpty, profiles.count <= Self.maximumProfiles,
              Set(profiles.map(\.id)).count == profiles.count, selectedProfile != nil,
              profiles.allSatisfy(\.hasValidName) else { throw ConfigurationError.profileInvalid }
        let names = profiles.compactMap(\.nameKey)
        guard Set(names).count == names.count else { throw ConfigurationError.profileInvalid }
        guard excludedApplications.count <= Self.maximumExcludedApplications,
              excludedApplications.allSatisfy(\.isSupported),
              Set(excludedApplications.map(\.bundleIdentifier)).count == excludedApplications.count else {
            throw ConfigurationError.invalid
        }
        let allBindings = profiles.flatMap(\.bindings)
        guard allBindings.count <= 1000, Set(allBindings.map(\.id)).count == allBindings.count,
              allBindings.allSatisfy(\.isValid) else { throw ConfigurationError.invalid }
        for profile in profiles {
            let enabled = profile.bindings.filter(\.isEnabled)
            let keys = enabled.map(\.matchKey)
            guard Set(keys).count == keys.count else { throw ConfigurationError.conflict }
            let gestures = Set(keys.filter { $0.trigger.holdsButton }.map(\.pressSource))
            // A plain press rule may share a button with its gestures (it runs on a click
            // without movement); hold and double press on that button stay ambiguous.
            guard !enabled.contains(where: {
                !$0.trigger.holdsButton && ($0.activation != .press || $0.holdsOutput)
                    && gestures.contains($0.matchKey.pressSource)
            }) else {
                throw ConfigurationError.conflict
            }
        }
    }

    /// Brings an older file to the current schema in memory. A file that claims an old schema
    /// but carries a newer feature is rejected instead of being silently upgraded.
    func migrated() throws -> Configuration {
        guard (1..<Self.currentSchemaVersion).contains(schemaVersion) else {
            try validate()
            return self
        }
        guard schemaVersion >= 34 || (excludedApplications.isEmpty && pointerGestureDistance == .standard
                                      && !reversesMouseWheel && mouseWheelSpeed == .standard),
              schemaVersion >= 33 || (languagePreference != .es && languagePreference != .zhHans),
              schemaVersion >= 6 || profiles.count == 1,
              profiles.flatMap(\.bindings).allSatisfy({ $0.minimumSchemaVersion <= schemaVersion }) else {
            throw ConfigurationError.invalid
        }
        var result = self
        if schemaVersion <= 12 {
            // Schemas 11 and 12 stored desktop actions with a shortcut; they are Dock requests now.
            for profile in result.profiles.indices {
                for index in result.profiles[profile].bindings.indices {
                    if case .desktop(let action, let shortcut) = result.profiles[profile].bindings[index].action {
                        guard shortcut.isSupported, schemaVersion == 11 || action.isSpaceNavigation else {
                            throw ConfigurationError.invalid
                        }
                        result.profiles[profile].bindings[index].action = .dock(action)
                    }
                }
            }
        }
        // Existing installations recover through the permission notice, not first-run setup.
        if schemaVersion <= 22 { result.hasCompletedSetup = true }
        result.schemaVersion = Self.currentSchemaVersion
        try result.validate()
        return result
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, isEnabled, hasCompletedSetup, languagePreference, bindings, profiles, selectedProfileID
        case showsDockIcon, showsMenuBarIcon, opensWindowAtLaunch, excludedApplications, pointerGestureDistance
        case reversesMouseWheel, mouseWheelSpeed
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let version = try values.decode(Int.self, forKey: .schemaVersion)
        guard (1...Self.currentSchemaVersion).contains(version) else { throw ConfigurationError.incompatible }
        let enabled = try values.decode(Bool.self, forKey: .isEnabled)
        if version < 6 {
            guard !values.contains(.profiles), !values.contains(.selectedProfileID) else { throw ConfigurationError.invalid }
            self.init(schemaVersion: version, isEnabled: enabled,
                      bindings: try values.decode([Binding].self, forKey: .bindings))
        } else {
            guard !values.contains(.bindings) else { throw ConfigurationError.invalid }
            self.init(schemaVersion: version, isEnabled: enabled)
            profiles = try values.decode([RuleProfile].self, forKey: .profiles)
            selectedProfileID = try values.decode(UUID.self, forKey: .selectedProfileID)
        }
        hasCompletedSetup = version >= 23 ? try values.decode(Bool.self, forKey: .hasCompletedSetup) : true
        languagePreference = version >= 24
            ? try values.decode(AppLanguagePreference.self, forKey: .languagePreference) : .system
        if version >= 33 {
            showsDockIcon = try values.decode(Bool.self, forKey: .showsDockIcon)
            showsMenuBarIcon = try values.decode(Bool.self, forKey: .showsMenuBarIcon)
            opensWindowAtLaunch = try values.decode(Bool.self, forKey: .opensWindowAtLaunch)
        }
        if version >= 34 {
            excludedApplications = try values.decode([ApplicationTarget].self, forKey: .excludedApplications)
            pointerGestureDistance = try values.decode(PointerGestureDistance.self, forKey: .pointerGestureDistance)
            reversesMouseWheel = try values.decode(Bool.self, forKey: .reversesMouseWheel)
            mouseWheelSpeed = try values.decode(MouseWheelSpeed.self, forKey: .mouseWheelSpeed)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schemaVersion, forKey: .schemaVersion)
        try values.encode(isEnabled, forKey: .isEnabled)
        if schemaVersion >= 23 { try values.encode(hasCompletedSetup, forKey: .hasCompletedSetup) }
        if schemaVersion >= 24 { try values.encode(languagePreference, forKey: .languagePreference) }
        if schemaVersion >= 33 {
            try values.encode(showsDockIcon, forKey: .showsDockIcon)
            try values.encode(showsMenuBarIcon, forKey: .showsMenuBarIcon)
            try values.encode(opensWindowAtLaunch, forKey: .opensWindowAtLaunch)
        }
        if schemaVersion >= 34 {
            try values.encode(excludedApplications, forKey: .excludedApplications)
            try values.encode(pointerGestureDistance, forKey: .pointerGestureDistance)
            try values.encode(reversesMouseWheel, forKey: .reversesMouseWheel)
            try values.encode(mouseWheelSpeed, forKey: .mouseWheelSpeed)
        }
        if schemaVersion < 6 {
            guard profiles.count == 1, selectedProfile != nil else { throw ConfigurationError.invalid }
            try values.encode(bindings, forKey: .bindings)
        } else {
            try values.encode(profiles, forKey: .profiles)
            try values.encode(selectedProfileID, forKey: .selectedProfileID)
        }
    }

    /// One profile as a shareable file: no other profiles, no app preferences, no excluded apps.
    func exportingProfile(_ id: UUID) throws -> Configuration {
        guard let profile = profiles.first(where: { $0.id == id }) else { throw ConfigurationError.profileInvalid }
        var result = Configuration()
        result.profiles = [profile]
        result.selectedProfileID = profile.id
        try result.validate()
        return result
    }

    mutating func selectProfile(_ id: UUID) throws {
        var updated = self
        updated.selectedProfileID = id
        try updated.validate()
        self = updated
    }

    mutating func createProfile(name: String, copying sourceID: UUID? = nil) throws {
        guard profiles.count < Self.maximumProfiles else { throw ConfigurationError.profileLimit }
        var copied: [Binding] = []
        if let sourceID {
            guard let source = profiles.first(where: { $0.id == sourceID }) else { throw ConfigurationError.profileInvalid }
            copied = source.bindings.map { $0.duplicated() }
        }
        let profile = RuleProfile(name: name.trimmingCharacters(in: .whitespacesAndNewlines), bindings: copied)
        var updated = self
        updated.profiles.append(profile)
        updated.selectedProfileID = profile.id
        try updated.validate()
        self = updated
    }

    mutating func renameProfile(_ id: UUID, name: String) throws {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { throw ConfigurationError.profileInvalid }
        var updated = self
        updated.profiles[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try updated.validate()
        self = updated
    }

    mutating func deleteProfile(_ id: UUID) throws {
        guard profiles.count > 1 else { throw ConfigurationError.lastProfile }
        guard profiles.contains(where: { $0.id == id }) else { throw ConfigurationError.profileInvalid }
        var updated = self
        updated.profiles.removeAll { $0.id == id }
        if selectedProfileID == id, let first = updated.profiles.first { updated.selectedProfileID = first.id }
        try updated.validate()
        self = updated
    }
}

nonisolated private extension Binding {
    /// The first schema whose files may contain this rule.
    var minimumSchemaVersion: Int {
        var version = 1
        func introduced(in schema: Int, _ applies: Bool) { if applies { version = max(version, schema) } }

        introduced(in: 2, trigger.isScroll)
        introduced(in: 3, activation != .press)
        introduced(in: 4, activation == .hold)
        introduced(in: 5, trigger.isPointerGesture)
        introduced(in: 22, trigger.isTrackpad)
        introduced(in: 25, trigger == .threeFingerTap)
        introduced(in: 26, trigger.isTrackpadDoubleTap)
        introduced(in: 27, trigger == .twoFingerDoubleTap)
        introduced(in: 30, trigger.isTrackpad && action.shortcut == nil)
        introduced(in: 32, scope == .magicTrackpad)
        introduced(in: 34, holdsOutput || note != nil || tapShortcut != nil || (trigger.isTrackpad && !modifiers.isEmpty))
        switch trigger {
        case .cornerTap: introduced(in: 28, true)
        case .trackpadClick: introduced(in: 29, true)
        case .buttonScroll: introduced(in: 34, true)
        default: break
        }
        switch action {
        case .shortcut: break
        case .system: introduced(in: 7, true)
        case .window: introduced(in: 8, true)
        case .workspace(let workspace):
            switch workspace {
            case .quitApplication, .openSystemSettings: introduced(in: 17, true)
            case .previousApplication: introduced(in: 21, true)
            default: introduced(in: 9, true)
            }
        case .appleShortcut: introduced(in: 10, true)
        case .desktop: introduced(in: 11, true)
        case .dock(let desktop): introduced(in: desktop.isSpaceNavigation ? 13 : 12, true)
        case .mouse(let mouse): introduced(in: mouse.isNewInSchema31 ? 31 : 14, true)
        case .media(let media): introduced(in: media.isBrightness ? 30 : 15, true)
        case .windowLayout(let layout): introduced(in: layout.isNewInSchema34 ? 34 : 16, true)
        case .sleepSystem: introduced(in: 18, true)
        case .lockScreen: introduced(in: 19, true)
        case .windowCycle: introduced(in: 20, true)
        case .doNothing, .control, .text, .modifier: introduced(in: 34, true)
        }
        return version
    }
}
