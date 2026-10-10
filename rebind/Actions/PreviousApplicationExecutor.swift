@MainActor protocol PreviousApplicationClient {
    associatedtype Application: Equatable
    var frontmostApplication: Application? { get }
    func isOwnApplication(_ application: Application) -> Bool
    func isEligible(_ application: Application) -> Bool
    func activate(_ application: Application, from source: Application,
                  canPerform: @escaping @Sendable () -> Bool) async -> WindowActionResult
}

@MainActor enum PreviousApplicationExecutor {
    static func perform<Client: PreviousApplicationClient>(
        history: inout ApplicationActivationHistory<Client.Application>,
        client: Client, canPerform: @escaping @Sendable () -> Bool
    ) async -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard let frontmost = client.frontmostApplication else { return .unavailable }
        let target: Client.Application?
        if client.isOwnApplication(frontmost) {
            target = history.current
        } else {
            guard client.isEligible(frontmost) else { return .unavailable }
            // Resample in case the activation notification has not been delivered yet.
            history.observe(frontmost)
            target = history.previous
        }
        guard let target, target != frontmost, client.isEligible(target),
              client.frontmostApplication == frontmost, client.isEligible(target) else { return .unavailable }
        guard canPerform() else { return .cancelled }
        return await client.activate(target, from: frontmost, canPerform: canPerform)
    }
}
