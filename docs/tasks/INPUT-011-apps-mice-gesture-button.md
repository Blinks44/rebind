# INPUT-011: Rules for one app, per-mouse smooth scrolling, Logitech gesture button, battery and wheel, settings backups

- Updated: 2026-10-15
- Stage: awaiting_verification
- Owner: Unassigned; released 2026-10-15 by the implementation session
- Ownership checked: 2026-10-15, uncommitted work on `main` after `4aff48c` (builds on [INPUT-010](INPUT-010-smooth-scrolling.md) and [DEVICE-001](DEVICE-001-mouse-devices.md)); released
- Owned surfaces: `Model/Binding.swift` (`application`), `Engine/EngineMailbox.swift` (rule sets per app, smooth scrolling per sender, off-tap buttons), `Engine/AttachedHIDScroll.swift` (sender ID), `Devices/*`, `Packages/HIDPP` (Battery, ReprogControls), `UI/DevicesSettingsView.swift`, `UI/InputSettingsView.swift`, `UI/RuleApplicationField.swift`, `Persistence/ConfigurationStore.swift` (daily copies), configuration schema 39
- Requirements: SPEC §2 (rules for one app), §3.2; AGENTS boundary updated by user request 2026-10-15

## Outcome and scope

User request 2026-10-15 (items 1–4, 6, 7, 8 of the gap review, plus extras):

- **Rules for one app**: the editor has an App field (All apps / Choose App…). A rule for one app works only while it is in front and replaces a rule for all apps with the same trigger there. The mailbox compiles one effective rule set per app with rules of its own and swaps it on app switches (queued work is cancelled, swallowed presses keep their release); matching itself is unchanged. Validation checks each app's effective set. The row caption names the app and search finds it.
- **Smooth scrolling per mouse** (moved from Input to each mouse card in Devices, every mouse, Logitech or not): toggle, distance slider (default 60 points per line, the default on its own line under the description) and glide. A wheel event names the HID service that sent it (`IOHIDEventGetSenderID` of the attached HID event); `MouseHardware` maps each mouse's IOKit device and the services below it to its settings and publishes them to the mailbox. Mice behind one receiver share its services. "Applies to" was removed: the user chooses per mouse. The global setting of schemas 36–38 is not carried over (it could not say which mouse it meant).
- **Reverse horizontal scrolling** is its own switch in Input; older files keep both directions as they were.
- **Logitech**: battery charge on the card (0x1004 or 0x1000, warning colour at 15 % or less), High-resolution wheel switch (0x2121), Gesture button switch (0x1B04 diversion of control 0x00C3). A diverted gesture button reaches Rebind as HID++ notifications on the report thread and enters the matcher as mouse button 1000 ("Gesture button"), so press, hold, double press and the four directions ("Gesture button + left") work as for any button; there is no click to give back. Rebind diverts it on every probe (launch, reconnect, Devices, receiver 0x41 connection notice) and undiverts it on quit; a crash leaves it diverted until the mouse reconnects. The thumb wheel stays native horizontal scrolling.
- **Hideable trackpad warning** (×, `hidesTrackpadGestureWarning`). The Permissions "Input Monitoring · Not required" card stays: it explains what is not needed and when Automation is asked.
- **Settings backups**: at each successful launch the configuration is copied to `Backups/configuration-YYYY-MM-DD.json`, newest 7 days kept; Advanced → Show Backups opens the folder, and Import restores any copy. The full export already includes every setting (rules, exclusions with switches, device and wheel settings).
- **Lost settings report** (2026-10-15): the configuration found afterwards was valid, recently written and marked as fresh (setup flag unset); the store never deletes or overwrites a file it cannot read, so the cause stays unknown (the user was asked what disappeared). The daily copies make such a loss recoverable.

## Acceptance

- [x] Code, strings in six languages, unit tests (778 Swift Testing + 15 layout; HIDPP package 29).
- [ ] Hardware: gesture button press, hold and four directions on the MX Master 2S; diversion restored after the mouse sleeps/reconnects and given back after quit; battery value; high-resolution wheel on/off changes the wheel; smooth scrolling on one mouse and not on another at the same time; horizontal reverse with the tilt/thumb wheel.
- [ ] Rules for one app: a Chrome-only rule on Button 4 replaces the general rule in Chrome only; switching apps while holding a button.
- [ ] Running-app review against new Sketch frames (pending design).

## Sketch source

Not drawn yet: Devices card with battery, high-resolution wheel, gesture button and per-mouse smooth scrolling (replaces the smooth block of frame 44 and the empty-state copy of 41), Input mouse wheel card with two reverse switches and the pointer to Devices, the binding editor App field and the "In <app>" row caption, × on the trackpad banner, Advanced Show Backups. Frame 43 (gesture button trigger) is now implemented.

## Next handoff

Design: draw the surfaces above in Light/Dark. Implementation: the user's hardware checklist; then decide on Magic Mouse presets from the probe output.
