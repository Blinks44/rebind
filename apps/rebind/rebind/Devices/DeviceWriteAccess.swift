import Synchronization

/// Fresh companion-app authorization shared with a device's serial I/O queue.
nonisolated final class DeviceWriteAccess: Sendable {
    private let state = Mutex((standard: false, gaming: false, revision: UInt64(0)))

    var revision: UInt64 { state.withLock { $0.revision } }

    func update(standard: Bool, gaming: Bool) {
        state.withLock {
            if $0.standard != standard || $0.gaming != gaming { $0.revision &+= 1 }
            $0.standard = standard
            $0.gaming = gaming
        }
    }

    func invalidate() { state.withLock { $0.revision &+= 1 } }

    func allows(gaming: Bool, revision: UInt64? = nil) -> Bool {
        state.withLock { (revision == nil || revision == $0.revision) && (gaming ? $0.gaming : $0.standard) }
    }
}
