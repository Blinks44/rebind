import AppKit
import Foundation

extension StarterSetup {
    var title: LocalizedStringResource {
        switch self {
        case .browser: .starterBrowserTitle
        case .windows: .starterWindowsTitle
        case .magicMouse: .starterMagicTitle
        case .mouse: .starterMouseTitle
        }
    }
    var summary: LocalizedStringResource {
        switch self {
        case .browser: .starterBrowserSummary
        case .windows: .starterWindowsSummary
        case .magicMouse: .starterMagicSummary
        case .mouse: .starterMouseSummary
        }
    }
    var introduction: LocalizedStringResource {
        switch self {
        case .browser: .starterBrowserIntro
        case .windows: .starterWindowsIntro
        case .magicMouse: .starterMagicIntro
        case .mouse: .starterMouseIntro
        }
    }
    var guidance: LocalizedStringResource {
        switch self {
        case .browser: .starterBrowserGuidance
        case .windows: .starterWindowsGuidance
        case .magicMouse: .starterMagicGuidance
        case .mouse: .starterMouseGuidance
        }
    }
}

enum StarterSetupAvailability {
    static func safari() -> ApplicationTarget? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari"),
            let target = ApplicationTarget(bundleURL: url), target.bundleIdentifier == "com.apple.Safari"
        else { return nil }
        return target
    }
}
