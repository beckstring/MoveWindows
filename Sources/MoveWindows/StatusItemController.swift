import AppKit
import Carbon

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let hotkeyManager: HotkeyManager

    private let pauseItem = NSMenuItem(title: "Pause Shortcuts", action: #selector(togglePause), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private let permissionItem = NSMenuItem(title: "Grant Accessibility Permission…", action: #selector(openAccessibilitySettings), keyEquivalent: "")

    init(hotkeyManager: HotkeyManager) {
        self.hotkeyManager = hotkeyManager
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        updateIcon()

        let menu = NSMenu()
        menu.delegate = self
        for item in [pauseItem, loginItem, permissionItem] {
            item.target = self
        }

        menu.addItem(NSMenuItem.sectionHeader(title: "Shortcuts"))
        for item in Self.shortcutItems() {
            menu.addItem(item)
        }
        menu.addItem(.separator())

        menu.addItem(permissionItem)
        menu.addItem(pauseItem)
        menu.addItem(loginItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit MoveWindows", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        permissionItem.isHidden = AXPermissions.isTrusted
        pauseItem.state = hotkeyManager.isPaused ? .on : .off
        loginItem.isHidden = !LaunchAtLogin.isAvailable
        loginItem.state = LaunchAtLogin.isAvailable && LaunchAtLogin.isEnabled ? .on : .off
    }

    @objc private func togglePause() {
        hotkeyManager.setPaused(!hotkeyManager.isPaused)
        updateIcon()
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.toggle()
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Display-only menu items (no action → disabled) showing each shortcut,
    /// rendered from the keybindings table so a rebind updates this list too.
    private static func shortcutItems() -> [NSMenuItem] {
        let rows: [(HotkeyAction, String)] = [
            (.snapLeft, "Snap Left Half"),
            (.snapRight, "Snap Right Half"),
            (.snapUp, "Maximize / Snap Up"),
            (.snapDown, "Restore / Snap Down"),
            (.displayPrev, "Move to Previous Display"),
            (.displayNext, "Move to Next Display"),
        ]
        return rows.compactMap { action, title in
            guard let binding = keybindings[action] else { return nil }
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: keyEquivalent(for: binding.keyCode))
            item.keyEquivalentModifierMask = cocoaModifiers(from: binding.carbonModifiers)
            return item
        }
    }

    private static func keyEquivalent(for keyCode: UInt32) -> String {
        let functionKey: Int
        switch Int(keyCode) {
        case kVK_LeftArrow: functionKey = NSLeftArrowFunctionKey
        case kVK_RightArrow: functionKey = NSRightArrowFunctionKey
        case kVK_UpArrow: functionKey = NSUpArrowFunctionKey
        case kVK_DownArrow: functionKey = NSDownArrowFunctionKey
        default: return ""
        }
        guard let scalar = UnicodeScalar(functionKey) else { return "" }
        return String(Character(scalar))
    }

    private static func cocoaModifiers(from carbonModifiers: UInt32) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbonModifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if carbonModifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if carbonModifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonModifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        return flags
    }

    private func updateIcon() {
        let symbol = hotkeyManager.isPaused ? "rectangle.slash" : "rectangle.lefthalf.filled"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "MoveWindows")
        image?.isTemplate = true
        statusItem.button?.image = image
    }
}
