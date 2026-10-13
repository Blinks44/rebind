import Darwin
import Foundation

// Narrow transport for Apple's CLI. Call only outside MainActor/event callbacks.
// The listing pipe is drained while the child runs; run output is discarded.
nonisolated enum ShortcutsProcess {
    enum Failure: Error, Equatable { case failed, cancelled, timedOut, invalidOutput }

    static func execute(arguments: [String], collectOutput: Bool, timeout: TimeInterval,
                        canContinue: () -> Bool,
                        executable: URL = URL(filePath: "/usr/bin/shortcuts")) throws -> Data {
        guard canContinue() else { throw Failure.cancelled }
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        let pipe = collectOutput ? Pipe() : nil
        if let pipe { process.standardOutput = pipe }
        else { process.standardOutput = FileHandle.nullDevice }
        defer {
            try? pipe?.fileHandleForReading.close()
            try? pipe?.fileHandleForWriting.close()
        }
        if let pipe {
            let fd = pipe.fileHandleForReading.fileDescriptor
            guard fcntl(fd, F_SETFL, O_NONBLOCK) != -1 else { throw Failure.failed }
        }
        guard canContinue() else { throw Failure.cancelled }
        try process.run()
        try? pipe?.fileHandleForWriting.close()
        var output = Data()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(timeout))
        do {
            while true {
                guard canContinue() else { throw Failure.cancelled }
                guard clock.now < deadline else { throw Failure.timedOut }
                if let pipe { try drain(pipe.fileHandleForReading.fileDescriptor, into: &output) }
                if !process.isRunning {
                    if let pipe { try drain(pipe.fileHandleForReading.fileDescriptor, into: &output) }
                    guard process.terminationReason == .exit, process.terminationStatus == 0 else { throw Failure.failed }
                    return output
                }
                Thread.sleep(forTimeInterval: 0.02)
            }
        } catch {
            if process.isRunning {
                process.terminate()
                let grace = clock.now.advanced(by: .milliseconds(250))
                while process.isRunning, clock.now < grace { Thread.sleep(forTimeInterval: 0.01) }
                if process.isRunning { _ = kill(process.processIdentifier, SIGKILL) }
                // Reap only our child; no shell or process-group termination.
                // OS termination cannot roll back an accepted shortcut's effects.
                process.waitUntilExit()
            }
            throw error
        }
    }

    private static func drain(_ fd: Int32, into output: inout Data) throws {
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let count = read(fd, &buffer, buffer.count)
            if count == 0 { return }
            if count < 0 {
                if errno == EINTR { continue }
                if errno == EAGAIN || errno == EWOULDBLOCK { return }
                throw Failure.failed
            }
            guard output.count + count <= 262_144 else { throw Failure.invalidOutput }
            output.append(contentsOf: buffer.prefix(count))
        }
    }
}
