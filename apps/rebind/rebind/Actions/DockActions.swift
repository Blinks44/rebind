import CoreFoundation
import Darwin

// Undocumented Apple SPI, used only behind this adapter. Resolve dynamically so
// disappearance disables the action instead of preventing the app from launching.
nonisolated enum DockActions {
    private typealias Notify = @convention(c) (CFString, Int32) -> Int32
    private static let notify: Notify? = resolve()
    static var isAvailable: Bool { notify != nil }
    static func isAvailable(for action: DesktopAction) -> Bool {
        // Space posting uses public Quartz APIs. Its system-shortcut dependency
        // is explained in the editor and checked on the worker before posting.
        action.isSpaceNavigation || isAvailable
    }

    static func perform(_ action: DesktopAction, canPerform: () -> Bool,
                        send: (String) -> Bool = sendNotification) -> WindowActionResult {
        if action.isSpaceNavigation { return SpaceShortcutSender.perform(action, canPerform: canPerform) }
        guard let name = action.dockNotification else { return .unavailable }
        guard canPerform() else { return .cancelled }
        return send(name) ? .performed : .unavailable
    }

    private static func sendNotification(_ name: String) -> Bool {
        guard let notify else { return false }
        // Success is request acceptance, not acknowledgement of the visual state.
        return notify(name as CFString, 0) == 0
    }

    private static func resolve() -> Notify? {
        let path = "/System/Library/Frameworks/ApplicationServices.framework/Frameworks/HIServices.framework/HIServices"
        guard let handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL) else { return nil }
        guard let symbol = dlsym(handle, "CoreDockSendNotification") else {
            dlclose(handle)
            return nil
        }
        // Keep one image reference for the function pointer's process lifetime.
        return unsafeBitCast(symbol, to: Notify.self)
    }
}
