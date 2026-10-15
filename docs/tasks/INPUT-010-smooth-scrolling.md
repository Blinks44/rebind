# INPUT-010: Smooth scrolling, per-app exclusion toggles, hideable companion warning, Input cleanup

- Updated: 2026-10-15
- Stage: awaiting_verification
- Owner: Unassigned; released 2026-10-15 by the implementation session
- Ownership checked: 2026-10-15; first slice committed by the user as `4aff48c` (with [DEVICE-001](DEVICE-001-mouse-devices.md)), follow-up below uncommitted; released
- Owned surfaces: `Engine/SmoothScroller.swift`, `Engine/PointerApplicationTracker.swift`, `Engine/EventTapWorker.swift` wheel branch, `Model/ExcludedApplication.swift`, `Model/SmoothScrolling.swift`, `UI/InputSettingsView.swift`, `UI/ExcludedApplicationsCard.swift`, `Banner` close button, Menu Bar window opening, configuration schemas 36–38, shared `UI/SettingSlider.swift`
- Requirements: SPEC §3.2 (wheel), §10 Settings; schema 36

## Outcome and scope

- **Smooth scrolling** (Settings → Input → Mouse wheel): each wheel click becomes a short glide of continuous scroll events. Glide Short / Standard / Long (ease-out time constants 50 / 90 / 150 ms, about 95 % of the distance after three); "Applies to" Wheels with clicks (default; high-resolution wheels already scroll smoothly) or All mouse wheels. Off by default.
- Order in the tap: the binding matcher sees the original click first (a wheel binding fires and the click is swallowed); then reverse/speed; then an unmodified, phase-less mouse wheel click is swallowed and its distance added to the glide. Command, Control and Shift clicks pass through untouched (zoom, modified wheel actions, horizontal Shift scrolling). Trackpad and Magic Mouse scrolling (phased) is never touched. A click the other way stops the glide. The tap removal (pause, permissions, failure) cancels a glide.
- **Excluded apps**: each app has two switches, "Bindings" and "Smooth scrolling" (on = keeps working in that app). Bindings covers bindings, gestures and wheel direction/speed. New apps start with both off. Schema 35 exclusions migrate as bindings off, smooth scrolling on (nothing changes for them).
- **Companion warning on the Mouse page** can be hidden with ×; hidden apps are remembered (`dismissedCompanionApps`), and a companion app not hidden before shows it again. The Devices banner (Options+, controls disabled) is not hideable. No reset control: there is no natural place for it in Advanced.
- **Input tab cleanup**: removed the "Keys and buttons · In each binding" and "Built-in trackpad · Experimental" information cards and the footer about the sidebar (text only, no control, repeated elsewhere); the header now reads "Input / How Rebind recognizes presses, movement and taps." as in Sketch. Eight strings deleted.

## Follow-up 2026-10-15 (user feedback on `4aff48c`)

- **Distance per click**: the glide used the 10 points a stepped click reports, while apps scroll a line much further, so pages needed many clicks. A stepped click now glides its accelerated lines (fixed-point delta, after reverse/speed) × the distance; a continuous wheel keeps its own points, scaled so the default matches it. First three presets (schema 37), then by user request a slider of 20–400 points per line in steps of 10, default 120 (schema 38; a schema 37 preset becomes 40 / 80 / 140). The Devices slider became the shared `SettingSlider`.
- **Exclusions follow the pointer**: a scroll goes to the window under the pointer, not to the app in front (Chrome in front, PhpStorm under the pointer still glided). `PointerApplicationTracker` reads the window list on a utility queue ten times a second, only while smooth scrolling is on and some app turns it off, and publishes the app under the pointer to the mailbox; the tap reads it under the usual lock. Without it the app in front decides. Bindings exclusions still follow the app in front (keys go there).
- **Menu Bar windows**: opening Rebind or Settings sometimes did nothing the first time or put the window into the Stage Manager strip. The policy switch and activation happened in the same run-loop turn as the menu closing; an activation requested then can be dropped and the window appears while Rebind is inactive. `showWindow` now activates and opens one turn later and brings the opened window to the front a turn after that.
- 769 tests + 15 layout tests pass; none of these three is checked in the running app yet.

## Acceptance

- [x] Smooth scrolling engine and settings; exclusion toggles; hideable warning; Input cleanup; strings in six languages.
- [x] Tests: ease-out step and direction change, which events glide (stepped/all, modifiers, phases), mailbox gating per app and when paused, schema 35 → 36 migration, warning dismissal persistence.
- [ ] Hardware feel on stepped and high-resolution wheels for each glide length; a wheel binding still fires once per click; Cmd/Ctrl zoom and Shift horizontal scrolling unchanged; trackpad untouched; per-app toggles in a real app switch.
- [ ] Running-app review against Sketch 42 (×), 44 and 45 in Light/Dark.

## Sketch source

Rebind.sketch, page "01 · Screens": "42 · Main · Mouse · Options+ running" (× on the banner), "44 · Settings · Input · Smooth scrolling", "45 · Settings · Input · Excluded apps", Light and Dark, inspected through MCP on 2026-10-15. Frame 44 has no "Distance per click" slider row yet (in code above Glide: title, "How far one wheel click scrolls (default 120 pt).", value "120 pt", same style as the Devices sliders). Frames 13, 31 and 36 still show the removed Input information cards and the old wheel copy; the design side updates them.

## Implementation and verification

- `SmoothScroller`: approach from LinearMouse's smoothed scrolling (MIT; credited in ThirdPartyNotices and README), with a plain exponential ease-out instead of its velocity/momentum model. The tap only adds distance under a short Mutex; a dedicated thread posts tagged pixel events at 120 Hz while distance remains and blocks on a semaphore otherwise. Tagged events pass the tap untouched, so a glide is never matched or adjusted twice.
- Noise review of the rest of the app, proposed only (debatable, not removed): Permissions "Input Monitoring · Not required" card (explains a permission users may see requested elsewhere; mouse hardware access may need it); General "To stop Rebind completely…" footer; the always-shown Trackpad "macOS may respond too" banner (could become hideable like the companion warning). The menu bar menu and diagnostics have nothing redundant.
- `./scripts/dev.sh test`: 767 Swift Testing tests and 15 XCTest layout tests pass. The app was not run for this change.

## Next handoff

Implementation: the user walks the checklist (smooth scrolling feel per glide, bindings on the wheel, modifiers, trackpad, per-app toggles, × on the warning, Light/Dark). Design: update frames 13/31/36 to the cleaned Input tab and decide on the proposed items.
