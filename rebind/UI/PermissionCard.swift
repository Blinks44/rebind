import SwiftUI

/// Calm permission content surfaces; navigation retains the system material.
struct PermissionCard<Content: View>: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.permissionSurface), in: .rect(cornerRadius: 12))
            .overlay {
                if contrast == .increased {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(Color(nsColor: .separatorColor))
                }
            }
    }
}
