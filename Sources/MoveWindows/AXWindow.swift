import AppKit
import ApplicationServices

/// Wrapper around the Accessibility API for the focused window of the
/// frontmost app. All frames at this layer are in AX coordinates
/// (top-left origin, +y down).
struct AXWindow {
    let element: AXUIElement
    let appElement: AXUIElement
    let pid: pid_t

    // Not defined as constants in the AX headers.
    private static let fullScreenAttribute = "AXFullScreen"
    private static let enhancedUserInterfaceAttribute = "AXEnhancedUserInterface"

    @MainActor
    static func focused() -> AXWindow? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        // Don't let a beachballing app hang the hotkey handler for the 6 s default.
        AXUIElementSetMessagingTimeout(appElement, 0.25)

        var focused: CFTypeRef?
        var result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focused)
        if result != .success || focused == nil {
            // Some apps don't report a focused window; fall back to the first window.
            var windows: CFTypeRef?
            result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows)
            guard result == .success, let list = windows as? [AXUIElement], let first = list.first else {
                return nil
            }
            focused = first
        }
        guard let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
        let element = unsafeDowncast(focused, to: AXUIElement.self)
        return AXWindow(element: element, appElement: appElement, pid: pid)
    }

    /// Native-fullscreen windows must never be moved — it corrupts the Space.
    var isFullscreen: Bool {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, Self.fullScreenAttribute as CFString, &value)
        return result == .success && (value as? Bool) == true
    }

    /// Standard windows only — skip palettes, sheets, and dialogs.
    var isStandardWindow: Bool {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &value)
        guard result == .success, let subrole = value as? String else {
            // No subrole reported: give the window the benefit of the doubt.
            return true
        }
        return subrole == kAXStandardWindowSubrole
    }

    /// Window frame in AX (top-left origin) coordinates.
    var frame: CGRect? {
        guard let position = copyPoint(kAXPositionAttribute),
              let size = copySize(kAXSizeAttribute)
        else { return nil }
        return CGRect(origin: position, size: size)
    }

    /// Sets the frame using the size → position → size dance: apps clamp
    /// position and size independently, and some (Terminal) re-clamp the size
    /// after a move. Reads back and retries the size once on a large miss.
    func setFrame(_ axRect: CGRect) {
        let restoreEnhancedUI = disableEnhancedUserInterface()
        defer { if restoreEnhancedUI { enableEnhancedUserInterface() } }

        setSize(axRect.size)
        setPosition(axRect.origin)
        setSize(axRect.size)

        if let actual = frame,
           abs(actual.width - axRect.width) > 10 || abs(actual.height - axRect.height) > 10 {
            setSize(axRect.size)
        }
    }

    // MARK: - Attribute plumbing

    private func setPosition(_ point: CGPoint) {
        var value = point
        guard let axValue = AXValueCreate(.cgPoint, &value) else { return }
        AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, axValue)
    }

    private func setSize(_ size: CGSize) {
        var value = size
        guard let axValue = AXValueCreate(.cgSize, &value) else { return }
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, axValue)
    }

    private func copyAXValue(_ attribute: String) -> AXValue? {
        var raw: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &raw)
        guard result == .success, let raw, CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        return unsafeDowncast(raw, to: AXValue.self)
    }

    private func copyPoint(_ attribute: String) -> CGPoint? {
        guard let axValue = copyAXValue(attribute) else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func copySize(_ attribute: String) -> CGSize? {
        guard let axValue = copyAXValue(attribute) else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else { return nil }
        return size
    }

    /// Some apps (notably Electron/Chromium) set AXEnhancedUserInterface on
    /// themselves, which animates/mangles AX frame writes. Temporarily disable
    /// it around the write. Returns true if it was on and should be restored.
    private func disableEnhancedUserInterface() -> Bool {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, Self.enhancedUserInterfaceAttribute as CFString, &value)
        guard result == .success, (value as? Bool) == true else { return false }
        AXUIElementSetAttributeValue(appElement, Self.enhancedUserInterfaceAttribute as CFString, kCFBooleanFalse)
        return true
    }

    private func enableEnhancedUserInterface() {
        AXUIElementSetAttributeValue(appElement, Self.enhancedUserInterfaceAttribute as CFString, kCFBooleanTrue)
    }
}
