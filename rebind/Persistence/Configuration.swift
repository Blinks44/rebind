import Foundation

nonisolated struct Configuration: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 32
    static let maximumProfiles = 20
    var schemaVersion: Int
    var isEnabled: Bool
    /// Records an explicit setup dismissal without changing remapping intent.
    var hasCompletedSetup = false
    var languagePreference: AppLanguagePreference = .system
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
        let allBindings = profiles.flatMap(\.bindings)
        guard allBindings.count <= 1000, Set(allBindings.map(\.id)).count == allBindings.count,
              allBindings.allSatisfy(\.isValid) else { throw ConfigurationError.invalid }
        for profile in profiles {
            let keys = profile.bindings.filter(\.isEnabled).map(\.matchKey)
            guard Set(keys).count == keys.count else { throw ConfigurationError.conflict }
            let gestures = Set(keys.filter { $0.trigger.isPointerGesture }.map(\.pressSource))
            guard !keys.contains(where: { !$0.trigger.isPointerGesture && gestures.contains($0.pressSource) }) else {
                throw ConfigurationError.conflict
            }
        }
    }

    func migrated() throws -> Configuration {
        var result = self
        if schemaVersion < 32, profiles.flatMap(\.bindings).contains(where: { $0.scope == .magicTrackpad }) {
            throw ConfigurationError.invalid
        }
        if schemaVersion < 31, profiles.flatMap(\.bindings).contains(where: {
            if case .mouse(let mouse) = $0.action { return mouse.isNewInSchema31 }
            return false
        }) {
            throw ConfigurationError.invalid
        }
        if schemaVersion < 30, profiles.flatMap(\.bindings).contains(where: {
            if case .media(let media) = $0.action, media.isBrightness { return true }
            return $0.trigger.isTrackpad && $0.action.shortcut == nil
        }) {
            throw ConfigurationError.invalid
        }
        if schemaVersion < 29, profiles.flatMap(\.bindings).contains(where: {
            if case .trackpadClick = $0.trigger { return true }
            return false
        }) {
            throw ConfigurationError.invalid
        }
        if schemaVersion < 28, profiles.flatMap(\.bindings).contains(where: {
            if case .cornerTap = $0.trigger { return true }
            return false
        }) {
            throw ConfigurationError.invalid
        }
        if schemaVersion < 27, profiles.flatMap(\.bindings).contains(where: { $0.trigger == .twoFingerDoubleTap }) {
            throw ConfigurationError.invalid
        }
        if schemaVersion < 26, profiles.flatMap(\.bindings).contains(where: { $0.trigger.isTrackpadDoubleTap }) {
            throw ConfigurationError.invalid
        }
        if schemaVersion < 25, profiles.flatMap(\.bindings).contains(where: { $0.trigger == .threeFingerTap }) {
            throw ConfigurationError.invalid
        }
        if schemaVersion < 22, profiles.flatMap(\.bindings).contains(where: { $0.trigger.isTrackpad }) {
            throw ConfigurationError.invalid
        }
        if schemaVersion < 21, profiles.flatMap(\.bindings).contains(where: {
            if case .workspace(.previousApplication) = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 20, profiles.flatMap(\.bindings).contains(where: {
            if case .windowCycle = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 19, profiles.flatMap(\.bindings).contains(where: {
            if case .lockScreen = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 18, profiles.flatMap(\.bindings).contains(where: {
            if case .sleepSystem = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 17, profiles.flatMap(\.bindings).contains(where: {
            switch $0.action {
            case .workspace(.quitApplication), .workspace(.openSystemSettings): true
            default: false
            }
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 16, profiles.flatMap(\.bindings).contains(where: {
            if case .windowLayout = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 15, profiles.flatMap(\.bindings).contains(where: {
            if case .media = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 14, profiles.flatMap(\.bindings).contains(where: {
            if case .mouse = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 12, profiles.flatMap(\.bindings).contains(where: {
            if case .dock = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 13, profiles.flatMap(\.bindings).contains(where: {
            if case .dock(let action) = $0.action { return action.isSpaceNavigation }
            return false
        }) { throw ConfigurationError.invalid }
        if (11...12).contains(schemaVersion) {
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
            result.schemaVersion = Self.currentSchemaVersion
        }
        if schemaVersion < 11, profiles.flatMap(\.bindings).contains(where: {
            if case .desktop = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if schemaVersion < 10, profiles.flatMap(\.bindings).contains(where: {
            if case .appleShortcut = $0.action { return true }
            return false
        }) { throw ConfigurationError.invalid }
        if (1...5).contains(schemaVersion) {
            guard profiles.count == 1,
                  schemaVersion >= 5 || bindings.allSatisfy({ !$0.trigger.isPointerGesture }),
                  schemaVersion >= 4 || bindings.allSatisfy({ $0.activation != .hold }),
                  schemaVersion >= 3 || bindings.allSatisfy({ $0.activation == .press }),
                  schemaVersion != 1 || bindings.allSatisfy({ !$0.trigger.isScroll }) else {
                throw ConfigurationError.invalid
            }
            result.schemaVersion = Self.currentSchemaVersion
        }
        if (1...6).contains(schemaVersion) {
            guard profiles.flatMap(\.bindings).allSatisfy({ $0.action.shortcut != nil }) else {
                throw ConfigurationError.invalid
            }
            result.schemaVersion = Self.currentSchemaVersion
        }
        if schemaVersion == 7 {
            guard profiles.flatMap(\.bindings).allSatisfy({
                if case .window = $0.action { return false }
                if case .workspace = $0.action { return false }
                return true
            }) else { throw ConfigurationError.invalid }
            result.schemaVersion = Self.currentSchemaVersion
        }
        if schemaVersion == 8 {
            guard profiles.flatMap(\.bindings).allSatisfy({
                if case .workspace = $0.action { return false }
                return true
            }) else { throw ConfigurationError.invalid }
            result.schemaVersion = Self.currentSchemaVersion
        }
        if (9...10).contains(schemaVersion) { result.schemaVersion = Self.currentSchemaVersion }
        if (13...31).contains(schemaVersion) { result.schemaVersion = Self.currentSchemaVersion }
        // Existing installations recover through the permission notice, not first-run setup.
        if (1...22).contains(schemaVersion) { result.hasCompletedSetup = true }
        try result.validate()
        return result
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, isEnabled, hasCompletedSetup, languagePreference, bindings, profiles, selectedProfileID
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
    }

    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schemaVersion, forKey: .schemaVersion)
        try values.encode(isEnabled, forKey: .isEnabled)
        if schemaVersion >= 23 { try values.encode(hasCompletedSetup, forKey: .hasCompletedSetup) }
        if schemaVersion >= 24 { try values.encode(languagePreference, forKey: .languagePreference) }
        if schemaVersion < 6 {
            guard profiles.count == 1, selectedProfile != nil else { throw ConfigurationError.invalid }
            try values.encode(bindings, forKey: .bindings)
        } else {
            try values.encode(profiles, forKey: .profiles)
            try values.encode(selectedProfileID, forKey: .selectedProfileID)
        }
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
            copied = source.bindings.map { original in
                var binding = original
                binding.id = UUID()
                return binding
            }
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
