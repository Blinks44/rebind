import SwiftUI

struct BindingEditorSection<Content: View>: View {
    let usesCard: Bool
    @ViewBuilder var content: Content

    var body: some View {
        if usesCard { GroupBox { content } }
        else { content }
    }
}
