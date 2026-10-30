# Changelog

Notable changes to Rebind. Versions follow the app version shown in **About Rebind**.

## 1.3.1: 2026-10-30

- Fixed built-in trackpad gestures stopping after the Mac slept for a long time with the lid closed.

## 1.3.0: 2026-10-29

- Rebind now runs on macOS 15 Sequoia and later.
- Magic Mouse: tap the left or right half with one finger to run a separate action. Experimental, like the other Magic Mouse gestures.
- The update window now shows what changed.
- The setup window no longer shows Check Again once access is granted.

## 1.2.0: 2026-10-28

- Moved Devices from Settings to the sidebar (⌘6).
- Moved wheel direction, wheel speed and mouse gesture distance to the All mice card in Devices, and excluded apps to Settings → General. The Input tab is gone.
- Clicking a device in the menu bar battery list opens Devices.

## 1.1.0: 2026-10-28

- Added G915 TKL lighting controls: brightness, color, idle timeout and low-battery colors. Idle-off and key-press wake are tester-confirmed; compatible Logitech RGB keyboards and mice have experimental support.
- Added standard actions, including Spotlight, Emoji & Symbols, microphone mute, fast-forward, rewind and Fill with Left Margin.
- Reduced background work while idle.
- Fixed long Apple Shortcuts delaying held-key and mouse-button releases.
- Improved action errors in the main window and menu bar, and wording in all six languages.

## 1.0.0: 2026-10-24

First public version.

### Triggers

- Keys and shortcuts, middle and extra mouse buttons, with press, double press and hold.
- Experimental Magic Mouse: one-, two- and three-finger taps, three-finger physical click, two-finger scroll up/down.
- A hold binding can send a shortcut on a short press and act on a long one.
- Mouse wheel steps, a held button plus movement, and a held button plus the wheel.
- Trackpad taps, double taps, clicks and corner taps, optionally with one held modifier key, for the built-in trackpad and an external Magic Trackpad.

### Actions

- Keyboard shortcuts, optionally kept pressed and repeated while the trigger is held; volume, brightness and scrolling can repeat the same way.
- Hold Command, Option, Control or Shift from a key or mouse button.
- Named commands: Copy, Paste, Cut, Undo, Redo, Select All, Back, Forward, tab and zoom commands, screenshots.
- Insert Text, Do Nothing, mouse clicks and scrolling.
- Windows: halves, quarters, fill, center, next display, close, minimize, full screen, window cycling.
- Apps and system: open, activate and quit apps, previous app, files, folders and web addresses, Apple Shortcuts, Mission Control and desktops, sound and media, display brightness, sleep and lock.
- Pause Rebind and switch profiles from a binding.

### App

- Profiles with manual selection; duplicate a binding, copy it to another profile, add a note.
- Export and import single profiles; full backup, restore and reset.
- Rules limited to one foreground app, plus separate app exclusions for bindings and smooth scrolling.
- Per-mouse smooth scrolling, wheel direction and speed, and adjustable mouse gesture distance.
- Supported Logitech settings: SmartShift, sensitivity, DPI, high-resolution wheel and gesture-button diversion. Device names and available battery levels in the menu bar.
- Automatic backups of the last 10 different configurations loaded at launch.
- Keyboard navigation, native menus and grouped touch-preset selectors.
- A short first-run guide through the Accessibility permission.
- Automatic updates through Sparkle: a daily check (can be turned off) plus **Check for Updates…**; each update is signature-checked and installed only after you confirm.
- Menu bar icon with a paused state and the last action error; optional Dock icon; launch at login; emergency pause with ⌃⌥⇧⌘ Escape.
- A support report with versions, permission status and counts, without any binding content.
- English, Russian, German, French, Spanish and Simplified Chinese.

### Known limits

- Signed by the maintainer but not notarized: macOS asks you to confirm the first launch.
- Trackpad and Magic Mouse touch support uses a private macOS interface and is experimental. Overlapping macOS gestures may also respond.
- No Caps Lock or Fn/Globe remapping, modifier-only triggers, left/right modifier distinction, physical-device rule routing, touch swipes, pinch or rotation.
- Wheel settings and wheel bindings are separate from trackpad/Magic Mouse scrolling. Available device settings and battery readings depend on the model/connection.
- Minimum target macOS 26; observed runtime evidence is on Apple silicon with macOS 27. Minimum-version and Intel execution remain unverified.
- Accessibility-grant preservation across distinct same-signer updates and full VoiceOver/preferences coverage remain separate release checks.
