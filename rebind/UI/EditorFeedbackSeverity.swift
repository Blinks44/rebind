import SwiftUI

enum EditorFeedbackSeverity {
    case error, warning, information

    var symbol: String {
        switch self {
        case .error: "exclamationmark.circle"
        case .warning: "exclamationmark.triangle"
        case .information: "info.circle"
        }
    }

    var color: Color {
        switch self {
        case .error: Color(.editorError)
        case .warning: Color(.editorWarning)
        case .information: .accentColor
        }
    }

    var surface: Color {
        switch self {
        case .error: Color(.editorErrorSurface)
        case .warning: Color(.editorWarningSurface)
        case .information: Color(.editorInfoSurface)
        }
    }
}
