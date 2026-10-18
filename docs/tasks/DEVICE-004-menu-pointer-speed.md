# DEVICE-004: Pointer speed in the Menu Bar menu

- Updated: 2026-10-18
- Stage: awaiting_verification
- Owner: Unassigned; implementation session released 2026-10-17
- Requirements: SPEC §3.2 (mouse hardware settings, Menu Bar menu); user request 2026-10-16 to change mouse DPI from the Menu Bar menu

## Outcome and acceptance

- [x] Sketch: pair **53 · Menu bar · Pointer speed** (Light/Dark) saved 2026-10-16. A "Pointer speed" section follows Battery: per mouse, the device symbol, its (local) name and the current value ("3200 DPI") right-aligned, then the shared `Slider` component under the name.
- [x] `MenuBarController`: one custom-view menu item per connected mouse that reports DPI (`LogitechDeviceState.dpi` with `supportedDPI`); no section when none does. It is independent of the Battery-in-menu setting.
- [x] The slider steps through the mouse's own list (same values as Settings → Devices), updates the label while dragging and writes/saves once on release through the existing `MouseHardwareSettings.dpi` path; both surfaces show the same value. Disabled while storage is locked or a companion app owns the mouse settings.
- [x] Copy reuses `devicesPointerSpeed` and `devicesDPIValue` (all six languages exist); the slider's accessibility label is the device name plus "Pointer speed", its value the localized DPI.
- [ ] Spoken VoiceOver, keyboard reach inside the menu and six-language widths in the running app.
- [ ] Native check on MX Master 2S: drag/release, reopen menu, Settings agreement, keyboard/VoiceOver.

## Implementation

- `MenuPointerSpeedView` (AppKit, in an `NSMenuItem.view`, like the system Sound menu): symbol, local name, monospaced-digit value and an `NSSlider` over list indices without tick marks. Drag updates the label and commits once on release; keyboard/scroll changes commit at once.
- 2026-10-18, user report (blue once with a focus ring on the thumb, gray on every later opening): a menu window never becomes key, and AppKit then draws the fill gray and ignores `trackFillColor`; the one blue opening was the slider becoming first responder. Reproduced in a non-key panel. `AccentSliderCell` draws the system bar and overlays the filled part in the accent color while enabled (matches a key-window slider), and the slider refuses first responder, like other menu content. A disabled slider names the companion app ([DEVICE-005](DEVICE-005-companion-dpi-reconnect.md)). Keyboard adjustment inside the menu is not offered; VoiceOver adjusts it through accessibility.
- `MenuBarController.pointerSpeedItems` adds the section after Battery and saves through `AppModel.setMouseHardware`, which writes the mouse on the existing HID++ queue. No storage, engine or HID changes.

## Verification

- 2026-10-17: `dev.sh test`: 841 Swift Testing tests in 130 suites + 17 native tests pass, including 3 new `MenuPointerSpeedTests` (nearest-value start, snap + single commit, disabled state).
- Not yet run: the menu in the running app (the installed Rebind was running, so the debug build was not launched alongside it).

Next step: with the installed Rebind quit, run the debug build and check drag/release on MX Master 2S, Settings agreement, Light/Dark against Sketch pair 53, keyboard and VoiceOver.
