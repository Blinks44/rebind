import Foundation
import Synchronization
import Testing
@testable import rebind

// Native benign fixtures exercise pipe draining and child lifecycle. No user's
// Apple Shortcut, shell command or output file is executed by these tests.
struct ShortcutsProcessTests {
    @Test func drainsOutputWhileChildRunsAndDoesNotInterpretArguments() async throws {
        let literal = "$(not-a-command) ; % text & \"quote\""
        let output = try await ShortcutsProcess.execute(arguments: ["%s", literal], collectOutput: true, timeout: 2,
            canContinue: { true }, executable: URL(filePath: "/usr/bin/printf"))
        #expect(String(data: output, encoding: .utf8) == literal)
    }

    @Test func childHasNoInheritedInputAndRunOutputIsDiscarded() async throws {
        #expect(try await ShortcutsProcess.execute(arguments: [], collectOutput: true, timeout: 2,
            canContinue: { true }, executable: URL(filePath: "/bin/cat")).isEmpty)
        #expect(try await ShortcutsProcess.execute(arguments: ["%s", "discard"], collectOutput: false, timeout: 2,
            canContinue: { true }, executable: URL(filePath: "/usr/bin/printf")).isEmpty)
    }

    @Test func unsuccessfulExitIsNotReportedAsCompleted() async {
        await #expect(throws: ShortcutsProcess.Failure.failed) {
            try await ShortcutsProcess.execute(arguments: [], collectOutput: true, timeout: 2,
                canContinue: { true }, executable: URL(filePath: "/usr/bin/false"))
        }
    }

    @Test func cancellationBeforeSpawnAndDuringWaitStopsOnlyChild() async {
        await #expect(throws: ShortcutsProcess.Failure.cancelled) {
            try await ShortcutsProcess.execute(arguments: [], collectOutput: false, timeout: 2,
                canContinue: { false }, executable: URL(filePath: "/not/an/executable"))
        }
        let checks = Mutex(0)
        await #expect(throws: ShortcutsProcess.Failure.cancelled) {
            try await ShortcutsProcess.execute(arguments: ["10"], collectOutput: false, timeout: 2,
                canContinue: { checks.withLock { $0 += 1; return $0 < 4 } }, executable: URL(filePath: "/bin/sleep"))
        }
        #expect(checks.withLock { $0 } >= 4)
    }

    @Test func parentTaskCancellationStopsTheCommand() async {
        let started = ProcessTestGate()
        let checks = Mutex(0)
        let task = Task {
            try await ShortcutsProcess.execute(arguments: ["10"], collectOutput: false, timeout: 2,
                canContinue: {
                    // Wait for the active command's next authorization check,
                    // rather than cancelling at the pre-spawn check.
                    if checks.withLock({ $0 += 1; return $0 >= 4 }) { started.signal() }
                    return true
                }, executable: URL(filePath: "/bin/sleep"))
        }
        await started.wait()
        task.cancel()
        await #expect(throws: ShortcutsProcess.Failure.cancelled) { try await task.value }
    }

    @Test func outputAtTheLimitIsAccepted() async throws {
        let output = try await ShortcutsProcess.execute(arguments: ["-c", "262144", "/dev/zero"],
            collectOutput: true, timeout: 2, canContinue: { true }, executable: URL(filePath: "/usr/bin/head"))
        #expect(output.count == 262_144)
    }

    @Test func timeoutAndOversizedOutputTerminateChildWithoutUnboundedBuffering() async {
        await #expect(throws: ShortcutsProcess.Failure.timedOut) {
            try await ShortcutsProcess.execute(arguments: ["10"], collectOutput: false, timeout: 0.05,
                canContinue: { true }, executable: URL(filePath: "/bin/sleep"))
        }
        await #expect(throws: ShortcutsProcess.Failure.invalidOutput) {
            try await ShortcutsProcess.execute(arguments: ["fixture"], collectOutput: true, timeout: 2,
                canContinue: { true }, executable: URL(filePath: "/usr/bin/yes"))
        }
    }
}

nonisolated private final class ProcessTestGate: Sendable {
    private struct State { var signalled = false; var waiter: CheckedContinuation<Void, Never>? }
    private let state = Mutex(State())
    func signal() {
        let waiter = state.withLock { state in
            state.signalled = true
            let waiter = state.waiter
            state.waiter = nil
            return waiter
        }
        waiter?.resume()
    }
    func wait() async {
        await withCheckedContinuation { continuation in
            state.withLock { state in
                if state.signalled { continuation.resume() } else { state.waiter = continuation }
            }
        }
    }
}
