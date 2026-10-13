import Foundation

enum ProfileEditOperation: Identifiable {
    case create, duplicate(UUID), rename(UUID)

    var id: String {
        switch self {
        case .create: "create"
        case .duplicate(let id): "duplicate-\(id)"
        case .rename(let id): "rename-\(id)"
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .create: .newProfile
        case .duplicate: .duplicateProfile
        case .rename: .renameProfile
        }
    }
}
