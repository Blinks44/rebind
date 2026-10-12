import AppKit
import SwiftUI

struct BindingEditor: View {
    let model: AppModel
    let scope: DeviceScope
    let existing: Binding?
    private let profileID: UUID
    private let configurationRevision: UInt64
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BindingEditorDraft
    @State private var recordingRequest: RecordingRequest?
    @State private var showingPermissions = false
    @State private var actionKind: ActionKind
    @State private var application: ApplicationTarget?
    @State private var webAddress: String
    @State private var file: URL?
    @State private var appleShortcut: AppleShortcutTarget?

    init(model: AppModel, scope: DeviceScope, existing: Binding?) {
        self.model = model
        self.scope = scope
        self.existing = existing
        profileID = model.configuration.selectedProfileID
        configurationRevision = model.configurationReplacementRevision
        _draft = State(initialValue: BindingEditorDraft(scope: scope, existing: existing))
        _actionKind = State(initialValue: existing.map { ActionKind(action: $0.action) } ?? .keyboardShortcut)
        let workspace: WorkspaceAction?
        if case .workspace(let value) = existing?.action { workspace = value } else { workspace = nil }
        _application = State(initialValue: workspace?.application)
        if case .openURL(let url) = workspace { _webAddress = State(initialValue: url.absoluteString) }
        else { _webAddress = State(initialValue: "") }
        if case .openFile(let url) = workspace { _file = State(initialValue: url) }
        else { _file = State(initialValue: nil) }
        if case .appleShortcut(let target) = existing?.action { _appleShortcut = State(initialValue: target) }
        else { _appleShortcut = State(initialValue: nil) }
    }

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 8) {
                VStack(alignment: .leading, spacing: scope == .allKeyboards ? 20 : EditorMetrics.sectionSpacing) {
                    if scope != .allKeyboards {
                        HStack(spacing: 16) {
                            Image(systemName: scope.symbol).foregroundStyle(.tint).accessibilityHidden(true)
                                .frame(width: 40, height: 40)
                                .background(Color(.permissionSurface), in: .rect(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 8) {
                                Text(existing == nil ? LocalizedStringResource.addBinding : .editBinding).font(EditorTypography.title)
                                Text(scope == .allMice
                                     ? LocalizedStringResource.mouseEditorScope(model.configuration.selectedProfile?.title ?? "")
                                     : .trackpadEditorScope(model.configuration.selectedProfile?.title ?? ""))
                                    .font(EditorTypography.caption).foregroundStyle(Color(.editorTextSecondary))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        Text(existing == nil ? LocalizedStringResource.addBinding : .editBinding).font(.title2.bold())
                        Text(.recordingLimitations)
                            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    if scope == .allMice {
                        MouseTriggerEditor(draft: $draft, model: model, record: { record(draft.mouseTarget) })
                    } else if scope == .builtInTrackpad {
                        TrackpadTriggerEditor(draft: $draft, isRecording: model.recording != nil)
                    } else {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(.triggerTitle).font(.headline)
                                if scope == .allKeyboards {
                                    Text(.activationTitle).font(.caption).foregroundStyle(.secondary)
                                    EditorActivationPicker(selection: $draft.activation)
                                        .frame(maxWidth: .infinity).frame(height: 28)
                                        .disabled(model.recording != nil)
                                    if draft.activation == .doublePress {
                                        Text(.doublePressHint).font(.caption).foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    if draft.activation == .hold {
                                        HoldDurationRow(milliseconds: $draft.holdDurationMilliseconds)
                                        Text(.holdHint).font(.caption).foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                Text(draft.trigger.map { InputLabels.trigger($0.trigger, modifiers: $0.modifiers) } ?? AppLocalization.string(.notRecorded)).font(.title3.monospaced())
                                if scope != .builtInTrackpad {
                                    Button(.recordTrigger) { record(scope == .allKeyboards ? .keyboardTrigger : draft.mouseTarget) }
                                        .disabled(!model.canRecord || model.recording != nil)
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
                        }
                    }
                    BindingEditorSection(usesCard: scope == .allKeyboards) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.actionTitle).font(scope == .allKeyboards ? .headline : EditorTypography.section)
                                .accessibilityAddTraits(.isHeader)
                            if scope == .builtInTrackpad {
                                Label { Text(.outputShortcut) } icon: {
                                    Image(systemName: "command").foregroundStyle(Color(.editorAccentText))
                                }
                                    .font(EditorTypography.label).foregroundStyle(Color(.editorTextPrimary))
                                    .padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                                    .modifier(EditorGlassSurface(interactive: false))
                            } else { ActionPickerView(model: model, selection: $actionKind) }
                            if actionKind == .keyboardShortcut {
                                if scope != .allKeyboards {
                                    BindingCaptureField(value: draft.output.map(InputLabels.shortcut), target: .output,
                                        recording: model.recording, canRecord: model.canRecord,
                                        record: { record(.output) }, cancel: model.cancelRecording,
                                        clear: { draft.output = nil }, wrapsControls: true, shortcut: draft.output)
                                    Text(scope == .builtInTrackpad ? LocalizedStringResource.trackpadOutputHelp : .mouseOutputHelp)
                                        .font(EditorTypography.caption).foregroundStyle(Color(.editorTextSecondary))
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    Text(draft.output.map(InputLabels.shortcut) ?? AppLocalization.string(.notRecorded)).font(.title3.monospaced())
                                    Button(.recordOutput) { record(.output) }.disabled(!model.canRecord || model.recording != nil)
                                }
                            } else if actionKind.mouseAction != nil {
                                Text(.mouseActionHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if actionKind.windowLayoutAction != nil {
                                Text(.windowLayoutHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if actionKind.mediaAction != nil {
                                Text(.mediaActionHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if let desktop = actionKind.desktopAction {
                                if desktop.dockNotification != nil {
                                    Text(.dockActionHint).font(.caption).foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if !actionKind.isAvailable(with: model.audioCapabilities) {
                                        Text(.dockActionUnavailable).foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text(.spaceActionHint).font(.caption).foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if !actionKind.isAvailable(with: model.audioCapabilities) {
                                        Text(.spaceActionUnavailable).foregroundStyle(.secondary)
                                    }
                                }
                            } else if actionKind == .previousApplication {
                                Text(.previousApplicationHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if actionKind.windowCycleAction != nil {
                                Text(.windowCycleHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if actionKind == .lockScreen {
                                Text(.lockScreenHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !actionKind.isAvailable(with: model.audioCapabilities) {
                                    Text(.lockScreenUnavailable).font(.caption).foregroundStyle(.secondary)
                                }
                            } else if actionKind == .sleepSystem {
                                Text(.sleepSystemHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !actionKind.isAvailable(with: model.audioCapabilities) {
                                    Text(.sleepSystemUnavailable).font(.caption).foregroundStyle(.secondary)
                                }
                            } else if actionKind == .openSystemSettings {
                                Text(.openSystemSettingsHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if actionKind == .runAppleShortcut {
                                AppleShortcutParameters(target: $appleShortcut).disabled(model.recording != nil)
                            } else if actionKind.needsWorkspaceParameters {
                                WorkspaceActionParameters(kind: actionKind, application: $application, webAddress: $webAddress, file: $file)
                                    .disabled(model.recording != nil)
                            } else {
                                Text(actionKind.windowAction == nil ? LocalizedStringResource.audioActionHint : .windowActionHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !actionKind.isAvailable(with: model.audioCapabilities) {
                                    Text(.audioActionUnavailable).foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(scope == .allKeyboards ? 8 : 0)
                    }
                    if scope == .builtInTrackpad, let preset = draft.trackpadPreset {
                        EditorFeedback(severity: .warning, title: .trackpadSystemGestureWarning,
                                       message: preset.systemGestureHelp) {
                            Button(.openSystemSettings, action: openSystemSettings)
                        }
                    }
                    if model.recording != nil && scope == .allKeyboards {
                        HStack {
                            Label(.listeningHint, systemImage: "record.circle").foregroundStyle(.tint)
                            Spacer()
                            Button(.cancelRecording) { model.cancelRecording() }
                        }
                    }
                    if !model.canRecord {
                        EditorFeedback(severity: .warning, title: .advancedDiagnosticsUnavailableTitle,
                                       message: recordingUnavailableHint) {
                            if !model.permissions.allowsRemapping {
                                Button(.mouseOpenPermissions) { model.cancelRecording(); showingPermissions = true }
                            }
                        }
                    }
                    switch model.status {
                    case .tapFailed, .interrupted, .outputFailed, .secureInput:
                        EditorFeedback(severity: model.status == .secureInput ? .warning : .error,
                                       title: model.status.text)
                    default: EmptyView()
                    }
                    if let error = model.error {
                        if error == .storageWriteFailed {
                            EditorFeedback(severity: .error, title: .bindingSaveFailed,
                                           message: .bindingSaveFailedDescription)
                        } else { EditorFeedback(severity: .error, title: error) }
                    }
                    if validationError == .conflict {
                        EditorFeedback(severity: .warning,
                            title: .mouseTriggerConflict(model.configuration.selectedProfile?.title ?? ""),
                            message: conflictHelp)
                    } else if validationError != nil { EditorFeedback(severity: .error, title: .bindingInvalid) }
                }.padding(24)
            }
        }.safeAreaInset(edge: .bottom, spacing: 0) {
            GlassEffectContainer(spacing: 8) {
                HStack {
                    if scope == .allKeyboards {
                        Button(.clearRecording) {
                            model.cancelRecording()
                            draft = BindingEditorDraft(scope: scope, existing: nil)
                            actionKind = .keyboardShortcut
                            application = nil; webAddress = ""; file = nil; appleShortcut = nil
                        }
                    }
                    Spacer()
                    Button(.cancel) { model.cancelRecording(); dismiss() }
                        .accessibilityIdentifier("binding-editor-cancel")
                        .modifier(EditorSecondaryButton())
                    Button(.editorSaveBinding, action: save).keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("binding-editor-save")
                        .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                        .disabled(candidate == nil || validationError != nil
                            || !actionKind.isAvailable(with: model.audioCapabilities)
                            || model.recording != nil || model.storageLocked)
                }.font(EditorTypography.body)
                    .tint(Color(.editorSelection))
                    .padding(24).background(Color(.permissionCanvasBottom))
            }
        }.frame(width: scope == .allKeyboards ? 540 : 512).frame(idealHeight: 640, maxHeight: 760)
        .background { PermissionCanvas() }
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

    private var configuredAction: RebindAction? {
        actionKind.configuredAction(shortcut: draft.output, application: application, webAddress: webAddress, file: file,
                                    appleShortcut: appleShortcut)
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
        scope == .builtInTrackpad ? .trackpadConflictHelp : .mouseConflictHelp
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
