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
    @FocusState private var cancelFocused: Bool
    @FocusState private var recordFocused: Bool

    private var isListening: Bool { recording?.target == target }

    var body: some View {
        PermissionCard {
            if isListening {
                VStack(spacing: 12) {
                    Image(systemName: target == .output ? "keyboard" : "computermouse")
                        .font(.title2).accessibilityHidden(true)
                    Text(prompt).font(.headline)
                    Text(target == .output ? LocalizedStringResource.mouseOutputListeningHelp : .mouseListeningHelp)
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Button(.cancelRecording, action: cancel).focused($cancelFocused)
                        .keyboardShortcut(.cancelAction)
                }.frame(maxWidth: .infinity).padding(.vertical, 12)
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
        .onChange(of: isListening) { wasListening, listening in
            if listening {
                cancelFocused = true
                AccessibilityNotification.Announcement(AppLocalization.string(prompt)).post()
            } else if wasListening { recordFocused = true }
        }
    }

    private var captureValue: some View {
        Text(value ?? AppLocalization.string(target == .output ? .mouseNoOutput : .mouseNoTrigger))
            .font(.headline).frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var recordButton: some View {
        Button(target == .output ? LocalizedStringResource.recordOutput : .recordTrigger, action: record)
            .focused($recordFocused).disabled(!canRecord || recording != nil)
    }

    private var clearButton: some View {
        Button(target == .output ? LocalizedStringResource.mouseClearOutput : .mouseClearTrigger,
               systemImage: "xmark", action: clear)
            .labelStyle(.iconOnly).buttonStyle(.borderless)
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
