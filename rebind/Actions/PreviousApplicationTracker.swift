import AppKit

@MainActor final class PreviousApplicationTracker<Client: PreviousApplicationClient>: NSObject {
    private var history = ApplicationActivationHistory<Client.Application>()
    private var observing = false
    private let client: Client
    private let notificationCenter: NotificationCenter
    private let applicationFromNotification: (Notification) -> Client.Application?

    init(client: Client, notificationCenter: NotificationCenter,
         applicationFromNotification: @escaping (Notification) -> Client.Application?) {
        self.client = client
        self.notificationCenter = notificationCenter
        self.applicationFromNotification = applicationFromNotification
        super.init()
    }

    func start() {
        guard !observing else { return }
        observing = true
        notificationCenter.addObserver(self, selector: #selector(activated(_:)),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
        sampleFrontmostApplication()
    }

    func stop() {
        notificationCenter.removeObserver(self)
        observing = false
        history.clear()
    }

    @objc private func activated(_ notification: Notification) {
        // AppKit can post before frontmostApplication reflects this activation.
        // Use the affected app from the notification, preserving event order.
        guard observing, let application = applicationFromNotification(notification),
              client.isEligible(application) else { return }
        history.observe(application)
    }

    private func sampleFrontmostApplication() {
        guard let application = client.frontmostApplication, client.isEligible(application) else { return }
        history.observe(application)
    }

    func perform(canPerform: @escaping @Sendable () -> Bool) async -> WindowActionResult {
        guard observing else { return .unavailable }
        sampleFrontmostApplication()
        // Notifications may update live history while activation awaits AX IPC.
        // Keep inout access local so observations never overlap that access.
        var snapshot = history
        return await PreviousApplicationExecutor.perform(history: &snapshot, client: client, canPerform: canPerform)
    }
}

extension PreviousApplicationTracker where Client == NativePreviousApplicationClient {
    convenience init() {
        self.init(client: NativePreviousApplicationClient(), notificationCenter: NSWorkspace.shared.notificationCenter) {
            $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        }
    }
}
