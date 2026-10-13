import Darwin
import Foundation

// Only this adapter touches the private framework. A device, its registration,
// framework handle and Sendable callback context live until process exit: private
// unregister/stop does not document callback quiescence. Stop closes acceptance
// before the native call; no callback can access a released Swift object. Repeated
// pause/resume does not leak additional contexts/devices or register duplicates.
// A Magic Trackpad that reconnects gets a new adapter; the old one is retired, not freed.
@MainActor final class NativeTrackpadDevice {
    enum Kind: Sendable { case builtIn, magicTrackpad }

    private typealias Callback = @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer?, Int32,
                                                Double, Int32, UnsafeMutableRawPointer) -> Void

    private struct Framework {
        let createDefault: @convention(c) () -> UnsafeMutableRawPointer?
        let createList: @convention(c) () -> Unmanaged<CFArray>?
        let release: @convention(c) (UnsafeMutableRawPointer) -> Void
        let isBuiltIn: @convention(c) (UnsafeMutableRawPointer) -> Bool
        let deviceID: @convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<UInt64>) -> Int32
        let dimensions: @convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<Int32>, UnsafeMutablePointer<Int32>) -> Int32
        let start: @convention(c) (UnsafeMutableRawPointer, Int32) -> Int32
        let stop: @convention(c) (UnsafeMutableRawPointer) -> Int32
        let register: @convention(c) (UnsafeMutableRawPointer, Callback?, UnsafeMutableRawPointer?) -> Bool

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
                  let deviceID: @convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<UInt64>) -> Int32 = symbol("MTDeviceGetDeviceID"),
                  let dimensions: @convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<Int32>, UnsafeMutablePointer<Int32>) -> Int32
                    = symbol("MTDeviceGetSensorSurfaceDimensions"),
                  let start: @convention(c) (UnsafeMutableRawPointer, Int32) -> Int32 = symbol("MTDeviceStart"),
                  let stop: @convention(c) (UnsafeMutableRawPointer) -> Int32 = symbol("MTDeviceStop"),
                  let register: @convention(c) (UnsafeMutableRawPointer, Callback?, UnsafeMutableRawPointer?) -> Bool
                    = symbol("MTRegisterContactFrameCallbackWithRefcon") else { return nil }
            self.createDefault = createDefault; self.createList = createList; self.release = release
            self.isBuiltIn = isBuiltIn; self.deviceID = deviceID; self.dimensions = dimensions
            self.start = start; self.stop = stop; self.register = register
        }
    }

    private static let framework = Framework()
    private static var builtIn: NativeTrackpadDevice?
    private static var magicTrackpad: NativeTrackpadDevice?
    private static var retired: [NativeTrackpadDevice] = []

    let buffer: NativeTrackpadBuffer
    private let device: UnsafeMutableRawPointer?
    private let identifier: UInt64
    private var running = false
    private(set) var available = false
    private(set) var failed = false

    /// The built-in adapter always exists (possibly unavailable). The Magic Trackpad
    /// adapter exists only while such a device is connected; call again to rescan.
    static func acquire(mailbox: EngineMailbox, kind: Kind = .builtIn) -> NativeTrackpadDevice? {
        switch kind {
        case .builtIn:
            if let builtIn { return builtIn }
            var device = framework?.createDefault()
            if let found = device, framework?.isBuiltIn(found) != true { framework?.release(found); device = nil }
            let result = NativeTrackpadDevice(mailbox: mailbox, kind: kind, device: device, identifier: 0)
            builtIn = result
            return result
        case .magicTrackpad:
            guard let framework, let found = connectedMagicTrackpad(framework) else {
                if let magicTrackpad { magicTrackpad.stop(); retired.append(magicTrackpad) }
                magicTrackpad = nil
                return nil
            }
            if let magicTrackpad, magicTrackpad.identifier == found.identifier { return magicTrackpad }
            if let magicTrackpad { magicTrackpad.stop(); retired.append(magicTrackpad) }
            let result = NativeTrackpadDevice(mailbox: mailbox, kind: kind, device: found.device, identifier: found.identifier)
            magicTrackpad = result
            return result
        }
    }

    /// The first external multitouch surface that is wider than tall. A Magic Mouse
    /// surface is taller than wide. No names, serial numbers or inventory are read.
    private static func connectedMagicTrackpad(_ framework: Framework) -> (device: UnsafeMutableRawPointer, identifier: UInt64)? {
        guard let list = framework.createList()?.takeRetainedValue() as? [AnyObject] else { return nil }
        return withExtendedLifetime(list) {
            for object in list {
                let device = Unmanaged.passUnretained(object).toOpaque()
                var width: Int32 = 0, height: Int32 = 0, identifier: UInt64 = 0
                guard !framework.isBuiltIn(device), framework.dimensions(device, &width, &height) == 0, width > height,
                      framework.deviceID(device, &identifier) == 0, identifier != 0 else { continue }
                // The list owns its devices; a newly adopted one is kept alive for the process lifetime.
                if magicTrackpad?.identifier != identifier { _ = Unmanaged.passUnretained(object).retain() }
                return (device, identifier)
            }
            return nil
        }
    }

    private init(mailbox: EngineMailbox, kind: Kind, device: UnsafeMutableRawPointer?, identifier: UInt64) {
        buffer = NativeTrackpadBuffer(mailbox: mailbox, isMagicTrackpad: kind == .magicTrackpad)
        self.device = device
        self.identifier = identifier
        guard let device, let framework = Self.framework else { return }
        // Permanent process-owned device retains the buffer independently of UI.
        let context = Unmanaged.passUnretained(buffer).toOpaque()
        available = framework.register(device, { _, data, count, time, frame, context in
            Unmanaged<NativeTrackpadBuffer>.fromOpaque(context).takeUnretainedValue()
                .receive(data, count: count, callbackFrame: frame, callbackTime: time)
        }, context)
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
