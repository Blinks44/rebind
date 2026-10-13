import Darwin
import Foundation

// Private Apple SPI, isolated here. No keyboard/AppleScript/CGSession fallback:
// an unavailable entry point must not turn into a different system operation.
nonisolated enum ScreenLockExecutor {
    typealias LockFunction = @convention(c) () -> Void
    private static let lock: LockFunction? = resolve()

    static func supportsSystemVersion(_ major: Int) -> Bool { (26...27).contains(major) }
    static var isAvailable: Bool { lock != nil }

    static func perform(canPerform: () -> Bool,
                        resolveRequest: () -> (() -> Void)? = { lock.map { function in { function() } } }) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard let function = resolveRequest() else { return .unavailable }
        // Dynamic loading can wait; recheck generation and protected context.
        guard canPerform() else { return .cancelled }
        function()
        // The void entry point provides no acknowledgement of actual locking.
        return .performed
    }

    private static func resolve() -> LockFunction? {
        guard supportsSystemVersion(ProcessInfo.processInfo.operatingSystemVersion.majorVersion) else { return nil }
        let path = "/System/Library/PrivateFrameworks/login.framework/Versions/A/login"
        guard let handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL) else { return nil }
        guard let symbol = dlsym(handle, "SACLockScreenImmediate") else {
            dlclose(handle)
            return nil
        }
        // Hold one image reference for the cached function pointer's lifetime.
        // Hammerspoon/macos-lock use this void ABI; do not interpret a return register.
        return unsafeBitCast(symbol, to: LockFunction.self)
    }
}
