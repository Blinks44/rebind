# INPUT-013: Trackpad taps, false clicks and stale devices after user review

- Updated: 2026-10-19
- Stage: awaiting_verification
- Owner: Unassigned (code session released; hardware acceptance open)
- Owned surfaces: `ShortContactRecognizer`, `TrackpadTapSession`, `TrackpadClickFilter`, `EngineMailbox.handle`, `MouseHardware` removal/battery publication, `tools/trackpad-click-probe.swift` and their tests.
- Follow-up surfaces (2026-10-18): `EventTapWorker`, `InputEvent`, `TrackpadCapture`, `TrackpadClickFilter`, `TrackpadTapClickReplacementTests`, `AnchoredMenu`, `MenuSelector`, `ProfilePicker`, `BindingsView`; affected evidence.
- Requirements: SPEC §§3.4, 4 (trackpad presets), Devices/battery; PLAN Phase 5.
- Code baseline: `main` `772c704`; clean tree at startup. Current follow-up owns the tap/click regression and associated tests/evidence.

## Outcome and scope

User review on the built-in trackpad and a Magic Trackpad (macOS 27.0.1; Tap to click, three-finger drag and Smart Zoom on) reported:

1. Three-finger tap did nothing (built-in).
2. Double tap with 2, 3 and 4 fingers did nothing on either trackpad (2 fingers also zoomed).
3. Three/four-finger click rules ran about 500 ms after fingers merely rested on the surface.
4. A Magic Trackpad with its batteries removed stayed in Devices and the battery list for 10+ minutes.

## Causes and changes

- **Double taps (all counts).** The device stops sending frames shortly after every finger lifts, so the second tap of a pair always starts after skipped frame IDs. The recognizer bridged such gaps only when no pair was pending, so every second tap was treated as frame loss and the pair was cancelled. Synthetic tests always fed consecutive IDs between taps. A forward gap after an observed release is now idle silence in every state; gaps inside a stroke, backwards IDs and non-monotonic time still cancel, and the pair deadline still bounds the wait.
- **Taps cancelled by their own click.** With Tap to click, macOS turns a two-finger tap into a secondary click after the lift (and, with three-finger drag, a three-finger tap into a click). That click advanced input activity like a physical press and cancelled the tap. `TrackpadClickFilter` now remembers any short contact; a button press within 350 ms of its release while no finger touches either surface is a `tapClick`: it passes on unchanged but is not input activity. A press while a finger touches either surface stays physical activity. The corner-tap replacement is unchanged.
- **Smart Zoom.** A two-finger double tap still also zooms when Smart Zoom is on; Rebind cannot suppress native gestures ([research](../research/native-gesture-suppression.md)). The editor already says to turn Smart Zoom off.
- **False 3/4-finger clicks (not fixed yet).** Three-finger drag makes macOS post a button press from resting fingers; contact count alone cannot tell it from a physical press. No discriminator is chosen without hardware data (SPEC: contact count or pressure alone does not prove a click). Added `apps/rebind/tools/trackpad-click-probe.swift`, which prints each button/pressure event with its CGEvent fields (pressure, subtype, stage, source) beside the contact count, hold time and per-contact force-like values.
- **Stale devices.** Removal recomputed the device's location from properties of a device that is going away; it now looks the device up where it was filed on arrival. macOS's own battery services (Magic devices) are now observed through IOKit match/terminate notifications, so their rows are republished when they appear or go away instead of up to five minutes later. The root cause of the reported 10-minute case was not observed directly (no live trace; the user declined screen access to the running app).

## Verification

Agent-observed 2026-10-16, macOS 27.0.1, Xcode 27.1, working tree: `dev.sh build` passes; `dev.sh test` passes **835 Swift Testing tests in 129 suites** plus the 17 native XCTest tests. New/changed tests: idle silence between taps keeps 2/3/4-finger pairs and the pending single; idle gap after a release keeps a waiting action (a repeated frame ID still cancels); a click made from a three-finger tap (either button) passes without cancelling the rule; a press with a finger on either surface right after a tap is still activity. The probe type-checks with `swiftc -typecheck`; it was not run. No hardware check by the agent.

## Follow-up evidence: 2026-10-16

- First probe run (user): resting three fingers produced a `leftMouseDown` with pressure 1 and subtype Touch even with Rebind off, confirming the synthetic press. The probe then crashed: `NSEvent.stage` raises for button events. Fixed to read `stage` only for pressure events and print the NSEvent subtype instead; type-checked, not run by the agent.
- User saw "trackpad-182 50 %" in the battery menu after disconnecting. Agent check a little later: macOS itself listed the trackpad as Bluetooth **Connected**, with an active `BNBTrackpadDevice` reporting `BatteryPercent` 49, so the row matched the system state at that moment; Rebind was not running then. Whether the trackpad had reconnected (Apple input devices reconnect on touch) is unknown. Periodic polling was not added: removal is event-driven and a poll would mask a real missed event.

