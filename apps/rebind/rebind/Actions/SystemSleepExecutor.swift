import IOKit.pwr_mgt

nonisolated enum SystemSleepExecutor {
    static func isAvailable() -> Bool { IOPMSleepEnabled() != 0 }

    static func perform(canPerform: () -> Bool,
                        sleepEnabled: () -> Bool = { isAvailable() },
                        openConnection: () -> io_connect_t = { IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL)) },
                        requestSleep: (io_connect_t) -> IOReturn = { IOPMSleepSystem($0) },
                        closeConnection: (io_connect_t) -> Void = { _ = IOServiceClose($0) }) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard sleepEnabled() else { return .unavailable }
        let connection = openConnection()
        guard connection != 0 else { return .unavailable }
        defer { closeConnection(connection) }
        // Opening the root-domain connection can wait. Recheck immediately before
        // requesting sleep. Only the console user may request it; no root/helper fallback.
        guard canPerform() else { return .cancelled }
        // Success means macOS accepted the request, not that sleep completed.
        return requestSleep(connection) == kIOReturnSuccess ? .performed : .unavailable
    }
}
