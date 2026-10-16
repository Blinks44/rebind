import Synchronization
import HIDPP

/// A HID++ connection owns diversion until an acknowledged release, even when a refresh
/// replaces its feature adapters or a companion app prevents further settings writes.
nonisolated final class GestureButtonOwnership: Sendable {
    /// The immutable protocol handle is used only on its connection's serial I/O queue,
    /// just like LogitechDevice. MainActor reads only the locked ownership keys.
    private struct Control: @unchecked Sendable {
        let value: ReprogControls
    }
    private let diverted = Mutex<[UInt8: Control]>([:])

    func contains(_ index: UInt8) -> Bool { diverted.withLock { $0[index] != nil } }

    func setDiverted(_ value: Bool, at index: UInt8, controls: ReprogControls) {
        diverted.withLock {
            $0[index] = value ? Control(value: controls) : nil
        }
    }

    /// Call on the connection's I/O queue, after revoking further settings writes.
    /// Cleanup includes a diversion acknowledged before its adapter reached MainActor.
    func releaseAll() {
        let controls = diverted.withLock { $0 }
        for (index, control) in controls {
            if control.value.setDiverted(ReprogControls.gestureButton, false) {
                diverted.withLock { $0[index] = nil }
            }
        }
    }
}
