import ApplicationServices
import Carbon

enum ProbeSession {
    static func allowsCapture() -> Bool {
        guard !IsSecureEventInputEnabled(),
              let session = CGSessionCopyCurrentDictionary() as? [String: Any],
              boolean(session[kCGSessionOnConsoleKey as String]) == true else { return false }
        // Same compatibility-limited lock guard as Rebind's ScreenLockSession;
        // no session identity or dictionary is retained or printed.
        guard let locked = session["CGSSessionScreenIsLocked"] else { return true }
        return boolean(locked) == false
    }

    private static func boolean(_ value: Any?) -> Bool? {
        guard let value, CFGetTypeID(value as CFTypeRef) == CFBooleanGetTypeID() else { return nil }
        return CFBooleanGetValue(unsafeDowncast(value as CFTypeRef, to: CFBoolean.self))
    }
}
