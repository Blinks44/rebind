import Foundation

extension RuleProfile {
    var title: String { name ?? AppLocalization.string(.defaultProfile) }
}
