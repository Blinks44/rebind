import Foundation

extension ApplicationTarget {
    /// VM launchers may all be called VM.app; the bundle name identifies the selected VM.
    var exclusionDisplayName: String {
        let name = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String
        return name.flatMap { $0.isEmpty ? nil : $0 } ?? url.deletingPathExtension().lastPathComponent
    }
}
