# DEVICE-005: G HUB coexistence, faster DPI on reconnect, tap recovery

- Updated: 2026-10-19
- Stage: awaiting_verification
- Owner: Unassigned; implementation session released 2026-10-18
- Requirements: SPEC §3.2 (mouse hardware settings, companion apps), §6 (event-tap timeouts); user report 2026-10-18 (G HUB and Rebind switch DPI back and forth; after G HUB quits or the mouse reconnects it stays at an unknown DPI for 5–15 s; menu slider sometimes gray)

## Findings

- **Companion detection missed background helpers.** `CompanionAppMonitor` read only `NSWorkspace.runningApplications`. G HUB's `lghub_system_tray` and `lghub_agent` (and the Options+ agent) are started by launchd, not Launch Services, so they never appear there; checked 2026-10-18 with the running `lghub_updater`, which `ps` lists and `runningApplications` does not. With the G HUB window closed Rebind wrote host mode/DPI to the gaming mouse while G HUB's agent rewrote its own (per-app profiles, reconnects): the reported back-and-forth. Quitting the agent sent no change, so the stored DPI was not rewritten until a reconnect or Devices refresh.
- **Stored settings waited for the whole probe.** Measured on the user's Lightspeed receivers (read-only, 2026-10-18): an idle gaming mouse answers each HID++ request in ~82 ms and needs ~0.9 s to wake; empty slots answer at once (0x8F). A probe asked every slot and every feature, enumerated all reprogrammable controls (one request each) and read the state twice before the DPI write, roughly 3–4 s after wake, longer with a busy queue or concurrent G HUB traffic.
- **Menu slider gray.** The slider is disabled (gray, as is the name) while G HUB owns a gaming mouse; with the window-only detection that state flipped as the G HUB window opened and closed, without any explanation in the menu.
- **Tap timeout latched.** A single `tapDisabledByTimeout` (system load, wake) paused all rules until the user pressed Resume; Karabiner-Elements, Hammerspoon and LinearMouse re-enable the tap.

## Changes

- `CompanionAppMonitor` scans all processes (`proc_listallpids`/`proc_pidpath`), names each by its enclosing bundle (cached), every 2 s and on Launch Services changes. Matching rules and the G HUB updater exclusion are unchanged. macOS offers no public launch notification for launchd-started processes; the scan of ~800 paths is cheap.
- `LogitechDevice` reads its name once, defers the control enumeration until first needed, and `apply` writes pointer speed (host mode + DPI) before SmartShift/wheel/gesture. `MouseHardware.probe` applies each mouse's stored settings as soon as that slot is found (no second read), and a receiver's connection notice asks that slot first.
- The menu slider shows "<App> is running" in place of the value (and as accessibility help) while a companion app owns the mouse; existing six-language copy is reused.
- `EventTapWorker` re-enables a tap macOS disabled, at most three times a minute, after resetting capture state (held outputs released); beyond that the failure latches as before.

## Verification

- 2026-10-18: `dev.sh test`: 846 Swift Testing tests in 131 suites + 17 native tests pass, including new checks for bundle naming of launchd helpers, the process scan, slot order, DPI-first write order, the companion note in the menu and the recovery budget.
- [x] Tester checklist 1.1–1.2: background G HUB is detected, slider disabled with the note, DPI oscillation stops; tray Quit restores Rebind DPI and slider in approximately two seconds. This observes behavior, not individual HID writes.
- [x] Tester checklist 1.3: reconnect/wake DPI check marked passed with G HUB absent; no elapsed seconds or distinction between power-cycle and sleep supplied.
- [ ] Options+ agent detection on a machine with Options+.
- [x] Tester checklist 1.4: enabled slider stays blue without the thumb focus ring on reopening; drag and Devices agree. Separate Light/Dark coverage not specified.
- [ ] Separate Light/Dark and accessibility review of the menu; see DEVICE-004.
- [ ] Hardware event-tap timeout/recovery, including held-output release and the retry-budget fallback.

Evidence: [October 18 checklist, recorded October 19](../verification/manual-test-2026-10-18.md). Exact build/mouse/OS were not supplied; no tests rerun for this documentation update. Stage remains `awaiting_verification` for the checks above.

Next step: verify Options+ background detection and event-tap recovery on an identified current build; do not repeat the passed G HUB happy path unless affected code changes.
