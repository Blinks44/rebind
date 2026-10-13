import SwiftUI

/// One rule: trigger keycaps → action, with its switch and options menu.
struct BindingRow: View {
    let binding: Binding
    let model: AppModel
    let edit: () -> Void
    let duplicate: () -> Void
    let delete: () -> Void

    private var kind: ActionKind { ActionKind(action: binding.action) }
    private var input: String { InputLabels.trigger(binding.trigger, modifiers: binding.modifiers) }
    private var isAvailable: Bool { kind.isAvailable(with: model.audioCapabilities) }

    private var caption: String {
        if !isAvailable { return AppLocalization.string(kind.unavailableMessage) }
        if let note = binding.note { return note }
        let category = AppLocalization.string(kind.category.title)
        if binding.holdsOutput { return category + " · " + AppLocalization.string(.holdOutputBadge) }
        guard binding.activation != .press else { return category }
        return category + " · " + AppLocalization.string(BindingList.detail(for: binding))
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                trigger.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.iconTertiary).frame(width: 14).accessibilityHidden(true)
                HStack(spacing: 12) {
                    ActionTile(symbol: kind.symbol)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(binding.action.label).font(Theme.headline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                        Text(caption).font(Theme.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    }
                }
                .padding(.leading, 19).frame(maxWidth: .infinity, alignment: .leading)
                // Sketch splits the row slightly left of center: equal columns plus this fixed gap.
                Color.clear.frame(width: 42, height: 1)
            }
            .opacity(binding.isEnabled ? 1 : 0.45)
            Toggle(isOn: SwiftUI.Binding(get: { binding.isEnabled }, set: { _ in model.toggle(binding) })) {
                Text(.mouseBindingEnabled(input, binding.action.label))
            }.toggleStyle(ThemeSwitchStyle()).labelsHidden().padding(.trailing, 12)
            OptionsMenu(label: .mouseBindingOptions(input)) { actions }
        }
        .disabled(model.storageLocked)
        .padding(.leading, 20).padding(.trailing, 16).frame(height: Theme.rowHeight)
        .contentShape(.rect)
        .contextMenu { actions }
    }

    @ViewBuilder private var actions: some View {
        Button(.editBinding, systemImage: "pencil", action: edit)
        Button(.duplicateBinding, systemImage: "doc.on.doc", action: duplicate)
        let others = model.configuration.profiles.filter { $0.id != model.configuration.selectedProfileID }
        if !others.isEmpty {
            Menu(.copyBindingToProfile, systemImage: "square.on.square") {
                ForEach(others) { profile in
                    Button { model.copyBinding(binding, toProfile: profile.id) } label: { Text(verbatim: profile.title) }
                }
            }
        }
        Button(.deleteBinding, systemImage: "trash", role: .destructive, action: delete)
    }

    /// Modifier keycaps followed by the key, mouse button or gesture chip.
    private var trigger: some View {
        HStack(spacing: 6) {
            ForEach(Array(binding.modifiers.glyphs), id: \.self) { Keycap(label: String($0)) }
            switch binding.trigger {
            case .key(let code): Keycap(label: InputLabels.key(code))
            case .mouseButton: Keycap(label: InputLabels.trigger(binding.trigger, modifiers: []))
            case .mouseGesture(_, let direction):
                TriggerChip(label: InputLabels.trigger(binding.trigger, modifiers: []), symbol: "arrow.\(direction.rawValue)")
            case .scroll(let direction), .buttonScroll(_, let direction):
                TriggerChip(label: InputLabels.trigger(binding.trigger, modifiers: []), symbol: "arrow.\(direction.rawValue)")
            default: TriggerChip(label: InputLabels.trigger(binding.trigger, modifiers: []), symbol: "hand.tap")
            }
        }
        .accessibilityElement(children: .ignore).accessibilityLabel(Text(input))
    }
}
