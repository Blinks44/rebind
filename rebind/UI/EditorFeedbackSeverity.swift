import SwiftUI

enum EditorFeedbackSeverity {
    case error, warning, success, information

    var symbol: String {
        switch self {
        case .error: "exclamationmark.circle"
        case .warning: "exclamationmark.triangle"
        case .success: "checkmark.circle"
        case .information: "info.circle"
        }
    }

    var color: Color {
        switch self {
        case .error: Color(.editorError)
        case .warning: Color(.editorWarning)
        case .success: Color(.permissionSuccess)
        case .information: .accentColor
        }
    }

    var surface: Color {
        switch self {
        case .error: Color(.editorErrorSurface)
        case .warning: Color(.editorWarningSurface)
        case .success: Color(.editorSuccessSurface)
        case .information: Color(.editorInfoSurface)
        }
    }
}
