import Foundation

/// Describes running capture separately from saved intent, access and protection.
nonisolated enum GeneralRuntimePresentation: Equatable {
    case active, paused, starting, missingAccess, engineError, secureInput, suspended, storageLocked

    init(isEnabled: Bool, permissions: InputPermissions, status: EngineStatus,
         isSuspended: Bool, storageLocked: Bool) {
        if storageLocked { self = .storageLocked }
        else if !isEnabled { self = .paused }
        else if !permissions.allowsRemapping { self = .missingAccess }
        else if isSuspended { self = .suspended }
        else {
            switch status {
            case .active: self = .active
            case .paused: self = .starting
            case .secureInput: self = .secureInput
            case .tapFailed, .interrupted, .outputFailed: self = .engineError
            case .permissionRequired: self = .starting
            }
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .active: .remappingActive
        case .paused: .remappingPaused
        case .starting: .remappingStarting
        case .engineError: .remappingEngineError
        case .missingAccess, .secureInput, .suspended, .storageLocked: .remappingUnavailable
        }
    }

    var description: LocalizedStringResource {
        switch self {
        case .active: .remappingActiveDescription
        case .paused: .remappingPausedDescription
        case .starting: .remappingStarting
        case .missingAccess: .remappingUnavailableDescription
        case .engineError: .remappingEngineErrorDescription
        case .secureInput: .secureInputPaused
        case .suspended: .remappingSessionSuspended
        case .storageLocked: .storageUnreadable
        }
    }
}
