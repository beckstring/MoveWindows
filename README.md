# MoveWindows

Windows-style `Win+Arrow` window snapping for macOS. A tiny, free, open-source
menu bar app — no dependencies, ~600 lines of Swift.

## Features

| Shortcut | Action |
|---|---|
| `⌘⇧←` / `⌘⇧→` | Snap the focused window to the left / right half |
| `⌘⇧↑` | Maximize (fill the screen — not native fullscreen) |
| `⌘⇧↓` | Restore the pre-maximize size |
| `⌘⇧←/→` then `⌘⇧↑/↓` | Quarter snapping, Windows-style (e.g. Left then Up → top-left quarter) |
| `⌘⌥⇧→` / `⌘⌥⇧←` | Throw the window to the next / previous display |

Windows that are snapped re-snap pixel-perfect on the destination display;
floating windows are rescaled proportionally.

> **Heads-up:** `⌘⇧←/→` shadows "select to start/end of line" in text editors.
> Use **Pause Shortcuts** in the menu bar icon when you need those, or change
> the bindings (see below).

## Install

Requires macOS 14+. No Xcode needed — the Swift toolchain from the Command
Line Tools is enough (`xcode-select --install`).

```sh
git clone https://github.com/beckstring/MoveWindows.git
cd MoveWindows
make install        # builds and copies to /Applications
open /Applications/MoveWindows.app
```

On first launch macOS asks for the **Accessibility** permission
(System Settings → Privacy & Security → Accessibility) — that's the API used
to move other apps' windows. There's no Dock icon; look for the rectangle
icon in the menu bar — its menu also lists all shortcuts.

Since release downloads aren't notarized (no paid Apple developer account),
Gatekeeper may complain about a downloaded build: right-click → Open, or
`xattr -d com.apple.quarantine MoveWindows.app`. Building from source avoids
this entirely.

## Customizing shortcuts

Edit [`Sources/MoveWindows/Keybindings.swift`](Sources/MoveWindows/Keybindings.swift)
— one small table of key codes and modifier masks — then `make install` again.

## Development

```sh
make test    # unit tests for the layout engine (pure math, no permissions needed)
make run     # run unbundled via swift run
make app     # build build/MoveWindows.app (ad-hoc signed)
```

**Tip — Accessibility permission during development:** run via `make run` from
your terminal. TCC attributes the permission to the *terminal* app, so grant
your terminal Accessibility once and every rebuilt binary inherits it.

For the bundled app, ad-hoc signing means the code signature changes on every
rebuild, which silently invalidates the Accessibility grant (the checkbox
stays on but stops working). Either:

- create a self-signed code-signing certificate in Keychain Access
  (Certificate Assistant → Create a Certificate → type "Code Signing", name it
  e.g. `MoveWindows Dev`) and build with
  `make install CODESIGN_IDENTITY="MoveWindows Dev"`, or
- after each rebuild, remove and re-add the app in System Settings →
  Accessibility, or run
  `sudo tccutil reset Accessibility com.philippnicolay.movewindows`.

### How it works

- **Hotkeys:** Carbon `RegisterEventHotKey` — still the only sanctioned API
  that both fires globally and swallows the keystroke (true Windows-key
  semantics).
- **Window control:** the Accessibility API (`AXUIElement`), setting
  `kAXPosition`/`kAXSize` with a size→position→size sequence because apps
  clamp the two independently.
- **Snap-state:** no per-window state. Each keypress *detects* the current
  layout by comparing the live frame against the computed layouts (with
  tolerance for apps like Terminal that quantize sizes), then runs a small
  transition table. `Sources/MoveWindowsCore` is pure geometry, fully
  unit-tested; all system integration lives in `Sources/MoveWindows`.
- **Coordinates:** the AX API uses top-left-origin coordinates, AppKit uses
  bottom-left. Everything is converted at the boundary
  (`ScreenCoordinates.flip`, an involution around the primary screen height).

## Known limitations

- **Native fullscreen windows** are deliberately left alone.
- **Stage Manager** may re-tile windows after a snap — best effort.
- **Secure Keyboard Entry** (password prompts, Terminal's "Secure Keyboard
  Entry" setting) suppresses all global hotkeys by design; shortcuts recover
  once it's off.
- Restore-after-maximize memory is per-session (not persisted across restarts).

## License

[MIT](LICENSE)
