import Foundation
import Subprocess
import System

/// Async child transport for Apple's CLI; one bounded action slot owns a running command.
nonisolated enum ShortcutsProcess {
    enum Failure: Error, Equatable { case failed, cancelled, timedOut, invalidOutput }

    static func execute(arguments: [String], collectOutput: Bool, timeout: TimeInterval,
                        canContinue: @escaping @Sendable () -> Bool,
                        executable: URL = URL(filePath: "/usr/bin/shortcuts")) async throws -> Data {
        guard !Task.isCancelled, canContinue() else { throw Failure.cancelled }
        guard timeout.isFinite, timeout > 0 else { throw Failure.timedOut }
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(timeout))
        do {
            return try await withThrowingTaskGroup(of: Data.self) { group in
                group.addTask {
                    guard !Task.isCancelled, canContinue() else { throw Failure.cancelled }
                    var options = Subprocess.PlatformOptions()
                    options.teardownSequence = [.gracefulShutDown(allowedDurationToNextStep: .milliseconds(250))]
                    let output: Data
                    let status: TerminationStatus
                    if collectOutput {
                        let result = try await Subprocess.run(.path(FilePath(executable.path)), arguments: Arguments(arguments),
                            platformOptions: options, input: .none, output: .data(limit: 262_144), error: .discarded)
                        output = result.standardOutput
                        status = result.terminationStatus
                    } else {
                        let result = try await Subprocess.run(.path(FilePath(executable.path)), arguments: Arguments(arguments),
                            platformOptions: options, input: .none, output: .discarded, error: .discarded)
                        output = Data()
                        status = result.terminationStatus
                    }
                    guard !Task.isCancelled, canContinue() else { throw Failure.cancelled }
                    guard status == .exited(0) else { throw Failure.failed }
                    return output
                }
                group.addTask {
                    // Only while a command runs. Lifecycle changes revoke its generation;
                    // cancelling the group tears down and reaps only this child.
                    while true {
                        guard canContinue() else { throw Failure.cancelled }
                        guard clock.now < deadline else { throw Failure.timedOut }
                        try await Task.sleep(for: .milliseconds(20))
                    }
                }
                defer { group.cancelAll() }
                guard let output = try await group.next() else { throw Failure.failed }
                return output
            }
        } catch is CancellationError { throw Failure.cancelled }
        catch let error as SubprocessError where error.code == .outputLimitExceeded { throw Failure.invalidOutput }
        catch let error as Failure { throw error }
        catch { throw Failure.failed }
    }
}
