import ApplicationServices
import Dispatch
import Darwin

nonisolated enum WindowActionResult: Equatable, Sendable {
    case performed, cancelled, unavailable
}

// Only the operations needed by this slice; the AX client and its elements
// stay on the serial action thread. Tests use local values, never real windows.
nonisolated protocol WindowAccessibility {
    associatedtype Element: Equatable
    var trusted: Bool { get }
    var application: Element? { get }
    func processID(of element: Element) -> pid_t?
    func element(_ attribute: String, of element: Element) -> Element?
    func isWindow(_ element: Element) -> Bool
    func isSettable(_ attribute: String, of element: Element) -> Bool
    func isEnabled(_ element: Element) -> Bool
    func setTrue(_ attribute: String, of element: Element) -> Bool
    func press(_ element: Element) -> Bool
}

nonisolated enum WindowActionExecutor {
    static func perform(_ action: WindowAction, canPerform: () -> Bool) -> WindowActionResult {
        perform(action, client: AXWindowAccessibility(), ownPID: getpid(), canPerform: canPerform)
    }

    static func perform<Client: WindowAccessibility>(_ action: WindowAction, client: Client,
                                                     ownPID: pid_t, canPerform: () -> Bool) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard client.trusted, let app = client.application,
              let pid = client.processID(of: app), pid > 0, pid != ownPID else { return .unavailable }
        let target: Client.Element
        let attribute: String?
        let window: Client.Element?
        switch action {
        case .hideApplication:
            guard client.isSettable(kAXHiddenAttribute, of: app) else { return .unavailable }
            target = app
            attribute = kAXHiddenAttribute
            window = nil
        case .close, .minimize, .toggleFullScreen:
            guard let focused = client.element(kAXFocusedWindowAttribute, of: app),
                  client.processID(of: focused) == pid, client.isWindow(focused) else { return .unavailable }
            window = focused
            if action == .minimize {
                guard client.isSettable(kAXMinimizedAttribute, of: focused) else { return .unavailable }
                target = focused
                attribute = kAXMinimizedAttribute
            } else {
                let buttonAttribute = action == .close ? kAXCloseButtonAttribute : kAXFullScreenButtonAttribute
                guard let button = client.element(buttonAttribute, of: focused),
                      client.processID(of: button) == pid, client.isEnabled(button) else { return .unavailable }
                target = button
                attribute = nil
            }
        }
        // AX reads may have waited for the other app. Never retarget a queued
        // action to a newly focused app/window, or mutate after pause/edit/sleep.
        guard client.application == app else { return .unavailable }
        if let window, client.element(kAXFocusedWindowAttribute, of: app) != window { return .unavailable }
        guard canPerform() else { return .cancelled }
        guard client.trusted else { return .unavailable }
        let success = attribute.map { client.setTrue($0, of: target) } ?? client.press(target)
        // Success means AX accepted the request. A save dialog or full-screen
        // animation belongs to the target app; no retry, auto-confirm or key fallback.
        return success ? .performed : .unavailable
    }
}

