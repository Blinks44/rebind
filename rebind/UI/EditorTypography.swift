import SwiftUI

/// Logical-point sizes from the released Sketch editor text styles.
enum EditorTypography {
    static let title = Font.system(size: 24, weight: .bold)
    static let section = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 13)
    static let label = Font.system(size: 13, weight: .medium)
    static let caption = Font.system(size: 12)
}
