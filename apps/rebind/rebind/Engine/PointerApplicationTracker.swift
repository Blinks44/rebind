import AppKit

/// Follows the app whose window is under the pointer, because a scroll goes to that window,
/// not to the app in front. Excluding smooth scrolling for an app must therefore look here.
/// The window list is too slow for the event tap, so a utility queue polls it ten times a
/// second, only while some app has smooth scrolling turned off, and publishes the result to
/// the mailbox, where the tap reads it under the usual short lock.
///
/// `@unchecked Sendable`: `timer` is touched only on `queue`.
nonisolated final class PointerApplicationTracker: @unchecked Sendable {
    private let mailbox: EngineMailbox
    private let queue = DispatchQueue(label: "Rebind pointer app", qos: .utility)
    private var timer: DispatchSourceTimer?

    init(mailbox: EngineMailbox) { self.mailbox = mailbox }

    func setRunning(_ running: Bool) {
        queue.async { [self] in
            guard running != (timer != nil) else { return }
            if running {
                let timer = DispatchSource.makeTimerSource(queue: queue)
                timer.schedule(deadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(20))
                timer.setEventHandler { [weak self] in self?.poll() }
                timer.resume()
                self.timer = timer
            } else {
                timer?.cancel()
                timer = nil
                mailbox.setPointerApplication(nil)
            }
        }
    }

    private func poll() {
        // Windows can move or change order beneath a stationary pointer.
        guard let location = CGEvent(source: nil)?.location else { return }
        mailbox.setPointerApplication(Self.bundleIdentifier(at: location))
    }

    /// The owner of the frontmost ordinary window containing the point (global, top-left origin).
    static func bundleIdentifier(at point: CGPoint) -> String? {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                                       kCGNullWindowID) as? [[String: Any]] else { return nil }
        for window in windows where window[kCGWindowLayer as String] as? Int == 0 {
            guard let bounds = (window[kCGWindowBounds as String] as? NSDictionary)
                    .flatMap({ CGRect(dictionaryRepresentation: $0 as CFDictionary) }),
                  bounds.contains(point), let pid = window[kCGWindowOwnerPID as String] as? pid_t else { continue }
            return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
        }
        return nil
    }
}
