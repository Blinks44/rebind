import Foundation

nonisolated struct ActionDispatch: Equatable, Sendable {
    var id = UUID()
    var action: RebindAction
    var revision: UInt64
    var deviceID: UInt32?
}