nonisolated struct AXWindowAccessibility: WindowLayoutAccessibility, WindowCyclingAccessibility {
    private let system = AXUIElementCreateSystemWide()
    private let startedAt = DispatchTime.now().uptimeNanoseconds
    private let budget: UInt64 = 450_000_000

    var trusted: Bool { AXIsProcessTrusted() }
    var application: AXUIElement? { element(kAXFocusedApplicationAttribute, of: system) }

    func processID(of element: AXUIElement) -> pid_t? {
        var pid: pid_t = 0
        return AXUIElementGetPid(element, &pid) == .success ? pid : nil
    }

    func element(_ attribute: String, of element: AXUIElement) -> AXUIElement? {
        guard let value = value(attribute, of: element), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        // CF's dynamic type ID is checked before bridging its opaque object.
        return unsafeDowncast(value, to: AXUIElement.self)
    }

    func isWindow(_ element: AXUIElement) -> Bool {
        (value(kAXRoleAttribute, of: element) as? String) == kAXWindowRole
    }

    func isEnabled(_ element: AXUIElement) -> Bool {
        guard let value = value(kAXEnabledAttribute, of: element), CFGetTypeID(value) == CFBooleanGetTypeID() else { return false }
        return CFBooleanGetValue(unsafeDowncast(value, to: CFBoolean.self))
    }

    func isSettable(_ attribute: String, of element: AXUIElement) -> Bool {
        guard prepare(element) else { return false }
        var settable: DarwinBoolean = false
        return AXUIElementIsAttributeSettable(element, attribute as CFString, &settable) == .success && settable.boolValue
    }

    func setTrue(_ attribute: String, of element: AXUIElement) -> Bool {
        guard prepare(element) else { return false }
        return AXUIElementSetAttributeValue(element, attribute as CFString, kCFBooleanTrue) == .success
    }

    func press(_ element: AXUIElement) -> Bool {
        guard prepare(element) else { return false }
        return AXUIElementPerformAction(element, kAXPressAction as CFString) == .success
    }

    func isStandardWindow(_ element: AXUIElement) -> Bool {
        (value(kAXSubroleAttribute, of: element) as? String) == kAXStandardWindowSubrole
    }

    func isMinimized(_ element: AXUIElement) -> Bool? {
        guard let value = value(kAXMinimizedAttribute, of: element), CFGetTypeID(value) == CFBooleanGetTypeID() else { return nil }
        return CFBooleanGetValue(unsafeDowncast(value, to: CFBoolean.self))
    }

    func frame(of element: AXUIElement) -> CGRect? {
        guard let position = axValue(kAXPositionAttribute, of: element, type: .cgPoint),
              let size = axValue(kAXSizeAttribute, of: element, type: .cgSize) else { return nil }
        var point = CGPoint.zero
        var dimensions = CGSize.zero
        guard AXValueGetValue(position, .cgPoint, &point), AXValueGetValue(size, .cgSize, &dimensions) else { return nil }
        let frame = CGRect(origin: point, size: dimensions)
        return WindowLayoutGeometry.valid(frame) ? frame : nil
    }

    private func axValue(_ attribute: String, of element: AXUIElement, type: AXValueType) -> AXValue? {
        guard let value = value(attribute, of: element), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        let typed = unsafeDowncast(value, to: AXValue.self)
        return AXValueGetType(typed) == type ? typed : nil
    }

    func setPosition(_ position: CGPoint, of element: AXUIElement) -> Bool {
        var point = position
        guard point.x.isFinite, point.y.isFinite, let value = AXValueCreate(.cgPoint, &point), prepare(element) else { return false }
        return AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value) == .success
    }

    func setSize(_ size: CGSize, of element: AXUIElement) -> Bool {
        var size = size
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0,
              let value = AXValueCreate(.cgSize, &size), prepare(element) else { return false }
        return AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value) == .success
    }

    func windows(of application: AXUIElement, limit: Int) -> [AXUIElement]? {
        guard prepare(application) else { return nil }
        var count = 0
        guard AXUIElementGetAttributeValueCount(application, kAXWindowsAttribute as CFString, &count) == .success,
              count >= 0, count <= limit else { return nil }
        if count == 0 { return [] }
        guard prepare(application) else { return nil }
        var values: CFArray?
        guard AXUIElementCopyAttributeValues(application, kAXWindowsAttribute as CFString, 0, count, &values) == .success,
              let array = values as? [AnyObject], array.count == count,
              array.allSatisfy({ CFGetTypeID($0) == AXUIElementGetTypeID() }) else { return nil }
        return array.map { unsafeDowncast($0, to: AXUIElement.self) }
    }

    func isModal(_ element: AXUIElement) -> Bool? {
        guard let value = value(kAXModalAttribute, of: element), CFGetTypeID(value) == CFBooleanGetTypeID() else { return nil }
        return CFBooleanGetValue(unsafeDowncast(value, to: CFBoolean.self))
    }

    func canRaise(_ element: AXUIElement) -> Bool {
        guard prepare(element) else { return false }
        var actions: CFArray?
        guard AXUIElementCopyActionNames(element, &actions) == .success,
              let names = actions as? [String] else { return false }
        return names.contains(kAXRaiseAction as String)
    }

    func raise(_ element: AXUIElement) -> Bool {
        guard prepare(element) else { return false }
        return AXUIElementPerformAction(element, kAXRaiseAction as CFString) == .success
    }

    private func value(_ attribute: String, of element: AXUIElement) -> CFTypeRef? {
        guard prepare(element) else { return nil }
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }

    private func prepare(_ element: AXUIElement) -> Bool {
        let now = DispatchTime.now().uptimeNanoseconds
        guard now >= startedAt, now - startedAt < budget else { return false }
        let remaining = Float(budget - (now - startedAt)) / 1_000_000_000
        // The system-wide object's timeout also sets this process's AX default.
        // All subsequent calls are bounded individually and by the slice budget.
        return AXUIElementSetMessagingTimeout(element, min(0.15, remaining)) == .success
    }
}
