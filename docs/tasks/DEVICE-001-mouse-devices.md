# DEVICE-001: Devices settings, Logitech wheel and pointer speed, companion-app warnings

- Updated: 2026-10-15
- Stage: awaiting_verification
- Owner: Unassigned; released 2026-10-15 by the implementation session
- Ownership checked: 2026-10-15, uncommitted work on `main` after `f10ed48`; released
- Owned surfaces: `apps/rebind/rebind/Devices/`, `Packages/HIDPP`, `UI/DevicesView.swift` (was `DevicesSettingsView`), sidebar Devices row, Mouse page banner, `Engine/ScrollEventAdapter.swift`, configuration schema 35
- Requirements: SPEC §3.2 (mouse hardware settings, companion apps), §10 Settings; schema 35
- Code baseline: `main` at `f10ed48`, all changes uncommitted (the user commits)

## Outcome and scope

- Settings has a **Devices** tab (between Input and Language) listing connected mice. A supported Logitech HID++ 2.0 mouse shows only the rows it reports: Scroll wheel (SmartShift / Always click / Always free spin), SmartShift sensitivity (SmartShift mode only) and Pointer speed (DPI from the mouse's own list). Other mice get a compact "No extra settings" card; with no supported mouse the empty state is shown.
- Values are stored per model (`vendor:name`) in the configuration and written to the mouse whenever it is found: at launch, on (re)connection of a direct Bluetooth/USB device, when Devices opens and when a companion app quits.
- Companion apps (Logi Options+, Logitech G HUB) are detected from the running process list. One shared banner and one text for every app (user decision 2026-10-15): "<App> is running" ("… are running" for several) / "It can take over mouse buttons and settings. If something doesn't work, turn it off or uninstall it." The Mouse page shows it whenever a companion app runs for a connected mouse's vendor; Devices shows it only for an app that rewrites these settings (Options+), which also disables the controls (no Quit button: it relaunches itself, confirmed by the user). Both are listed in the support report together with the connected mice.
- Mouse wheel reverse/speed and wheel triggers now also apply to continuous high-resolution wheels without a gesture phase (user report: no effect on an MX Master 2S without Logitech software). Trackpad and Magic Mouse scrolling always carry a scroll or momentum phase and stay untouched.
- Wheel root cause, in two steps. (1) The adapter accepted only stepped events; the MX Master 2S scrolls continuously without a phase, so diagnostics showed "Unsupported". (2) After that fix diagnostics showed "Wheel up/down" but scrolling was still not reversed: a hardware scroll CGEvent carries the HID event it came from, and AppKit reads precise (continuous) deltas from that attached event, so rewriting only the CGEvent fields changes nothing for a high-resolution wheel. Synthetic test events have no attached event, which is why the unit tests passed. `Engine/AttachedHIDScroll.swift` now scales the attached values too, through the private `CGEventCopyIOHIDEvent` / `IOHIDEventGet/SetFloatValue` (as LinearMouse does), looked up once with `dlsym`; without the symbols only the CGEvent fields change. Diagnostics show "Passed on, changed" when the tap reverses or speeds up a wheel event, so a remaining problem can be told apart from paused rules.

Out of scope, by decision: the **gesture button and thumb wheel** (REPROG_CONTROLS_V4 diversion). Sketch removed the row from the Devices card and renamed frame 43 "43 · Future · Mouse · Gesture button trigger"; no code or strings for it exist. Diverted controls arrive as HID++ notifications on the report thread, not through the Quartz tap, so they need a second input source feeding the synchronous matcher, new trigger kinds with movement gestures and click-on-release semantics, re-diversion on every reconnect and guaranteed undiversion on pause, crash and quit. That is a separate engine task with hardware checks, not a settings slice.

## Acceptance

- [x] Devices tab, cards, rows only for reported features, empty state, shared companion banner (Mouse page; Devices only for Options+, with disabled controls).
- [x] SmartShift 0x2110/0x2111 and DPI read/write; stored settings re-applied when a mouse is found; Bolt/Unifying receiver slots 1–6 probed.
- [x] Strings in EN/RU/DE/FR/ES/zh-Hans.
- [x] Unit tests: companion matching, schema 35 validation/migration, SmartShift/DPI payloads with a mock device; package tests for SmartShift and DEVICE_NAME.
- [x] User report 2026-10-15 (Debug build): the MX Master 2S on the Unifying receiver is listed and switching SmartShift off works.
- [x] User report 2026-10-15, Debug build of the attached-event fix: all ten checklist items work on the MX Master 2S over Unifying: Devices listing and rows, SmartShift modes, sensitivity, DPI, persistence after relaunch and reconnect, wheel reverse/speed with "Passed on, changed" in diagnostics, trackpad unaffected, G HUB banner, empty state, Light/Dark.
- [ ] Options+ banner and disabled controls with Options+ installed (uninstalled on the test Mac); Bluetooth-direct and Bolt mice; MX Master 3/3S (0x2111).

## Sketch source

Rebind.sketch, page "01 · Screens", frames 39–43 Light/Dark ("Settings · Devices", "… Options+ running", "… Empty", "Main · Mouse · Options+ running", "Main · Mouse · Logitech controls"), inspected through MCP on 2026-10-15. Re-read 2026-10-15 after the design update: banner text matches the code, the Devices card has no gesture-button row, frame 43 is marked Future. Frame 40's banner has no Quit button (user decision).

## Implementation and verification

- `Packages/HIDPP`: LinearMouse's MIT module vendored at `843d9a0` with its LICENSE; additions listed in its README. Linked to the app as a local Swift package.
- `Devices/HIDReportDevice.swift`: public-IOKit adapter. Opens without seizing, input reports on a dedicated run-loop thread, requests on one serial queue waiting on a semaphore, so neither the main thread nor the event tap ever blocks.
- `Devices/LogitechMouse.swift`, `Devices/MouseHardware.swift`: discovery through IOHIDManager (mice without a digitizer usage, plus Logitech vendor interfaces), HID++ probe (direct, else receiver slots), apply and read-back.
- User report 2026-10-15: with G HUB at its defaults (side buttons sent as Buttons 4/5) Rebind bindings work alongside it; the user still wants the Mouse page to say that G HUB may take buttons, so it gets the shared banner but never locks Devices.
- `Devices/CompanionApp.swift`: verified identifiers only (`com.logi.optionsplus` + `logioptionsplus_agent`; `com.logi.ghub`, `com.logi.ghub.agent` read from the installed G HUB). Razer, SteelSeries and the old Logitech Options are not listed until verified.
- Limits: mice behind a receiver are re-probed when Devices opens, at launch or receiver replug, not when they wake. Receivers report a wake only after their notification register is rewritten (LinearMouse does this with ownership/restore logic outside the vendored module); not adopted, and the mouse keeps DPI and SmartShift itself. Identical models share settings. Opening a device whose interfaces include a keyboard may need Input Monitoring; without it the mouse shows "No extra settings". G HUB does not lock Devices, so a G-series mouse in G HUB can have its DPI replaced by G HUB's profile.
- 2026-10-15, agent-observed: a read-only probe built from the same sources found "Wireless Mouse MX Master 2S" on Unifying receiver `c52b` slot 1 (SmartShift 0x2110, threshold 16; DPI 1000, list 200–4000 by 50) in 0.29 s; empty slots failed in 0.01–0.17 s through the 0x8F handling. Nothing was written to the mouse.
- Review 2026-10-15 of the whole diff: a slider could keep a stale draft, a missed reply could collapse a card to "No extra settings", a location-prefix lookup could match a different device, a comment promised wake re-apply, disabled segmented controls did not dim. All fixed; choices now show at once and the mouse's answer replaces them.
- `./scripts/dev.sh build` and `./scripts/dev.sh test`: pass (762 Swift Testing tests and 15 XCTest layout tests). `swift test` in `Packages/HIDPP`: 26 tests pass. The app was not run.

## Next handoff

Implementation: the user walks the checklist in the final report (Devices on the MX Master 2S, persistence, banner, wheel reverse/speed with "Passed on, changed" in diagnostics, trackpad unaffected, Light/Dark). If the wheel is still not reversed while diagnostics say "changed", the attached-event path needs a closer look on that machine. Gesture button/thumb wheel: a separate engine task when the user asks for it.
