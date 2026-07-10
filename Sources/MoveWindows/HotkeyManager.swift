import AppKit
import Carbon

/// Registers global hotkeys via Carbon's RegisterEventHotKey, which both fires
/// reliably and swallows the keystroke system-wide (Windows-key semantics).
@MainActor
final class HotkeyManager {
    var onAction: ((HotkeyAction) -> Void)?

    /// While paused the hotkeys are UNREGISTERED (not ignored) so that
    /// Cmd+Shift+Arrow reaches the frontmost app for text selection.
    private(set) var isPaused = false

    private var hotkeyRefs: [HotkeyAction: EventHotKeyRef] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private let signature: OSType = 0x4D56_574E // 'MVWN'

    func start() {
        installEventHandler()
        registerAll()
    }

    func setPaused(_ paused: Bool) {
        guard paused != isPaused else { return }
        isPaused = paused
        if paused {
            unregisterAll()
        } else {
            registerAll()
        }
    }

    private func installEventHandler() {
        guard eventHandlerRef == nil else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let callback: EventHandlerUPP = { _, event, userData in
            var hotkeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )
            guard status == noErr, let userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            // The dispatcher target delivers on the main run loop.
            MainActor.assumeIsolated {
                if let action = HotkeyAction(rawValue: hotkeyID.id) {
                    manager.onAction?(action)
                }
            }
            return noErr
        }
        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }

    private func registerAll() {
        for action in HotkeyAction.allCases {
            guard hotkeyRefs[action] == nil, let binding = keybindings[action] else { continue }
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                binding.keyCode,
                binding.carbonModifiers,
                EventHotKeyID(signature: signature, id: action.rawValue),
                GetEventDispatcherTarget(),
                0,
                &ref
            )
            if status == noErr, let ref {
                hotkeyRefs[action] = ref
            } else {
                NSLog("MoveWindows: failed to register hotkey for \(action) (status \(status))")
            }
        }
    }

    private func unregisterAll() {
        for (_, ref) in hotkeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotkeyRefs.removeAll()
    }
}
