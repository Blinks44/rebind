import AppKit
import SwiftUI

struct BindingEditor: View {
    let model: AppModel
    let scope: DeviceScope
    let existing: Binding?
    /// A copy opens prefilled but is saved as a new rule.
    let isCopy: Bool
    private let profileID: UUID
    private let configurationRevision: UInt64
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BindingEditorDraft
    @State private var recordingRequest: RecordingRequest?
    @State private var showingPermissions = false
    @State private var confirmingDeletion = false
    @State private var actionKind: ActionKind
    @State private var application: ApplicationTarget?
    @State private var webAddress: String
    @State private var file: URL?
    @State private var appleShortcut: AppleShortcutTarget?
    @State private var snippet: String

    init(model: AppModel, scope: DeviceScope, existing: Binding?, isCopy: Bool = false) {
        self.model = model
        self.isCopy = isCopy
        self.scope = scope
        self.existing = existing
        profileID = model.configuration.selectedProfileID
        configurationRevision = model.configurationReplacementRevision
        _draft = State(initialValue: BindingEditorDraft(scope: scope, existing: existing))
        _actionKind = State(initialValue: existing.map(ActionKind.init(binding:)) ?? .keyboardShortcut)
        let workspace: WorkspaceAction?
        if case .workspace(let value) = existing?.action { workspace = value } else { workspace = nil }
        _application = State(initialValue: workspace?.application)
        if case .openURL(let url) = workspace { _webAddress = State(initialValue: url.absoluteString) }
        else { _webAddress = State(initialValue: "") }
        if case .openFile(let url) = workspace { _file = State(initialValue: url) }
        else { _file = State(initialValue: nil) }
        if case .appleShortcut(let target) = existing?.action { _appleShortcut = State(initialValue: target) }
        else { _appleShortcut = State(initialValue: nil) }
        if case .text(let text) = existing?.action { _snippet = State(initialValue: text) }
        else { _snippet = State(initialValue: "") }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(existing == nil || isCopy ? LocalizedStringResource.addBinding : .editBinding)
                            .font(Theme.titleSmall).foregroundStyle(Theme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text(scopeCaption).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    switch scope {
                    case .allMice: MouseTriggerEditor(draft: $draft, model: model, record: { record(draft.mouseTarget) },
                                                      recordTapOutput: { record(.tapOutput) })
                    case .builtInTrackpad, .magicTrackpad: TrackpadTriggerEditor(draft: $draft, isRecording: model.recording != nil)
                    case .magicMouse: MagicMouseTriggerEditor(draft: $draft, isRecording: model.recording != nil)
                    case .allKeyboards: keyboardTrigger
                    }
                    action
                    RuleApplicationField(application: $draft.ruleApplication)
                        .disabled(model.recording != nil)
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(.bindingNoteTitle)
                        ThemeTextField(title: .bindingNoteTitle, text: $draft.note, prompt: Text(.bindingNotePrompt))
                            .disabled(model.recording != nil)
                            .accessibilityIdentifier("binding-editor-note")
                    }
                    feedback
                }.padding(28)
            }
            Theme.separator.frame(height: 1)
            HStack(spacing: 10) {
                if existing != nil, !isCopy {
                    Button(.deleteBinding, systemImage: "trash") { model.cancelRecording(); confirmingDeletion = true }
                        .destructiveButton()
                        .disabled(model.recording != nil || model.storageLocked)
                }
                Spacer()
                Button(.cancel) { model.cancelRecording(); dismiss() }
                    .accessibilityIdentifier("binding-editor-cancel")
                    .secondaryButton().controlSize(.large)
                Button(.editorSaveBinding, action: save).keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("binding-editor-save")
                    .primaryButton()
                    .disabled(candidate == nil || validationError != nil
                        || !actionKind.isAvailable(with: model.audioCapabilities)
                        || model.recording != nil || model.storageLocked)
            }.padding(.horizontal, 28).padding(.vertical, 20)
        }
        .frame(width: 520).frame(idealHeight: 640, maxHeight: 760)
        .background(Theme.sheetSurface)
        .alert(.deleteBinding, isPresented: $confirmingDeletion) {
            Button(.cancel, role: .cancel) { }
            Button(.deleteBinding, role: .destructive) {
                guard let existing, configurationRevision == model.configurationReplacementRevision else { dismiss(); return }
                model.delete(existing.id)
                dismiss()
            }
        } message: { Text(.deleteBindingConfirmation) }
        .onExitCommand { if model.recording != nil { model.cancelRecording() } else { dismiss() } }
        .sheet(isPresented: $showingPermissions) { PermissionSetupView(model: model, context: .recovery) }
        .onAppear { model.error = nil; model.beginEditing() }
        .onDisappear { model.endEditing() }
        .onChange(of: model.configurationReplacementRevision) { dismiss() }
        .onChange(of: draft.mouseTarget) {
            model.cancelRecording()
            recordingRequest = nil
            draft.selectMouseTarget(draft.mouseTarget)
        }
        .onChange(of: actionKind) { model.cancelRecording() }
        .onChange(of: draft.activation) { model.cancelRecording() }
        .onChange(of: draft.holdDurationMilliseconds) { model.cancelRecording() }
        .onChange(of: draft.pointerDirection) { model.cancelRecording() }
        .onChange(of: draft.scrollDirection) { model.cancelRecording() }
        .onChange(of: draft.magicMousePreset) { model.cancelRecording(); recordingRequest = nil }
        .onChange(of: draft.trackpadPreset) {
            model.cancelRecording()
            recordingRequest = nil
        }
        .onChange(of: model.lastRecording?.request.id) {
            guard let recorded = model.lastRecording else { return }
            draft.accept(recorded, for: recordingRequest, scope: scope)
            recordingRequest = nil
        }
        .onChange(of: model.recording?.id) {
            if model.recording == nil, model.lastRecording?.request != recordingRequest {
                recordingRequest = nil
            }
        }
        .onChange(of: validationError) {
            if validationError == .conflict {
                AccessibilityNotification.Announcement(AppLocalization.string(conflictHelp)).post()
            }
        }
    }

    private var scopeCaption: LocalizedStringResource {
        let profile = model.configuration.selectedProfile?.title ?? ""
        switch scope {
        case .allMice: return .mouseEditorScope(profile)
        case .builtInTrackpad: return .trackpadEditorScope(profile)
        case .magicTrackpad: return .magicTrackpadEditorScope(profile)
        case .magicMouse: return .magicMouseEditorScope(profile)
        case .allKeyboards: return .keyboardEditorScope(profile)
        }
    }

    private var keyboardTrigger: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(.triggerTitle)
            BindingCaptureField(value: draft.trigger.map { InputLabels.trigger($0.trigger, modifiers: $0.modifiers) },
                target: .keyboardTrigger, recording: model.recording, canRecord: model.canRecord,
                record: { record(.keyboardTrigger) }, cancel: model.cancelRecording,
                clear: { draft.trigger = nil }, shortcut: keyboardTriggerShortcut)
            Text(.recordingLimitations).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            SectionLabel(.activationTitle).padding(.top, 8)
            ActivationPicker(selection: $draft.activation).frame(maxWidth: .infinity)
                .disabled(model.recording != nil)
            if draft.activation == .hold {
                HoldDurationRow(milliseconds: $draft.holdDurationMilliseconds).disabled(model.recording != nil)
            }
            if draft.activation != .press {
                Text(draft.activation == .hold ? LocalizedStringResource.holdHint : .doublePressHint)
                    .font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if draft.activation == .hold {
                TapOutputField(draft: $draft, model: model, record: { record(.tapOutput) })
            }
        }
    }

    private var keyboardTriggerShortcut: KeyboardShortcut? {
        guard let trigger = draft.trigger, case .key(let code) = trigger.trigger else { return nil }
        return KeyboardShortcut(keyCode: code, modifiers: trigger.modifiers)
    }

    private var action: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(.actionTitle)
            ActionPickerView(model: model, selection: $actionKind)
            if actionKind == .keyboardShortcut {
                BindingCaptureField(value: draft.output.map(InputLabels.shortcut), target: .output,
                    recording: model.recording, canRecord: model.canRecord,
                    record: { record(.output) }, cancel: model.cancelRecording,
                    clear: { draft.output = nil }, wrapsControls: true, shortcut: draft.output)
            } else if actionKind == .insertText {
                ThemeTextField(title: .insertTextAction, text: $snippet, prompt: Text(.insertTextPrompt))
                    .disabled(model.recording != nil)
                if snippet.utf16.count > TextSnippet.maximumUTF16Length {
                    Text(.insertTextEncodingTooLong).font(Theme.caption).foregroundStyle(Theme.warningText)
                } else if snippet.count > TextSnippet.maximumLength {
                    Text(.insertTextTooLong).font(Theme.caption).foregroundStyle(Theme.warningText)
                }
            } else if actionKind == .runAppleShortcut {
                AppleShortcutParameters(target: $appleShortcut).disabled(model.recording != nil)
            } else if actionKind.needsWorkspaceParameters {
                WorkspaceActionParameters(kind: actionKind, application: $application, webAddress: $webAddress, file: $file)
                    .disabled(model.recording != nil)
            }
            if showsHoldOption {
                Toggle(isOn: $draft.holdsOutput) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(.holdOutputTitle).font(Theme.body).foregroundStyle(Theme.textPrimary)
                        Text(actionKind == .keyboardShortcut ? LocalizedStringResource.holdOutputShortcutHint : .holdOutputRepeatHint)
                            .font(Theme.caption).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toggleStyle(ThemeSwitchStyle())
                .padding(.leading, 14).padding(.trailing, 10).padding(.vertical, 10)
                .insetSurface()
                .disabled(model.recording != nil)
                .accessibilityIdentifier("binding-editor-hold-output")
            }
            if let actionHint {
                Text(actionHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !actionKind.isAvailable(with: model.audioCapabilities) {
                Text(actionKind.unavailableMessage).font(Theme.caption).foregroundStyle(Theme.warningText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Only a pressed key or mouse button has a release to hold an output until.
    private var showsHoldOption: Bool {
        guard actionKind.canBeHeld, draft.activation != .doublePress else { return false }
        return scope == .allKeyboards || (scope == .allMice && draft.mouseTarget == .mouseTrigger)
    }

    private var actionHint: LocalizedStringResource? {
        if actionKind == .keyboardShortcut {
            return scope == .allMice ? .mouseOutputHelp : scope.isTouchSurface ? .trackpadOutputHelp : nil
        }
        if actionKind == .runAppleShortcut || actionKind.needsWorkspaceParameters { return nil }
        if actionKind == .doNothing { return .doNothingHint }
        if actionKind == .pauseRebind { return .pauseRebindHint }
        if actionKind.controlAction != nil { return .switchProfileHint }
        if actionKind == .insertText { return .insertTextHint }
        if actionKind.modifierAction != nil { return .holdModifierHint }
        if actionKind == .navigateBack || actionKind == .navigateForward { return .navigationActionHint }
        if let shortcut = actionKind.fixedShortcut, [.spotlight, .emojiSymbols].contains(actionKind) { return .systemShortcutSettingsHint(InputLabels.shortcut(shortcut)) }
        if actionKind == .toggleMicrophoneMute { return .microphoneMuteHint }
        if actionKind == .openApps { return .openAppsHint }
        if actionKind == .fillWindowWithStageManager { return .stageManagerFillHint }
        if let shortcut = actionKind.fixedShortcut { return .namedShortcutHint(InputLabels.shortcut(shortcut)) }
        if let mouse = actionKind.mouseAction { return mouse.scrollLines == nil ? .mouseActionHint : .scrollActionHint }
        if actionKind == .nextDisplay { return .nextDisplayHint }
        if actionKind.windowLayoutAction != nil { return .windowLayoutHint }
        if let media = actionKind.mediaAction { return media.isBrightness ? .brightnessActionHint : .mediaActionHint }
        if let desktop = actionKind.desktopAction {
            return desktop.dockNotification != nil ? .dockActionHint : .spaceActionHint
        }
        if actionKind == .previousApplication { return .previousApplicationHint }
        if actionKind.windowCycleAction != nil { return .windowCycleHint }
        if actionKind == .lockScreen { return .lockScreenHint }
        if actionKind == .sleepSystem { return .sleepSystemHint }
        if actionKind == .openSystemSettings { return .openSystemSettingsHint }
        return actionKind.windowAction == nil ? .audioActionHint : .windowActionHint
    }

    @ViewBuilder private var feedback: some View {
        if validationError != .conflict, scope.isTrackpad, let preset = draft.trackpadPreset {
            Banner(severity: .information, title: .trackpadSystemGestureWarning,
                           message: preset.systemGestureHelp) {
                Button(.openSystemSettings, action: openSystemSettings).secondaryButton()
            }
        }
        if validationError != .conflict, scope == .magicMouse, let gestureHelp = draft.magicMousePreset.systemGestureHelp {
            Banner(severity: .information, title: .touchNativeGestureTitle,
                   message: gestureHelp)
        }
        if !model.canRecord {
            Banner(severity: .warning, title: .advancedDiagnosticsUnavailableTitle,
                           message: recordingUnavailableHint) {
                if !model.permissions.allowsRemapping {
                    Button(.mouseOpenPermissions) { model.cancelRecording(); showingPermissions = true }.secondaryButton()
                }
            }
        }
        switch model.status {
        case .tapFailed, .interrupted, .outputFailed, .secureInput:
            Banner(severity: model.status == .secureInput ? .warning : .error, title: model.status.text)
        default: EmptyView()
        }
        if let error = model.error {
            if error == .storageWriteFailed {
                Banner(severity: .error, title: .bindingSaveFailed, message: .bindingSaveFailedDescription)
            } else { Banner(severity: .error, title: error) }
        }
        if validationError == .conflict {
            Banner(severity: .warning,
                title: .mouseTriggerConflict(model.configuration.selectedProfile?.title ?? ""),
                message: conflictHelp)
        } else if validationError != nil { Banner(severity: .error, title: .bindingInvalid) }
    }

    private var configuredAction: RebindAction? {
        actionKind.configuredAction(shortcut: draft.output, application: application, webAddress: webAddress, file: file,
                                    appleShortcut: appleShortcut, text: snippet)
    }

    private var candidate: Binding? {
        configuredAction.flatMap { draft.binding(scope: scope, action: $0, existing: existing) }
    }

    private var validationError: ConfigurationError? {
        candidate.flatMap { BindingEditorValidation.error(for: $0, in: model.configuration) }
    }

    private var recordingUnavailableHint: LocalizedStringResource {
        if !model.permissions.allowsRemapping { return .mouseRecordingUnavailable }
        return model.recordingUnavailableHint
    }

    private var conflictHelp: LocalizedStringResource {
        scope.isTouchSurface ? .trackpadConflictHelp : .mouseConflictHelp
    }

    private func openSystemSettings() {
        model.cancelRecording()
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences"),
              NSWorkspace.shared.open(url) else {
            model.error = .openSystemSettingsFailed
            return
        }
    }

    private func record(_ target: RecordingTarget) {
        model.beginRecording(target)
        recordingRequest = model.recording
    }

    private func save() {
        guard configurationRevision == model.configurationReplacementRevision else { dismiss(); return }
        guard let candidate, validationError == nil, actionKind.isAvailable(with: model.audioCapabilities) else { return }
        if model.saveBinding(candidate, profileID: profileID) { dismiss() }
    }
}
