# INPUT-011: Rules for one app, per-mouse smooth scrolling, Logitech gesture button, battery and wheel, settings backups

- Updated: 2026-10-19 (manual evidence reconciliation; original software runs unchanged)
- Stage: awaiting_verification
- Owner: Unassigned; released 2026-10-15 by the implementation session
- Ownership checked: 2026-10-15, uncommitted work on `main` after `4aff48c` (builds on [INPUT-010](INPUT-010-smooth-scrolling.md) and [DEVICE-001](DEVICE-001-mouse-devices.md)); released
- Owned surfaces: `Model/Binding.swift` (`application`), `Engine/EngineMailbox.swift` (rule sets per app, smooth scrolling per sender, off-tap buttons), `Engine/AttachedHIDScroll.swift` (sender ID), `Devices/*`, `Packages/HIDPP` (Battery, ReprogControls), `UI/DevicesSettingsView.swift`, `UI/InputSettingsView.swift`, `UI/RuleApplicationField.swift`, `Persistence/ConfigurationStore.swift` (daily copies), configuration schema 39
- Requirements: SPEC §2 (rules for one app), §3.2; AGENTS boundary updated by user request 2026-10-15

## Outcome and scope

User request 2026-10-15 (items 1–4, 6, 7, 8 of the gap review, plus extras):

- **Rules for one app**: the editor has an App field (All apps / Choose App…). A rule for one app works only while it is in front and replaces a rule for all apps with the same trigger there. The mailbox compiles one effective rule set per app with rules of its own and swaps it on app switches (queued work is cancelled, swallowed presses keep their release); matching itself is unchanged. Validation checks each app's effective set. The row caption names the app and search finds it.
- **Smooth scrolling per mouse** (moved from Input to each mouse card in Devices, every mouse, Logitech or not): toggle, distance slider (default 50 points per line, subsequent user choice; the default on its own line under the description) and glide. A wheel event names the HID service that sent it (`IOHIDEventGetSenderID` of the attached HID event); `MouseHardware` maps each mouse's IOKit device and the services below it to its settings and publishes them to the mailbox. Mice behind one receiver share its services. "Applies to" was removed: the user chooses per mouse. The global setting of schemas 36–38 is not carried over (it could not say which mouse it meant).
- **Reverse horizontal scrolling** is its own switch in Input; older files keep both directions as they were.
- **Logitech**: battery charge on the card (0x1004 or 0x1000, warning colour at 15 % or less), High-resolution wheel switch (0x2121), Gesture button switch (0x1B04 diversion of control 0x00C3). A diverted gesture button reaches Rebind as HID++ notifications on the report thread and enters the matcher as mouse button 1000 ("Gesture button"), so press, hold, double press and the four directions ("Gesture button + left") work as for any button; there is no click to give back. Rebind diverts it on every probe (launch, reconnect, Devices, receiver 0x41 connection notice) and undiverts it on quit; a crash leaves it diverted until the mouse reconnects. The thumb wheel stays native horizontal scrolling.
- **Hideable trackpad warning** (×, `hidesTrackpadGestureWarning`). The Permissions "Input Monitoring · Not required" card stays: it explains what is not needed and when Automation is asked.
- **Settings backups**: at each successful launch the configuration is copied to `Backups/configuration-YYYY-MM-DD.json`, newest 7 days kept; Advanced → Show Backups opens the folder, and Import restores any copy. The full export already includes every setting (rules, exclusions with switches, device and wheel settings).
- **Lost settings report** (2026-10-15): the configuration found afterwards was valid, recently written and marked as fresh (setup flag unset); the store never deletes or overwrites a file it cannot read, so the cause stays unknown (the user was asked what disappeared). The daily copies make such a loss recoverable.

## Follow-up 2026-10-15 evening (user report on `1401d30`)

- **Settings loss, explained as far as possible**: an older build reported "could not read" a file a newer build had written (protective lock, nothing lost); the user then twice started from defaults after replacing the app. No code path deletes or overwrites a configuration, no cleaner app is installed, and Accessibility stayed granted. Cause still unknown; the daily copies (now present) make it recoverable.
- **Default distance 50 pt** (user choice).
- **Sliders** no longer draw a tick per value (a 12,000 DPI sensor drew a solid comb); they snap to the accepted values.
- **Dock icon**: Rebind now handles reopen itself: it becomes a regular app, activates, and de-miniaturizes or fronts the existing window (SwiftUI opens one if none). Before, with Show in Dock off, a window opened while Rebind was still an accessory app stayed inactive and looked minimized, and further clicks did nothing.
- **Quit hang and slow DPI**: one HID++ queue serves all devices, and a probe of a silent slot asked every feature with a 1 s timeout each, so changes and the quit-time gesture-button release waited behind it. A device now must answer the first question or is skipped; quitting waits at most 1.5 s and only releases mice whose button Rebind diverted.
- **G603 DPI fighting G HUB**: gaming mice have onboard profiles (0x8100). While G HUB runs it manages them, so Rebind no longer writes their hardware settings and shows the shared banner in Devices for them. Without G HUB, writing a DPI first switches the mouse to host mode (as G HUB and Solaar do), otherwise its onboard profile restores its own DPI; in host mode the mouse's DPI button no longer cycles its onboard levels.
- **Battery in the Menu Bar menu** (General → "Battery in menu", schema 40, on by default; stored under the key `showsBatteryInMenuBar`): first drawn next to the icon, then, at the user's request, moved into the menu as a native "Battery" section: one item per device with its kind symbol and the percentage as the item's badge (⚡︎ while charging); clicking opens Settings → Devices. The status item shows only the Rebind icon again. Sources: Logitech HID++ mice and keyboards (keyboards are now probed for their battery only and never listed as mice; G915 TKL expected to work, unverified) and devices macOS reports through `AppleDeviceManagementHIDEventService` `BatteryPercent` (Magic devices; charging not shown, the flag is undocumented). Refreshed every 5 minutes and on every probe.
- **Stage Manager action**: not added. macOS has no public API or shortcut that reveals the Stage Manager strip; turning Stage Manager on or off is possible with the Shortcuts action "Set Stage Manager", which Rebind can already run ("Run Shortcut").
- 780 tests + 15 layout tests and 30 package tests pass; nothing run in the app.

