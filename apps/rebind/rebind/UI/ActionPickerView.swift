import SwiftUI

/// Selector plus a searchable popover of actions grouped by category.
struct ActionPickerView: View {
    let model: AppModel
    @SwiftUI.Binding var selection: ActionKind
    @State private var presented = false
    @State private var search = ""
    @State private var hovered: ActionKind?

    var body: some View {
        Button { search = ""; presented = true } label: {
            SelectorLabel(title: selection.title, symbol: selection.symbol)
        }
        .buttonStyle(.plain).modifier(ControlSurface()).keyboardFocusRing()
        .accessibilityLabel(Text(.chooseAction)).accessibilityValue(Text(selection.title))
        .disabled(model.recording != nil)
        .popover(isPresented: $presented, arrowEdge: .bottom) { list }
    }

    private var list: some View {
        VStack(spacing: 0) {
            ThemeTextField(title: .searchActions, text: $search, symbol: "magnifyingglass", autofocus: true,
                           onSubmit: { if let first = matchingKinds.first(where: isAvailable) { choose(first) } })
                .padding(8)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(ActionKind.Category.allCases) { category in
                        let kinds = matchingKinds.filter { $0.category == category }
                        if !kinds.isEmpty {
                            SectionLabel(category.title).padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 6)
                            ForEach(kinds) { row($0) }
                        }
                    }
                    if matchingKinds.isEmpty {
                        Text(.noMatchingActions).font(Theme.body).foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 32)
                    }
                }.padding(.bottom, 8)
            }
        }
        .frame(width: 360, height: 420)
    }

    private var matchingKinds: [ActionKind] {
        ActionKind.allCases.filter {
            search.isEmpty
                || AppLocalization.string($0.title).localizedStandardContains(search)
                || AppLocalization.string($0.category.title).localizedStandardContains(search)
        }
    }

    private func isAvailable(_ kind: ActionKind) -> Bool { kind.isAvailable(with: model.audioCapabilities) }

    private func choose(_ kind: ActionKind) {
        selection = kind
        presented = false
    }

    private func row(_ kind: ActionKind) -> some View {
        let available = isAvailable(kind)
        return Button { choose(kind) } label: {
            HStack(spacing: 12) {
                ActionTile(symbol: kind.symbol)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                    if !available {
                        Text(kind.unavailableMessage).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                if selection == kind {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.accent)
                        .accessibilityLabel(Text(.profileSelected))
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(hovered == kind && available ? Theme.hoverSurface : .clear,
                        in: .rect(cornerRadius: 12, style: .continuous))
            .opacity(available ? 1 : 0.45)
            .contentShape(.rect)
        }
        .buttonStyle(.plain).keyboardFocusRing(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .disabled(!available).padding(.horizontal, 4)
        .onHover { hovered = $0 ? kind : (hovered == kind ? nil : hovered) }
    }
}
