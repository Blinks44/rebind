import AppKit

final class EditorMenuSelectionTarget: NSObject {
    let select: (Int) -> Void

    init(select: @escaping (Int) -> Void) { self.select = select }

    @objc func selectItem(_ item: NSMenuItem) { select(item.tag) }
}
