import AppKit
import ApplicationServices

/// In-memory storage of pre-maximize frames (Cocoa coordinates) so that
/// maximized+Down can restore. Not persisted across app restarts.
@MainActor
final class WindowFrameStore {
    private struct WindowKey: Hashable {
        let pid: pid_t
        let element: AXUIElement

        static func == (lhs: WindowKey, rhs: WindowKey) -> Bool {
            lhs.pid == rhs.pid && CFEqual(lhs.element, rhs.element)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(pid)
            hasher.combine(CFHash(element))
        }
    }

    private var frames: [WindowKey: CGRect] = [:]
    private var terminationObserver: NSObjectProtocol?

    init() {
        terminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let pid = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?
                .processIdentifier
            guard let pid else { return }
            MainActor.assumeIsolated {
                self?.evict(pid: pid)
            }
        }
    }

    func store(_ cocoaFrame: CGRect, for window: AXWindow) {
        frames[WindowKey(pid: window.pid, element: window.element)] = cocoaFrame
    }

    func retrieve(for window: AXWindow) -> CGRect? {
        frames.removeValue(forKey: WindowKey(pid: window.pid, element: window.element))
    }

    private func evict(pid: pid_t) {
        frames = frames.filter { $0.key.pid != pid }
    }
}
