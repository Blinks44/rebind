import AppKit
import SwiftUI

/// AppKit's text system provides selection, line navigation, copying and Find without editing.
struct ReadOnlyNoticesText: NSViewRepresentable {
    let text: String
    var findRequest = 0
    @Environment(\.locale) private var locale

    /// Tracks explicit Find invocations without disturbing selection on ordinary view updates.
    final class Coordinator {
        var handledFindRequest = 0
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let view = NSTextView(frame: scroll.contentView.bounds)
        view.isEditable = false
        view.isSelectable = true
        view.isRichText = false
        view.usesFindBar = true
        view.font = .systemFont(ofSize: NSFont.systemFontSize)
        view.textColor = .textColor
        view.backgroundColor = .textBackgroundColor
        view.textContainerInset = NSSize(width: 12, height: 12)
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = false
        view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = true
        view.textContainer?.containerSize = NSSize(width: scroll.contentSize.width,
                                                  height: CGFloat.greatestFiniteMagnitude)
        view.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                              height: CGFloat.greatestFiniteMagnitude)
        scroll.documentView = view
        updateNSView(scroll, context: context)
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let view = scroll.documentView as? NSTextView else { return }
        if view.string != text { view.string = text }
        var title = LocalizedStringResource.aboutLicenses
        title.locale = locale
        view.setAccessibilityLabel(String(localized: title))
        if context.coordinator.handledFindRequest != findRequest {
            context.coordinator.handledFindRequest = findRequest
            // AppKit focus/find-bar changes must happen after SwiftUI's representable update.
            DispatchQueue.main.async { [weak view] in
                guard let view, let window = view.window else { return }
                window.makeFirstResponder(view)
                let action = NSMenuItem()
                action.tag = NSTextFinder.Action.showFindInterface.rawValue
                view.performTextFinderAction(action)
            }
        }
    }
}
