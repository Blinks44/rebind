import Foundation
import Testing
@testable import rebind

// Native benign fixtures exercise pipe draining and child lifecycle. No user's
// Apple Shortcut, shell command or output file is executed by these tests.
struct ShortcutsProcessTests {
    @Test func drainsOutputWhileChildRunsAndDoesNotInterpretArguments() throws {
        let literal = "$(not-a-command) ; % text & \"quote\""
        let output = try ShortcutsProcess.execute(arguments: ["%s", literal], collectOutput: true, timeout: 2,
            canContinue: { true }, executable: URL(filePath: "/usr/bin/printf"))
        #expect(String(data: output, encoding: .utf8) == literal)
    }

    @Test func childHasNoInheritedInputAndRunOutputIsDiscarded() throws {
        #expect(try ShortcutsProcess.execute(arguments: [], collectOutput: true, timeout: 2,
            canContinue: { true }, executable: URL(filePath: "/bin/cat")).isEmpty)
        #expect(try ShortcutsProcess.execute(arguments: ["%s", "discard"], collectOutput: false, timeout: 2,
            canContinue: { true }, executable: URL(filePath: "/usr/bin/printf")).isEmpty)
    }

    @Test func unsuccessfulExitIsNotReportedAsCompleted() {
        #expect(throws: ShortcutsProcess.Failure.failed) {
            try ShortcutsProcess.execute(arguments: [], collectOutput: true, timeout: 2,
                canContinue: { true }, executable: URL(filePath: "/usr/bin/false"))
        }
    }

    @Test func cancellationBeforeSpawnAndDuringWaitStopsOnlyChild() {
        #expect(throws: ShortcutsProcess.Failure.cancelled) {
            try ShortcutsProcess.execute(arguments: [], collectOutput: false, timeout: 2,
                canContinue: { false }, executable: URL(filePath: "/not/an/executable"))
        }
        var checks = 0
        #expect(throws: ShortcutsProcess.Failure.cancelled) {
            try ShortcutsProcess.execute(arguments: ["10"], collectOutput: false, timeout: 2,
                canContinue: { checks += 1; return checks < 4 }, executable: URL(filePath: "/bin/sleep"))
        }
        #expect(checks == 4)
    }

    @Test func timeoutAndOversizedOutputTerminateChildWithoutUnboundedBuffering() {
        #expect(throws: ShortcutsProcess.Failure.timedOut) {
            try ShortcutsProcess.execute(arguments: ["10"], collectOutput: false, timeout: 0.05,
                canContinue: { true }, executable: URL(filePath: "/bin/sleep"))
        }
        #expect(throws: ShortcutsProcess.Failure.invalidOutput) {
            try ShortcutsProcess.execute(arguments: ["fixture"], collectOutput: true, timeout: 2,
                canContinue: { true }, executable: URL(filePath: "/usr/bin/yes"))
        }
    }
}
