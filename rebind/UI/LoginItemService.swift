/// Main-actor boundary for native login registration and injectable verification.
@MainActor protocol LoginItemService {
    var status: LoginItemStatus { get }
    func register() throws
    func unregister() async throws
    func openLoginItems()
}
