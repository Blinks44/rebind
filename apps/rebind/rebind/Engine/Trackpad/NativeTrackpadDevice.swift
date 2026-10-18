import Darwin
import Foundation
import IOKit

// Only this adapter touches the private framework. A device, its registration,
// framework handle and Sendable callback context live until process exit: private
// unregister/stop does not document callback quiescence. Stop closes acceptance
// before the native call; no callback can access a released Swift object. Repeated
// pause/resume does not leak additional contexts/devices or register duplicates.
// A Magic Trackpad that reconnects gets a new adapter; the old one is retired, not freed.
@MainActor final class NativeTrackpadDevice {
    enum Kind: Sendable { case builtIn, magicTrackpad, magicMouse }

    /// Discovery creates fresh wrappers; only the registry entry identifies a connection.
    struct Connection: Equatable {
        let device: UnsafeMutableRawPointer
        let registryEntryID: UInt64

        static func == (lhs: Self, rhs: Self) -> Bool { lhs.registryEntryID == rhs.registryEntryID }
    }

    private typealias Callback = @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer?, Int32,
                                                Double, Int32, UnsafeMutableRawPointer) -> Void

    private struct Framework {
        let createDefault: @convention(c) () -> UnsafeMutableRawPointer?
        let createList: @convention(c) () -> Unmanaged<CFArray>?
        let release: @convention(c) (UnsafeMutableRawPointer) -> Void
        let isBuiltIn: @convention(c) (UnsafeMutableRawPointer) -> Bool
        let service: @convention(c) (UnsafeMutableRawPointer) -> io_service_t
        let dimensions: @convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<Int32>, UnsafeMutablePointer<Int32>) -> Int32
        let familyID: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<Int32>) -> Int32)?
        let start: @convention(c) (UnsafeMutableRawPointer, Int32) -> Int32
        let stop: @convention(c) (UnsafeMutableRawPointer) -> Int32
        let register: @convention(c) (UnsafeMutableRawPointer, Callback?, UnsafeMutableRawPointer?) -> Void
        /// Optional: without it, no surface is treated as reporting finger force.
        let supportsForce: (@convention(c) (UnsafeMutableRawPointer) -> Bool)?

        init?() {
            // New major OS releases require another private-ABI audit. This is a
            // compatibility gate, not a hardware-verification claim for macOS 26.
            guard (26...27).contains(ProcessInfo.processInfo.operatingSystemVersion.majorVersion),
                  let handle = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport",
                                      RTLD_LOCAL | RTLD_LAZY) else { return nil }
            func symbol<T>(_ name: String) -> T? { dlsym(handle, name).map { unsafeBitCast($0, to: T.self) } }
            guard let createDefault: @convention(c) () -> UnsafeMutableRawPointer? = symbol("MTDeviceCreateDefault"),
                  let createList: @convention(c) () -> Unmanaged<CFArray>? = symbol("MTDeviceCreateList"),
                  let release: @convention(c) (UnsafeMutableRawPointer) -> Void = symbol("MTDeviceRelease"),
                  let isBuiltIn: @convention(c) (UnsafeMutableRawPointer) -> Bool = symbol("MTDeviceIsBuiltIn"),
                  let service: @convention(c) (UnsafeMutableRawPointer) -> io_service_t = symbol("MTDeviceGetService"),
                  let dimensions: @convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<Int32>, UnsafeMutablePointer<Int32>) -> Int32
                    = symbol("MTDeviceGetSensorSurfaceDimensions"),
                  let start: @convention(c) (UnsafeMutableRawPointer, Int32) -> Int32 = symbol("MTDeviceStart"),
                  let stop: @convention(c) (UnsafeMutableRawPointer) -> Int32 = symbol("MTDeviceStop"),
                  let register: @convention(c) (UnsafeMutableRawPointer, Callback?, UnsafeMutableRawPointer?) -> Void
                    = symbol("MTRegisterContactFrameCallbackWithRefcon") else { return nil }
            self.createDefault = createDefault; self.createList = createList; self.release = release
            self.isBuiltIn = isBuiltIn; self.service = service; self.dimensions = dimensions
            self.start = start; self.stop = stop; self.register = register
            familyID = symbol("MTDeviceGetFamilyID") as (@convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<Int32>) -> Int32)?
            supportsForce = symbol("MTDeviceSupportsForce") as (@convention(c) (UnsafeMutableRawPointer) -> Bool)?
        }
    }

    private static let framework = Framework()
    private static var builtIn: NativeTrackpadDevice?
    private static var magicTrackpad: NativeTrackpadDevice?
    private static var magicMouse: NativeTrackpadDevice?
    private static var retired: [NativeTrackpadDevice] = []

    let buffer: NativeTrackpadBuffer
    private let connection: Connection?
    private var device: UnsafeMutableRawPointer? { connection?.device }
    private var running = false
    private(set) var available = false
    private(set) var failed = false

    /// The built-in adapter always exists (possibly unavailable). External adapters
    /// exist only while their surface is connected; call again to rescan.
    static func acquire(mailbox: EngineMailbox, kind: Kind = .builtIn) -> NativeTrackpadDevice? {
        switch kind {
        case .builtIn:
            if let builtIn { return builtIn }
            var device = framework?.createDefault()
            if let found = device, framework?.isBuiltIn(found) != true { framework?.release(found); device = nil }
            let connection = device.map { Connection(device: $0, registryEntryID: 0) }
            let result = NativeTrackpadDevice(mailbox: mailbox, kind: kind, connection: connection)
            builtIn = result
            return result
        case .magicTrackpad, .magicMouse:
            let previous = kind == .magicMouse ? magicMouse : magicTrackpad
            guard let framework, let found = connectedExternal(framework, kind: kind) else {
                if let previous { previous.stop(); retired.append(previous) }
                if kind == .magicMouse { magicMouse = nil } else { magicTrackpad = nil }
                return nil
            }
            if let previous, previous.connection == found {
                Unmanaged<AnyObject>.fromOpaque(found.device).release()
                return previous
            }
            if let previous { previous.stop(); retired.append(previous) }
            let result = NativeTrackpadDevice(mailbox: mailbox, kind: kind, connection: found)
            if kind == .magicMouse { magicMouse = result } else { magicTrackpad = result }
            return result
        }
    }

    /// Trackpads are wider than tall; the observed Magic Mouse is family 112 and taller than wide.
    /// No names, serial numbers or per-device rule routing are read.
    private static func connectedExternal(_ framework: Framework, kind: Kind) -> Connection? {
        guard let list = framework.createList()?.takeRetainedValue() as? [AnyObject] else { return nil }
        return withExtendedLifetime(list) {
            for object in list {
                let device = Unmanaged.passUnretained(object).toOpaque()
                var width: Int32 = 0, height: Int32 = 0, registryEntryID: UInt64 = 0
                guard !framework.isBuiltIn(device), framework.dimensions(device, &width, &height) == 0, width > 0, height > 0,
                      IORegistryEntryGetRegistryEntryID(framework.service(device), &registryEntryID) == KERN_SUCCESS,
                      registryEntryID != 0 else { continue }
                if kind == .magicMouse {
                    var family: Int32 = 0
                    guard width < height, framework.familyID?(device, &family) == 0, family == 112 else { continue }
                } else if width <= height { continue }
                // Retain within the list's lifetime; acquisition adopts the extra ownership below.
                _ = Unmanaged.passUnretained(object).retain()
                return Connection(device: device, registryEntryID: registryEntryID)
            }
            return nil
        }
    }

    private init(mailbox: EngineMailbox, kind: Kind, connection: Connection?) {
        let device = connection?.device
        // A Magic Trackpad reports no finger force through this framework (probe, 2026-10-16).
        let reportsForce = device.map { Self.framework?.supportsForce?($0) == true } ?? false
        buffer = NativeTrackpadBuffer(mailbox: mailbox, isMagicTrackpad: kind == .magicTrackpad, reportsForce: reportsForce, isMagicMouse: kind == .magicMouse)
        self.connection = connection
        guard let device, let framework = Self.framework else { return }
        // Permanent process-owned device retains the buffer independently of UI.
        let context = Unmanaged.passUnretained(buffer).toOpaque()
        framework.register(device, { _, data, count, time, frame, context in
            Unmanaged<NativeTrackpadBuffer>.fromOpaque(context).takeUnretainedValue()
                .receive(data, count: count, callbackFrame: frame, callbackTime: time)
        }, context)
        // Registration returns Void; MTDeviceStart supplies the actual status.
        available = true
    }

    @discardableResult func start() -> Bool {
        guard available, !failed, let device, let framework = Self.framework else { return false }
        guard !running else { return true }
        buffer.setAccepting(true)
        // Mode 0 matches the verified probe. No private settings/gesture suppression.
        running = framework.start(device, 0) == 0
        if !running { buffer.setAccepting(false); failed = true }
        return running
    }

    func stop() {
        buffer.setAccepting(false)
        guard running, let device, let framework = Self.framework else { return }
        running = false
        if framework.stop(device) != 0 { failed = true }
    }
}
