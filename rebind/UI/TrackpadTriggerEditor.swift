import SwiftUI

struct TrackpadTriggerEditor: View {
    @SwiftUI.Binding var draft: BindingEditorDraft
    let isRecording: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.triggerTitle).font(.headline).accessibilityAddTraits(.isHeader)
            Menu {
                Picker(.trackpadGestureTitle, selection: $draft.trackpadPreset) {
                    if draft.trackpadPreset == nil {
                        Text(.notRecorded).tag(Optional<TrackpadPreset>.none)
                    }
                    ForEach(TrackpadPreset.allCases) { preset in
                        Text(preset.title).tag(Optional(preset))
                    }
                }
                .pickerStyle(.inline).labelsHidden()
            } label: {
                HStack(spacing: 12) {
                    Text(draft.trackpadPreset?.title ?? .notRecorded)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
                }
                .foregroundStyle(.primary).padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 36)
                .contentShape(.rect)
            }
            .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
            .frame(maxWidth: .infinity, minHeight: 36)
            .accessibilityLabel(Text(.trackpadGestureTitle))
            .accessibilityValue(Text(draft.trackpadPreset?.title ?? .notRecorded))
            .background {
                if reduceTransparency {
                    Capsule().fill(Color(.permissionSurface))
                }
            }
            .glassEffect(reduceTransparency ? .identity : .regular.interactive(), in: .capsule)
            .overlay {
                if contrast == .increased {
                    Capsule().strokeBorder(Color(nsColor: .separatorColor))
                }
            }
            .disabled(isRecording)
            .accessibilityIdentifier("trackpad-preset-selector")
            if let preset = draft.trackpadPreset {
                Text(preset.explanation).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