## Follow-up 2026-10-15 night (user report after archiving a build)

Agent-observed on the user's Mac (read-only HID++ probes, no writes): G603 on Lightspeed receiver `c539` slot 1 (onboard profiles, host mode, DPI 1450, battery 90 %); G915 TKL on `c545` slot 1 (keyboard; battery only through BATTERY_VOLTAGE 0x1001, ≈49 %; first answer after 0.9 s when waking, none in deep sleep); a G435 headset with a Logitech vendor interface; both receivers already had wireless notifications on.

- **"App started clean"**: the configuration on disk was intact and loaded in the current code (temporary test against the real file: schema 40, 4 rules). The window always opened on Keyboard, where the user has no rules (all four are mouse gestures), and setup was never acknowledged, so it can show the first-run sheet. The window now reopens on the last input category shown. Backups were per day, so a launch with unexpected contents replaced the good copy of that day: now a copy per change (timestamped, identical contents skipped), newest 10 kept.
- **Dock**: implementing reopen in the delegate (previous follow-up) stopped SwiftUI's own handler, and SwiftUI never opens a window suppressed at launch, so a Dock click after a background start showed only the dot. The delegate now opens the window itself with the scene's `openWindow`, handed over by the Menu Bar icon (alive from launch; checked with a standalone SwiftUI app: the label's `onAppear` runs and `openWindow` opens a suppressed `Window`) and by the main window. With neither a Dock nor a Menu Bar icon, the window is no longer suppressed at launch.
- **G915 battery**: added BATTERY_VOLTAGE (0x1001) and ADC_MEASUREMENT (0x1F20) with an approximate Li-ion curve (LinearMouse maps 3.5–4.2 V linearly; Solaar's GPL table not used). The first question allows 2.5 s for a waking device; keyboards are asked only for their battery. A device that sleeps keeps its last battery reading and its card until it answers again.
- **G603 DPI delays**: one queue served every HID++ endpoint, and the headset was probed as a receiver (7 × 1 s). Now each endpoint has its own queue, only mice, keyboards and their receivers are opened, a silent endpoint is not asked for receiver slots, and receivers get wireless notifications turned on (HID++ 1.0 register 0x00, as Logitech software and Solaar do) so a device that reconnects is set again. With G HUB closed, DPI changes go to the G603 in host mode without waiting behind other devices.
- DPI writes are read back and retried once (host mode first on onboard-profile mice); a reconnect notice applies them again. The G HUB updater (`com.logi.ghub.updater`, a root process that runs without G HUB) never counts as G HUB; G HUB's app or agent does, and while either runs Rebind writes no hardware settings to gaming mice.
- 781 tests + 15 layout tests and 32 package tests pass; nothing run in the app.

## Acceptance

[October 18 checklist, received October 19](../verification/manual-test-2026-10-18.md): item 2.5 confirms responsive MX Master 2S gesture-button hold; 2.6 confirms background-window smooth-scrolling exclusion and preserved onset. Its introduction summarizes earlier per-app, gesture, battery and Bluetooth checks without variant/build details. Keep the detailed lifecycle/model matrix below open; no new build/test run.

- [x] Code, strings in six languages, unit tests (778 Swift Testing + 15 layout; HIDPP package 29).
- [x] MX Master 2S gesture-button hold: checklist 2.5.
- [ ] Remaining hardware: gesture button press and four directions on the MX Master 2S; diversion restored after the mouse sleeps/reconnects and given back after quit; battery value; high-resolution wheel on/off changes the wheel; smooth scrolling on one mouse and not on another at the same time; horizontal reverse with the tilt/thumb wheel.
- [ ] Dock icon after closing the window (Show in Dock on and off); Quit from the Menu Bar is immediate; G603 DPI with and without G HUB; battery in the Menu Bar for the MX Master 2S, G915 TKL and Magic devices.
- [ ] Rules for one app: a Chrome-only rule on Button 4 replaces the general rule in Chrome only; switching apps while holding a button.
- [ ] Running-app review against the current saved Sketch frames.

## Sketch source

The current live source includes per-mouse Devices controls, Input's two reverse switches/Devices pointer, the editor App field, exclusions and Advanced backups. [REVIEW-001](REVIEW-001-production-review.md) reconciled the newer inventory/naming/Bluetooth states, archived obsolete global smoothing, and saved all screens as 52 numbered Light/Dark pairs. [DESIGN](../DESIGN.md) locates the source; inspect it live during native comparison. Hardware acceptance remains open.

## Next handoff

Runtime: complete gesture press/directions, reconnect/quit diversion and remaining multi-mouse/per-app/battery checks; retain the confirmed hold/background-exclusion subset. Magic Mouse now has an experimental one/two-finger app testing pool in INPUT-014. Design: add its missing populated/editor/recovery states to the current source.
