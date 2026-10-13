// Two observed applications only. A requested activation never changes history:
// Activation observations, rather than dispatch results, establish the order.
nonisolated struct ApplicationActivationHistory<Application: Equatable> {
    private(set) var current: Application?
    private(set) var previous: Application?

    mutating func observe(_ application: Application) {
        guard application != current else { return }
        previous = current
        current = application
    }

    mutating func clear() {
        current = nil
        previous = nil
    }
}
