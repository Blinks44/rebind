import Foundation

nonisolated struct Configuration: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 9
    static let maximumProfiles = 20
    var schemaVersion: Int
    var isEnabled: Bool
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
        try result.validate()
        return result
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, isEnabled, bindings, profiles, selectedProfileID
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
    }

    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schemaVersion, forKey: .schemaVersion)
        try values.encode(isEnabled, forKey: .isEnabled)
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
