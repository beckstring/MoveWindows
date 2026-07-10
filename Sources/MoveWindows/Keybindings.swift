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

let keybindings: [HotkeyAction: Keybinding] = [
    .snapLeft: Keybinding(keyCode: UInt32(kVK_LeftArrow), carbonModifiers: UInt32(cmdKey | shiftKey)),
    .snapRight: Keybinding(keyCode: UInt32(kVK_RightArrow), carbonModifiers: UInt32(cmdKey | shiftKey)),
    .snapUp: Keybinding(keyCode: UInt32(kVK_UpArrow), carbonModifiers: UInt32(cmdKey | shiftKey)),
    .snapDown: Keybinding(keyCode: UInt32(kVK_DownArrow), carbonModifiers: UInt32(cmdKey | shiftKey)),
    .displayNext: Keybinding(keyCode: UInt32(kVK_RightArrow), carbonModifiers: UInt32(cmdKey | optionKey | shiftKey)),
    .displayPrev: Keybinding(keyCode: UInt32(kVK_LeftArrow), carbonModifiers: UInt32(cmdKey | optionKey | shiftKey)),
]
