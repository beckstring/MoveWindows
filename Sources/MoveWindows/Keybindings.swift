import Carbon

/// The single place to change keyboard shortcuts.
///
/// `keyCode` values are Carbon virtual key codes (`kVK_*` in Carbon.HIToolbox).
/// `carbonModifiers` are Carbon modifier masks — NOT NSEvent.ModifierFlags:
///   cmdKey = 0x100, shiftKey = 0x200, optionKey = 0x800, controlKey = 0x1000.
enum HotkeyAction: UInt32, CaseIterable {
    case snapLeft = 1
    case snapRight
    case snapUp
    case snapDown
    case displayNext
    case displayPrev
}

struct Keybinding: Sendable {
    let keyCode: UInt32
    let carbonModifiers: UInt32
}

// Windows layout: Cmd+Arrow snaps (like Win+Arrow), Cmd+Shift+Arrow moves
// between displays (like Win+Shift+Arrow). Note that plain Cmd+Arrow shadows
// macOS text navigation (line start/end, document top/bottom) and browser
// back/forward — use the menu bar's "Pause Shortcuts" when you need those.
let keybindings: [HotkeyAction: Keybinding] = [
    .snapLeft: Keybinding(keyCode: UInt32(kVK_LeftArrow), carbonModifiers: UInt32(cmdKey)),
    .snapRight: Keybinding(keyCode: UInt32(kVK_RightArrow), carbonModifiers: UInt32(cmdKey)),
    .snapUp: Keybinding(keyCode: UInt32(kVK_UpArrow), carbonModifiers: UInt32(cmdKey)),
    .snapDown: Keybinding(keyCode: UInt32(kVK_DownArrow), carbonModifiers: UInt32(cmdKey)),
    .displayNext: Keybinding(keyCode: UInt32(kVK_RightArrow), carbonModifiers: UInt32(cmdKey | shiftKey)),
    .displayPrev: Keybinding(keyCode: UInt32(kVK_LeftArrow), carbonModifiers: UInt32(cmdKey | shiftKey)),
]
