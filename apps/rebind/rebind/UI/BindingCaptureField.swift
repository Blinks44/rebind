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
    @Environment(\.displayScale) private var displayScale

    private var isListening: Bool { recording?.target == target }
    private var isOutput: Bool { target == .output || target == .tapOutput }

    var body: some View {
        Group {
            if isListening {
                HStack(spacing: 12) {
                    Circle().fill(Theme.danger).frame(width: 12, height: 12).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prompt).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                        Text(isOutput ? LocalizedStringResource.mouseOutputListeningHelp : .mouseListeningHelp)
                            .font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    }.fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button(.cancelRecording, action: cancel).focused($cancelFocused)
                        .keyboardShortcut(.cancelAction)
                        .secondaryButton()
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
                .strokeBorder(isListening ? Theme.accent : Theme.borderSubtle, lineWidth: isListening ? Theme.accentBorderWidth(displayScale: displayScale) : 1)
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
                        Text(isOutput ? LocalizedStringResource.mouseNoOutput : .mouseNoTrigger)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }.font(Theme.body)
            .frame(minHeight: Theme.controlHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recordButton: some View {
        Button(isOutput ? LocalizedStringResource.editorRecordOutput : .editorRecordTrigger, action: record)
            .secondaryButton()
            .accessibilityLabel(Text(isOutput ? LocalizedStringResource.recordOutput : .recordTrigger))
            .focused($recordFocused).disabled(!canRecord || recording != nil)
    }

    private var clearButton: some View {
        Button(action: clear) {
            Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundStyle(Theme.iconTertiary)
                .frame(width: 28, height: 28).contentShape(.rect)
        }
            .buttonStyle(.plain)
            .keyboardFocusRing(Circle())
            .accessibilityLabel(Text(isOutput ? LocalizedStringResource.mouseClearOutput : .mouseClearTrigger))
            .disabled(value == nil || recording != nil)
    }

    private var prompt: LocalizedStringResource {
        switch target {
        case .output, .tapOutput: .mouseOutputListening
        case .scrollTrigger: .mouseWheelListening
        case .mouseTrigger, .gestureTrigger, .buttonScrollTrigger: .mouseButtonListening
        case .keyboardTrigger: .listeningHint
        }
    }
}
