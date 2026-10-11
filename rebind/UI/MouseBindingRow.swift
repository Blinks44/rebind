import SwiftUI

struct MouseBindingRow: View {
    let binding: Binding
    let model: AppModel
    let edit: () -> Void
    let delete: () -> Void

    private var input: String { InputLabels.trigger(binding.trigger, modifiers: binding.modifiers) }
    private var kind: ActionKind { ActionKind(action: binding.action) }

    var body: some View {
        HStack(spacing: 16) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(input).font(.headline).fixedSize(horizontal: false, vertical: true)
                    Text(MouseBindingList.detail(for: binding)).font(.caption).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "computermouse").frame(width: 32, height: 40)
                    .background(Color(nsColor: .quaternaryLabelColor), in: .rect(cornerRadius: 8))
                    .accessibilityHidden(true)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "arrow.right").foregroundStyle(.secondary).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(binding.action.label).padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color(nsColor: .quaternaryLabelColor), in: .rect(cornerRadius: 8))
                    .fixedSize(horizontal: false, vertical: true)
                if !kind.isAvailable(with: model.audioCapabilities) {
                    Text(kind.unavailableMessage).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Toggle(isOn: SwiftUI.Binding(get: { binding.isEnabled }, set: { _ in model.toggle(binding) })) {
                Text(.mouseBindingEnabled(input, AppLocalization.string(MouseBindingList.detail(for: binding))))
            }.toggleStyle(.switch).labelsHidden().disabled(model.storageLocked)
                .frame(width: 48)
            Menu {
                Button(.editBinding, systemImage: "pencil", action: edit)
                Button(.deleteBinding, systemImage: "trash", role: .destructive, action: delete)
            } label: {
                Label(.mouseBindingOptions(input), systemImage: "ellipsis")
            }.labelStyle(.iconOnly).menuStyle(.borderlessButton).frame(width: 24)
                .disabled(model.storageLocked)
        }.padding(.vertical, 8)
    }
}
