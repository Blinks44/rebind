import CoreGraphics
import Darwin

/// A hardware scroll CGEvent carries the HID scroll event it came from, and AppKit reads
/// precise (continuous) scrolling deltas from that attached event. Rewriting only the
/// CGEvent fields therefore reverses a stepped wheel but not a high-resolution one such as
/// an MX Master without Logitech software. This adapter scales the attached values too.
///
/// Private SPI (`CGEventCopyIOHIDEvent`, `IOHIDEventGet/SetFloatValue`, the same calls
/// LinearMouse uses), looked up once. If a future macOS drops a symbol, only the CGEvent
/// fields change: stepped wheels keep working and nothing crashes.
nonisolated enum AttachedHIDScroll {
    private typealias Copy = @convention(c) (CGEvent) -> Unmanaged<CFTypeRef>?
    private typealias Get = @convention(c) (CFTypeRef, UInt32) -> Double
    private typealias Set = @convention(c) (CFTypeRef, UInt32, Double) -> Void

    /// kIOHIDEventTypeScroll (6) << 16, plus the axis: X = 0, Y = 1.
    private static let scrollX: UInt32 = 6 << 16
    private static let scrollY: UInt32 = 6 << 16 | 1

    // Immutable after the one-time lookup; C function pointers carry no state.
    private nonisolated(unsafe) static let functions: (copy: Copy, get: Get, set: Set)? = {
        func symbol<T>(_ name: String) -> T? {
            dlsym(UnsafeMutableRawPointer(bitPattern: -2), name).map { unsafeBitCast($0, to: T.self) } // RTLD_DEFAULT
        }
        guard let copy: Copy = symbol("CGEventCopyIOHIDEvent"), let get: Get = symbol("IOHIDEventGetFloatValue"),
              let set: Set = symbol("IOHIDEventSetFloatValue") else { return nil }
        return (copy, get, set)
    }()

    /// Looks the symbols up outside the event callback.
    static func prepare() { _ = functions }

    /// Multiplies the attached HID scroll values; vertical is CGEvent axis 1, HID Y.
    static func scale(_ event: CGEvent, by factor: Double) {
        guard let functions, let attached = functions.copy(event)?.takeRetainedValue() else { return }
        for field in [scrollY, scrollX] {
            let value = functions.get(attached, field)
            if value != 0 { functions.set(attached, field, value * factor) }
        }
    }
}
