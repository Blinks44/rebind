import ApplicationServices
import Foundation

// The copy API and on-console key are public; the screen-lock key/notifications
// are undocumented. Never retain/display/log the session dictionary or user data.
// Query on the UI lifecycle poll / serial action worker, never in the event tap.
nonisolated enum ScreenLockSession {
    static let lockedNotification = Notification.Name("com.apple.screenIsLocked")
    static let unlockedNotification = Notification.Name("com.apple.screenIsUnlocked")

    static func allowsInput() -> Bool {
        allowsInput(session: CGSessionCopyCurrentDictionary() as? [String: Any])
    }

    static func allowsInput(session: [String: Any]?) -> Bool {
        guard let session, boolean(session[kCGSessionOnConsoleKey as String]) == true else { return false }
        // Observed absent while unlocked; MacLock uses the same convention.
        // A malformed/present non-boolean value fails closed.
        guard let value = session["CGSSessionScreenIsLocked"] else { return true }
        return boolean(value) == false
    }

    private static func boolean(_ value: Any?) -> Bool? {
        guard let value, CFGetTypeID(value as CFTypeRef) == CFBooleanGetTypeID() else { return nil }
        return CFBooleanGetValue(unsafeDowncast(value as CFTypeRef, to: CFBoolean.self))
    }
}
