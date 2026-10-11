import SwiftUI

/// Opaque Light/Dark canvas colors from Rebind's live Sketch foundations.
struct PermissionCanvas: View {
    var body: some View {
        LinearGradient(colors: [Color(.permissionCanvasTop), Color(.permissionCanvasBottom)],
                       startPoint: .top, endPoint: .bottom)
    }
}
