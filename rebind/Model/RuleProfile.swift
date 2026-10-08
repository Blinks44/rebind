import Foundation

nonisolated struct RuleProfile: Codable, Equatable, Identifiable, Sendable {
    // A deterministic legacy container makes repeated in-memory migrations stable.
    static let defaultID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
    var id: UUID
    // nil is the localized built-in name, never a persisted translation.
    var name: String?
    var bindings: [Binding]

    init(id: UUID = UUID(), name: String?, bindings: [Binding] = []) {
        self.id = id
        self.name = name
        self.bindings = bindings
    }

    var hasValidName: Bool {
        guard let name else { return id == Self.defaultID }
        return !name.isEmpty && name.count <= 80
            && name == name.trimmingCharacters(in: .whitespacesAndNewlines)
            && !name.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
    }

    var nameKey: String? {
        name?.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
