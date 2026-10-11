import SwiftUI

struct BindingEditor: View {
    let model: AppModel
    let scope: DeviceScope
    let existing: Binding?
    private let profileID: UUID
    private let configurationRevision: UInt64
    @Environment(\.dismiss) private var dismiss
    @State private var trigger: MatchKey?
    @State private var output: KeyboardShortcut?
    @State private var actionKind: ActionKind
    @State private var application: ApplicationTarget?
    @State private var webAddress: String
    @State private var file: URL?
    @State private var appleShortcut: AppleShortcutTarget?
    @State private var mouseRecordingTarget: RecordingTarget
    @State private var activation: PressActivation
    @State private var holdDurationMilliseconds: UInt32
    @State private var pointerDirection: PointerDirection

    init(model: AppModel, scope: DeviceScope, existing: Binding?) {
        self.model = model
        self.scope = scope
        self.existing = existing
        profileID = model.configuration.selectedProfileID
        configurationRevision = model.configurationReplacementRevision
        _trigger = State(initialValue: existing.map { $0.matchKey.pressSource }
            ?? (scope == .builtInTrackpad ? MatchKey(trigger: .fourFingerTap, modifiers: []) : nil))
        _output = State(initialValue: existing?.action.shortcut)
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
        _activation = State(initialValue: existing?.activation ?? .press)
        _holdDurationMilliseconds = State(initialValue: existing?.holdDurationMilliseconds ?? 500)
        let target: RecordingTarget
        if let existing, case .scroll = existing.trigger { target = .scrollTrigger }
        else if let existing, case .mouseGesture = existing.trigger { target = .gestureTrigger }
        else { target = .mouseTrigger }
        _mouseRecordingTarget = State(initialValue: target)
        let direction: PointerDirection
        if let existing, case .mouseGesture(_, let value) = existing.trigger { direction = value }
        else { direction = .left }
        _pointerDirection = State(initialValue: direction)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(existing == nil ? LocalizedStringResource.addBinding : .editBinding).font(.title2.bold())
                Text(scope == .builtInTrackpad ? LocalizedStringResource.trackpadTapHint : .recordingLimitations)
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(.triggerTitle).font(.headline)
                        if scope == .allMice {
                            Picker(.mouseInputKind, selection: $mouseRecordingTarget) {
                                Text(.mouseButtonInput).tag(RecordingTarget.mouseTrigger)
                                Text(.mouseWheelInput).tag(RecordingTarget.scrollTrigger)
                                Text(.pointerGestureInput).tag(RecordingTarget.gestureTrigger)
                            }.pickerStyle(.menu)
                            if mouseRecordingTarget == .scrollTrigger {
                                Text(.wheelMappingHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if mouseRecordingTarget == .gestureTrigger {
                                Picker(.pointerDirectionTitle, selection: $pointerDirection) {
                                    ForEach(PointerDirection.allCases, id: \.self) { direction in
                                        Text(direction.label).tag(direction)
                                    }
                                }
                                Text(.pointerGestureHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if scope == .allKeyboards || (scope == .allMice && mouseRecordingTarget == .mouseTrigger) {
                            Text(.activationTitle).font(.caption).foregroundStyle(.secondary)
                            Picker(.activationTitle, selection: $activation) {
                                Text(.pressActivation).tag(PressActivation.press)
                                Text(.doublePressActivation).tag(PressActivation.doublePress)
                                Text(.holdActivation).tag(PressActivation.hold)
                            }.pickerStyle(.segmented).labelsHidden()
                            if activation == .doublePress {
                                Text(.doublePressHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if activation == .hold {
                                HoldDurationRow(milliseconds: $holdDurationMilliseconds)
                                Text(.holdHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Text(trigger.map { InputLabels.trigger($0.trigger, modifiers: $0.modifiers) } ?? AppLocalization.string(.notRecorded)).font(.title3.monospaced())
                        if scope != .builtInTrackpad {
                            Button(.recordTrigger) { model.beginRecording(scope == .allKeyboards ? .keyboardTrigger : mouseRecordingTarget) }
                                .disabled(!model.canRecord || model.recording != nil)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
                }
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(.actionTitle).font(.headline)
                        if scope == .builtInTrackpad {
                            Text(.outputShortcut)
                        } else { ActionPickerView(model: model, selection: $actionKind) }
                        if actionKind == .keyboardShortcut {
                            Text(output.map(InputLabels.shortcut) ?? AppLocalization.string(.notRecorded)).font(.title3.monospaced())
                            Button(.recordOutput) { model.beginRecording(.output) }.disabled(!model.canRecord || model.recording != nil)
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
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
                }
                if model.recording != nil {
                    HStack {
                        Label(.listeningHint, systemImage: "record.circle").foregroundStyle(.tint)
                        Spacer()
                        Button(.cancelRecording) { model.cancelRecording() }
                    }
                }
                if !model.canRecord {
                    Text(model.permissionHint).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                switch model.status {
                case .tapFailed, .interrupted, .outputFailed, .secureInput:
                    Text(model.status.text).foregroundStyle(.secondary)
                default: EmptyView()
                }
                if let error = model.error {
                    if error == .storageWriteFailed {
                        PermissionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(.bindingSaveFailed).font(.headline)
                                Text(.bindingSaveFailedDescription).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else { Text(error).foregroundStyle(.red) }
                }
                HStack {
                    Button(.clearRecording) {
                        model.cancelRecording()
                        trigger = scope == .builtInTrackpad ? MatchKey(trigger: .fourFingerTap, modifiers: []) : nil
                        output = nil; actionKind = .keyboardShortcut
                        application = nil; webAddress = ""; file = nil; appleShortcut = nil
                    }
                    Spacer()
                    Button(.cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                    Button(.saveBinding) { save() }.keyboardShortcut(.defaultAction)
                        .disabled(trigger == nil || configuredAction == nil || !actionKind.isAvailable(with: model.audioCapabilities) || model.recording != nil || model.storageLocked)
                }
            }.padding(24)
        }.frame(width: 540).frame(maxHeight: 760)
        .onAppear { model.error = nil; model.beginEditing() }
        .onDisappear { model.endEditing() }
        .onChange(of: model.configurationReplacementRevision) { dismiss() }
        .onChange(of: mouseRecordingTarget) {
            model.cancelRecording()
            trigger = nil
            activation = .press
            holdDurationMilliseconds = 500
            pointerDirection = .left
        }
        .onChange(of: actionKind) {
            model.cancelRecording()
        }
        .onChange(of: activation) { model.cancelRecording() }
        .onChange(of: holdDurationMilliseconds) { model.cancelRecording() }
        .onChange(of: pointerDirection) { model.cancelRecording() }
        .onChange(of: model.lastRecording?.request.id) {
            guard let recording = model.lastRecording, let input = recording.input else { return }
            if recording.request.target == .output, case .key(let code) = input.trigger {
                output = KeyboardShortcut(keyCode: code, modifiers: input.modifiers)
            } else { trigger = input }
        }
    }

    private var configuredAction: RebindAction? {
        actionKind.configuredAction(shortcut: output, application: application, webAddress: webAddress, file: file,
                                    appleShortcut: appleShortcut)
    }

    private func save() {
        guard configurationRevision == model.configurationReplacementRevision else { dismiss(); return }
        guard let trigger, let action = configuredAction, actionKind.isAvailable(with: model.audioCapabilities) else { return }
        let source: InputTrigger
        if mouseRecordingTarget == .gestureTrigger, scope == .allMice {
            guard case .mouseButton(let button) = trigger.trigger else { return }
            source = .mouseGesture(button: button, direction: pointerDirection)
        } else { source = trigger.trigger }
        var binding = Binding(scope: scope, trigger: source, modifiers: trigger.modifiers,
                              action: action, activation: activation,
                              holdDurationMilliseconds: holdDurationMilliseconds)
        if let existing { binding.id = existing.id; binding.isEnabled = existing.isEnabled }
        if model.saveBinding(binding, profileID: profileID) { dismiss() }
    }
}
