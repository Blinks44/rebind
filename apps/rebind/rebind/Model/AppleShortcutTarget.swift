import Foundation

nonisolated struct AppleShortcutTarget: Codable, Equatable, Hashable, Identifiable, Sendable {
    enum ListError: Error { case invalidOutput }
    var id: UUID
    var name: String

    var isSupported: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.utf8.count <= 512
            && !name.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
    }

    static func parseList(_ data: Data) throws -> [Self] {
        guard data.count <= 262_144, let text = String(data: data, encoding: .utf8) else {
            throw ListError.invalidOutput
        }
        var targets: [Self] = []
        var identifiers = Set<UUID>()
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard targets.count < 4096, line.hasSuffix(")"),
                  let suffix = line.range(of: " (", options: .backwards),
                  let id = UUID(uuidString: String(line[suffix.upperBound..<line.index(before: line.endIndex)])) else {
                throw ListError.invalidOutput
            }
            let target = Self(id: id, name: String(line[..<suffix.lowerBound]))
            guard target.isSupported, identifiers.insert(id).inserted else { throw ListError.invalidOutput }
            targets.append(target)
        }
        return targets
    }
}
