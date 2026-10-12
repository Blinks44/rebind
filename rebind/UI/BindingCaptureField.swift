import SwiftUI

/// Replaces only the active capture field, leaving its previous value in the draft.
struct BindingCaptureField: View {
    let value: String?
    let target: RecordingTarget
    let recording: RecordingRequest?
    let canRecord: Bool
    let record: () -> Void
    let cancel: () -> Void
    let clear: () -> Void
    var wrapsControls = false
    var shortcut: KeyboardShortcut?
    @FocusState private var cancelFocused: Bool
    @FocusState private var recordFocused: Bool

    private var isListening: Bool { recording?.target == target }

    var body: some View {
        PermissionCard(insets: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 4)) {
            if isListening {
                VStack(spacing: 12) {
                    Image(systemName: target == .output ? "keyboard" : "computermouse")
                        .font(.title2).foregroundStyle(.tint).accessibilityHidden(true)
                    Text(prompt).font(.headline)
                    Text(target == .output ? LocalizedStringResource.mouseOutputListeningHelp : .mouseListeningHelp)
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Button(.cancelRecording, action: cancel).focused($cancelFocused)
                        .keyboardShortcut(.cancelAction)
                        .modifier(EditorSecondaryButton())
                }.frame(maxWidth: .infinity).padding(.vertical, 12).padding(.trailing, 8)
            } else {
                if wrapsControls {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { captureValue; recordButton.fixedSize(); clearButton }
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { captureValue; clearButton }
                            recordButton.fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else { HStack(spacing: 12) { captureValue; recordButton; clearButton } }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12).strokeBorder(Color(.editorTextPrimary).opacity(0.08))
        }
        .onChange(of: isListening) { wasListening, listening in
            if listening {
                cancelFocused = true
                AccessibilityNotification.Announcement(AppLocalization.string(prompt)).post()
            } else if wasListening { recordFocused = true }
        }
    }

    private var captureValue: some View {
        Group {
            if let shortcut { ShortcutKeycaps(shortcut: shortcut) }
            else {
                HStack(spacing: 12) {
                    if value != nil {
                        Image(systemName: "computermouse").accessibilityHidden(true)
                            .font(.system(size: 16)).frame(width: 20, height: 20)
                    }
                    Text(value ?? AppLocalization.string(target == .output ? .mouseNoOutput : .mouseNoTrigger))
                        .fixedSize(horizontal: false, vertical: true)
                }.padding(.leading, 4)
            }
        }.font(EditorTypography.body)
            .foregroundStyle(Color(.editorTextPrimary))
            .frame(minHeight: EditorMetrics.keycapHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recordButton: some View {
        Button(target == .output ? LocalizedStringResource.editorRecordOutput : .editorRecordTrigger, action: record)
            .modifier(EditorSecondaryButton())
            .accessibilityLabel(Text(target == .output ? LocalizedStringResource.recordOutput : .recordTrigger))
            .focused($recordFocused).disabled(!canRecord || recording != nil)
    }

    private var clearButton: some View {
        Button(action: clear) {
            Image(systemName: "xmark").font(.system(size: 16))
                .frame(width: 28, height: 28).contentShape(.rect)
        }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(target == .output ? LocalizedStringResource.mouseClearOutput : .mouseClearTrigger))
            .disabled(value == nil || recording != nil)
    }

    private var prompt: LocalizedStringResource {
        switch target {
        case .output: .mouseOutputListening
        case .scrollTrigger: .mouseWheelListening
        case .mouseTrigger, .gestureTrigger: .mouseButtonListening
        case .keyboardTrigger: .listeningHint
        }
    }
}