- Battery list: user confirms a device leaves the battery list once it is fully disconnected.
- Second probe run (user, Magic Trackpad only): resting three/four fingers and physical three/four-finger presses produce identical `leftMouseDown` events (pressure 1, subtype 3, source 1, no pressure events). Resting presses are released when the fingers lift; physical ones 50–150 ms later with fingers still down, so release timing alone separates them only after the fact. A two-finger tap produced right-down/up with no contact and a three-finger tap left-down/up with no contact, confirming the tap-click path. The per-contact value at offset 52 read 0.00 on this device. [trackpad-runner](https://github.com/madebyjun/trackpad-runner) (no license; read, not copied) reads that field as `MTFinger.pressure` and reports resting 0–35 versus click peaks 100–130 on a built-in Force Touch trackpad; `MTRegisterButtonStateCallback` is reported silent on Force Touch hardware. The probe now prints `MTDeviceSupportsForce`, current/peak pressure, density and contact states for both trackpads.

- Third probe run (user, both trackpads): `MTDeviceSupportsForce` is yes for the built-in trackpad and **no** for the Magic Trackpad, whose contact pressure stays 0. Built-in: resting three fingers reached force 33 (peak 59) when macOS pressed; physical presses 271 (three fingers), 185 (four), 129 (one). Magic Trackpad: macOS pressed for resting three fingers after 538 ms (earlier run 495 ms) and released on lift; physical presses came 105–136 ms after landing (earlier 104–291 ms).

## False-click fix

`TrackpadClickFilter` runs a three/four-finger click rule only for a deliberate press: on a Force Touch surface the strongest finger force at the press must be ≥ 90; on a surface without force the fingers must have landed (observed from neutral) less than 400 ms before the press and stayed within 0.04 of where they landed. Otherwise the press passes on unchanged (and still counts as input activity). Two-finger secondary clicks are unchanged. `NativeTrackpadDevice` reads the optional `MTDeviceSupportsForce` once per adapter; the per-frame code uses fixed slots, no arrays. Limitation: on a Magic Trackpad a physical press made after fingers rested ≥ 400 ms, or after they slid, stays an ordinary click. Thresholds come from one built-in trackpad and one Magic Trackpad.

Verification: new tests cover force 59 versus 129, a quick still press versus macOS's 538 ms press, a slid press and an unobserved landing; `dev.sh test` passes **838 Swift Testing tests in 129 suites**. Not checked on hardware after the change.

## Open checks

- [October 18 checklist, received October 19](../verification/manual-test-2026-10-18.md), items 3.1–3.4: built-in three-finger single/double, two-finger double, physical three-finger click replacement and ordinary gestures are user-confirmed. Exact revision/settings and a separate resting-finger/dragging trial breakdown were not supplied. Look Up's checklist wording permits a visible conflict; native suppression is not established. The tested artifact is not identified, so these passes do not establish regression acceptance of the shared-adapter correction.

- 2026-10-19 follow-up after shared-adapter correction: user confirms Magic Trackpad three/four-finger singles work. The three-finger ~500 ms delay disappeared after disabling the matching double rule, confirming the existing arbitration wait; see [INPUT-014](INPUT-014-magic-mouse-integration.md#magic-trackpad-discovery-regression--2026-10-19). Double/reconnect and measured timing acceptance remain open.

- [ ] On the corrected current bundle: built-in regression and Magic Trackpad double taps, plus four-finger double delivery on both surfaces. Earlier built-in two/three-finger passes and later external singles are recorded separately above.
- [x] User ran the probe on both trackpads (2026-10-16); discriminator implemented.
- [ ] User: with three/four-finger click rules, resting fingers no longer trigger them, and quick presses still do, on both trackpads.
- [ ] User: disconnect a Magic Trackpad/Mouse (batteries out) and confirm it leaves Devices and the battery menu within seconds.

## Next handoff

**Current handoff:** [INPUT-014](INPUT-014-magic-mouse-integration.md#magic-trackpad-discovery-regression--2026-10-19) corrected repeated discovery restarting the arming gate; subsequent external three/four-finger singles are user-confirmed. Next check external doubles/reconnect, first taps after idle, and the built-in regression on that corrected artifact. Retain normal-click/dragging/false-positive checks and profile-popup alignment. The dated built-in passes above are not tied to the corrected bundle. Use aggregate `--diagnose-trackpad` reasons for remaining failures; standalone probes do not replace app acceptance.

## Three-finger native clicks and selector alignment — 2026-10-18

User reports delayed/missed three-finger single/double taps and primary clicks instead; four-finger taps work well. The precise running artifact, current surface and system settings were not restated, so this is a regression report, not a measured latency/accuracy result.

The former fix deliberately passed the primary click made by three-finger drag through. A completed stationary three-finger stroke now replaces that primary click only for the public Touch event subtype, an enabled matching single/double rule on that category with the exact modifiers, known release and no finger on either surface. Its bounded fixed-slot checks mirror the recognizer's per-finger movement/identity, placement/lift, two peak frames, duration and continuity requirements; Force Touch click-level force excludes replacement. Capture arming (three seconds), rule revision and input activity must still match. A new capture resets attribution before starting the observer; already consumed releases remain owned. Non-Touch clicks, physical presses during contact, moved/uncertain/stale strokes and inactive rules retain passthrough. An ordinary non-Touch press after a recent lift now also cancels pending tap output, rather than being mistaken for a native tap-made click. No general gesture cancellation or physical-device attribution is claimed; mixed simultaneous touch devices remain a hardware gate.

Timing contract is unchanged: a single with no matching double rule is ready after the independent **60 ms** click check. If both rules exist, the single waits the system double-click interval (commonly **500 ms**); a recognized pair is ready 60 ms after its second release. No arbitrary shortened interval or early single action was introduced. Native Look Up/Zoom and drag-clicks arising while fingers remain down are still coexistence limits; do not infer their cancellation from the after-release replacement.

The profile selector used SwiftUI Menu's placement, unlike the existing explicit NSMenu selectors. `AnchoredMenu` now shares the latter's content-frame anchoring, native tracking and keyboard-focus restoration between profile selection and other selectors; the profile button's geometry/text/icon are preserved. Profile changes still save transactionally; the management command remains separate. Sketch MCP is unavailable, so this is a placement-mechanics correction, with no visual redesign or parity claim.

Agent verification, macOS 27.0.1 / Xcode 27.1, baseline `772c704` plus this uncommitted change:

- `dev.sh build` passed; targeted `dev.sh test` rebuilt the changed app and passed **94 Swift Testing tests in seven suites**: tap-click replacement, corner taps, click rules, single taps, doubles, scheduling and short contacts. New cases cover both categories, the single's 60 ms bound, double/native-click pairs without a leaked single, non-Touch passthrough, movement, frame gaps, four-finger exclusion, force, stale revision/activity, editing, new contact, exact modifiers, arming and release ownership after pause.
- Two native `MainWindowLayoutTests` pass: `testKeyboardScreensRenderAtSketchSize` and `testPermissionNoticeDoesNotExpandNavigationBeyondTheWindow` (72 size/language/permission/rule combinations in the latter). These use isolated models and never start capture/load real rules.
- A temporary standalone AppKit menu fixture reports the popup window and 196 pt trigger at the same screen x (**0 pt** difference). This checks NSMenu placement away from screen edges, not every actual app menu/appearance/VoiceOver state. Fixture/logs stay outside Git.
- The first unrestricted run stopped progressing in `AboutLayoutTests.testFindCanReopenWithoutEditingOrResettingSelection`; a process sample showed XCTest blocked in issue symbolication, and the run was interrupted (Xcode cleanup exited 75). The unchanged full rerun on 2026-10-18 at 23:06–23:10 completed successfully: **858 Swift Testing tests in 133 suites + 17 native XCTest tests, zero failures**, `dev.sh test` exit 0 / `TEST SUCCEEDED`. About Find passed in 0.790 seconds; total test operation took 270.559 seconds. Evidence: local `apps/rebind/build/DerivedData/Logs/Test/Test-rebind-2026.10.18_23-06-02-+0300.xcresult`. AppKit emitted non-fatal QoS/window-count warnings; the earlier stall's cause is not established by the successful retry. No source/test changes were needed for the rerun. No hardware remapping, settings/grant change, commit or Sketch edit was performed.

Research refresh: Apple's public NSMenu positioning contract supports the shared anchor; the installed AppKit SDK names `NSEvent.EventSubtype.touch`, matching the earlier probe's subtype 3. BetterTouchTool's [developer discussion](https://community.folivora.ai/t/please-help-cant-assign-middle-click-to-three-finger-tap/18692) describes a separate three-finger-drag compatibility mode; [current release notes](https://updates.folivora.ai/bettertouchtool_release_notes.html) also acknowledge macOS 27 drag changes. Neither establishes BTT's private implementation. The earlier [library audit](../research/touch-library-audit.md) remains the reuse decision; refreshed GitHub README/SPI searches did not establish a drop-in replacement. One pinned Subsurface source-page fetch failed. No third-party source copied or dependency added.

Final review: source-event ownership and bounded callbacks reviewed; the related 94-test run and subsequent unchanged full 858 + 17 test rerun pass after the non-Touch activity guard. `git diff --check` passes; affected local document links reviewed. Required physical checks remain open, so the task stays `awaiting_verification`.
