import SwiftUI

/// UI-only specimens: no AppModel, configuration store or input interception.
private struct EditorControlsPreview: View {
    @State private var activation: PressActivation = .press
    @State private var input: RecordingTarget = .scrollTrigger
    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(alignment: .leading, spacing: EditorMetrics.sectionSpacing) {
                VStack(alignment: .leading, spacing: EditorMetrics.fieldSpacing) {
                    Text(.triggerTitle).font(EditorTypography.section)
                    EditorMenuSelector(selection: $input, title: .mouseInputKind,
                        choices: [.mouseTrigger, .scrollTrigger],
                        label: { $0 == .scrollTrigger ? .mouseWheelInput : .mouseButtonInput })
                        .frame(width: EditorMetrics.mouseSelectorWidth)
                    BindingCaptureField(value: InputLabels.trigger(.scroll(.up), modifiers: .control), target: .scrollTrigger,
                        recording: nil, canRecord: true, record: {}, cancel: {}, clear: {})
                    EditorActivationPicker(selection: $activation)
                }
                VStack(alignment: .leading, spacing: EditorMetrics.fieldSpacing) {
                    EditorSelectorLabel(title: .outputShortcut, symbol: "command")
                        .modifier(EditorGlassSurface())
                    BindingCaptureField(value: nil, target: .output, recording: nil,
                        canRecord: true, record: {}, cancel: {}, clear: {},
                        shortcut: KeyboardShortcut(keyCode: 13, modifiers: .command))
                    BindingCaptureField(value: nil, target: .output, recording: nil,
                        canRecord: false, record: {}, cancel: {}, clear: {})
                }
            }.padding(EditorMetrics.inset)
        }.frame(width: 512).background { PermissionCanvas() }
    }
}

#Preview("Editor controls · Light") { EditorControlsPreview().preferredColorScheme(.light) }
#Preview("Editor controls · Dark") { EditorControlsPreview().preferredColorScheme(.dark) }
#Preview("Editor controls · Disabled") { EditorControlsPreview().disabled(true) }
