import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let snapController = SnapController()
    private let hotkeyManager = HotkeyManager()
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager.onAction = { [snapController] action in
            snapController.handle(action)
        }
        statusItemController = StatusItemController(hotkeyManager: hotkeyManager)
        // Register hotkeys immediately; actions no-op with a beep until the
        // Accessibility permission is granted.
        hotkeyManager.start()
        AXPermissions.ensurePermission {
            // Nothing else to wire up — the grant takes effect on the next hotkey.
        }
    }
}
