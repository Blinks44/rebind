# INPUT-013: Trackpad taps, false clicks and stale devices after user review

- Updated: 2026-10-16 (false-click fix)
- Stage: awaiting_verification
- Owner: Unassigned (code agent session released)
- Owned surfaces: `ShortContactRecognizer`, `TrackpadTapSession`, `TrackpadClickFilter`, `EngineMailbox.handle`, `MouseHardware` removal/battery publication, `tools/trackpad-click-probe.swift` and their tests.
- Requirements: SPEC §§3.4, 4 (trackpad presets), Devices/battery; PLAN Phase 5.
- Code baseline: `main` `da415e4`; uncommitted on top (INPUT-012 probe work from another session is also uncommitted and untouched).

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

- [ ] User: on a fresh build, two/three/four-finger double taps and the three-finger single tap on both trackpads (Smart Zoom off for two fingers).
- [x] User ran the probe on both trackpads (2026-10-16); discriminator implemented.
- [ ] User: with three/four-finger click rules, resting fingers no longer trigger them, and quick presses still do, on both trackpads.
- [ ] User: disconnect a Magic Trackpad/Mouse (batteries out) and confirm it leaves Devices and the battery menu within seconds.

## Next handoff

User: on a fresh build, check the open boxes above. Code agent: if Magic Trackpad presses after a longer rest must run the rule, look for a force source for that device (for example its HID force reports) before loosening the 400 ms bound.
