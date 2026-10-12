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
        Group {
            if isListening {
                HStack(spacing: 12) {
                    Circle().fill(Theme.danger).frame(width: 12, height: 12).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prompt).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                        Text(target == .output ? LocalizedStringResource.mouseOutputListeningHelp : .mouseListeningHelp)
                            .font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    }.fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button(.cancelRecording, action: cancel).focused($cancelFocused)
                        .keyboardShortcut(.cancelAction)
                        .modifier(EditorSecondaryButton())
                }
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
        .padding(.leading, 14).padding(.trailing, 10).padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(isListening ? Theme.accentTint : Theme.insetSurface, in: .rect(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isListening ? Theme.accent : Theme.borderSubtle, lineWidth: isListening ? 1.5 : 1)
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
                    if let value {
                        TriggerChip(label: value, symbol: target == .keyboardTrigger ? "keyboard" : "computermouse")
                    } else {
                        Text(target == .output ? LocalizedStringResource.mouseNoOutput : .mouseNoTrigger)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }.font(EditorTypography.body)
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
            Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundStyle(Theme.iconTertiary)
                .frame(width: 28, height: 28).contentShape(.rect)
        }
            .buttonStyle(.plain)
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
