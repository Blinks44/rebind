import AppKit

/// Follows the app whose window is under the pointer, because a scroll goes to that window,
/// not to the app in front. Excluding smooth scrolling for an app must therefore look here.
/// The window list is too slow for the event tap and costly to read, so a utility queue reads it
/// ten times a second only while the mouse wheel turns (the tap reports each click through a
/// cheap dispatch source) and stops a second after the last one. Until the first answer, and while
/// stopped, the app in front stands in, which is where most scrolls go.
///
/// `@unchecked Sendable`: `timer`, `running` and `lastScroll` are touched only on `queue`.
nonisolated final class PointerApplicationTracker: @unchecked Sendable {
    private let mailbox: EngineMailbox
    private let queue = DispatchQueue(label: "Rebind pointer app", qos: .utility)
    private let scrolls: DispatchSourceUserDataAdd
    private var timer: DispatchSourceTimer?
    private var running = false
    private var lastScroll: UInt64 = 0

    init(mailbox: EngineMailbox) {
        self.mailbox = mailbox
        scrolls = DispatchSource.makeUserDataAddSource(queue: queue)
        scrolls.setEventHandler { [weak self] in self?.scrolled() }
        scrolls.activate()
    }

    /// From the event tap, for every wheel click that may glide: no allocation, no lock.
    func noteScroll() { scrolls.add(data: 1) }

    func setRunning(_ running: Bool) {
        queue.async { [self] in
            self.running = running
            if !running { stopPolling() }
        }
    }

    private func scrolled() {
        guard running else { return }
        lastScroll = DispatchTime.now().uptimeNanoseconds
        guard timer == nil else { return }
        poll()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + .milliseconds(100), repeating: .milliseconds(100), leeway: .milliseconds(20))
        timer.setEventHandler { [weak self] in self?.tick() }
        timer.resume()
        self.timer = timer
    }

    private func tick() {
        // Windows can move or change order beneath a stationary pointer during a scroll.
        if DispatchTime.now().uptimeNanoseconds &- lastScroll > 1_000_000_000 { stopPolling() } else { poll() }
    }

    private func stopPolling() {
        timer?.cancel()
        timer = nil
        mailbox.setPointerApplication(nil)
    }

    private func poll() {
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
