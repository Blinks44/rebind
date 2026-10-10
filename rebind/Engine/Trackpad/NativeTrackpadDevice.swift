import Darwin
import Foundation

// Only this adapter touches the private framework. Its one device, registration,
// framework handle and Sendable callback context live until process exit: private
// unregister/stop does not document callback quiescence. Stop closes acceptance
// before the native call; no callback can access a released Swift object. Repeated
// pause/resume does not leak additional contexts/devices or register duplicates.
@MainActor final class NativeTrackpadDevice {
    private typealias Callback = @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer?, Int32,
                                                Double, Int32, UnsafeMutableRawPointer) -> Void
    private typealias Start = @convention(c) (UnsafeMutableRawPointer, Int32) -> Int32
    private typealias Stop = @convention(c) (UnsafeMutableRawPointer) -> Int32
    private typealias IsBuiltIn = @convention(c) (UnsafeMutableRawPointer) -> Bool
    private typealias Register = @convention(c) (UnsafeMutableRawPointer, Callback?, UnsafeMutableRawPointer?) -> Bool
    private typealias Create = @convention(c) () -> UnsafeMutableRawPointer?
    private typealias Release = @convention(c) (UnsafeMutableRawPointer) -> Void

    private static var retainedDevice: NativeTrackpadDevice?
    let buffer: NativeTrackpadBuffer
    private var handle: UnsafeMutableRawPointer?
    private var device: UnsafeMutableRawPointer?
    private var startFunction: Start?
    private var stopFunction: Stop?
    private var running = false
    private(set) var available = false
    private(set) var failed = false

    static func acquire(mailbox: EngineMailbox) -> NativeTrackpadDevice {
        if let retainedDevice { return retainedDevice }
        let result = NativeTrackpadDevice(mailbox: mailbox)
        retainedDevice = result
        return result
    }

    private init(mailbox: EngineMailbox) {
        buffer = NativeTrackpadBuffer(mailbox: mailbox)
        // New major OS releases require another private-ABI audit. This is a
        // compatibility gate, not a hardware-verification claim for macOS 26.
        guard (26...27).contains(ProcessInfo.processInfo.operatingSystemVersion.majorVersion) else { return }
        // No inventory, serial numbers or external device enumeration.
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_LOCAL | RTLD_LAZY) else { return }
        self.handle = handle
        func symbol<T>(_ name: String, as type: T.Type) -> T? {
            guard let address = dlsym(handle, name) else { return nil }
            return unsafeBitCast(address, to: type)
        }
        guard let create = symbol("MTDeviceCreateDefault", as: Create.self),
              let release = symbol("MTDeviceRelease", as: Release.self),
              let builtIn = symbol("MTDeviceIsBuiltIn", as: IsBuiltIn.self),
              let start = symbol("MTDeviceStart", as: Start.self),
              let stop = symbol("MTDeviceStop", as: Stop.self),
              let register = symbol("MTRegisterContactFrameCallbackWithRefcon", as: Register.self),
              let device = create() else { return }
        guard builtIn(device) else { release(device); return }
        self.device = device
        startFunction = start
        stopFunction = stop
        // Permanent process-owned device retains the buffer independently of UI.
        let context = Unmanaged.passUnretained(buffer).toOpaque()
        available = register(device, { _, data, count, _, _, context in
            Unmanaged<NativeTrackpadBuffer>.fromOpaque(context).takeUnretainedValue().receive(data, count: count)
        }, context)
    }

    @discardableResult func start() -> Bool {
        guard available, !failed, let device, let startFunction else { return false }
        guard !running else { return true }
        buffer.setAccepting(true)
        // Mode 0 matches the verified probe. No private settings/gesture suppression.
        running = startFunction(device, 0) == 0
        if !running { buffer.setAccepting(false); failed = true }
        return running
    }

    func stop() {
        buffer.setAccepting(false)
        guard running, let device, let stopFunction else { return }
        running = false
        if stopFunction(device) != 0 { failed = true }
    }
}
