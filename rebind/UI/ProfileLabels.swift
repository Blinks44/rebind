import Foundation

extension RuleProfile {
    var title: String { name ?? String(localized: .defaultProfile) }
}
