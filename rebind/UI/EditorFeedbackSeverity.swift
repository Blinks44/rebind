import SwiftUI

enum EditorFeedbackSeverity {
    case error, warning, success, information

    var symbol: String {
        switch self {
        case .error: "xmark.circle"
        case .warning: "exclamationmark.triangle"
        case .success: "checkmark.circle"
        case .information: "info.circle"
        }
    }

    var color: Color {
        switch self {
        case .error: Theme.danger
        case .warning: Theme.warning
        case .success: Theme.success
        case .information: Theme.accent
        }
    }

    var textColor: Color {
        switch self {
        case .error: Theme.dangerText
        case .warning: Theme.warningText
        case .success: Theme.successText
        case .information: Theme.accent
        }
    }

    var surface: Color { color.opacity(0.12) }
}
