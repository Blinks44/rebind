# Phase 2 long-press verification — 2026-10-08

Scope: SPEC §§2, 3.1–3.2, 4, 6, 9; Phase 2 source hold recognition.
Status: implemented and software-tested; **configured G603 long-press output and delay user-verified after fixes**.
The first attempt failed; the subsequent retest succeeded. Full hardware safety and timing checks remain open.
The user's ordinary G603 Control + Button 4 → Command+A result does not verify this mode.

## Contract

- Ordinary physical keys and middle/extra mouse buttons, exact four primary modifiers.
  Category-wide scope; no physical device attribution. Wheel cannot use long press.
- One shortcut pulse after holding for a per-rule 100–5000 ms threshold (default 500).
  Output keys are never held. No repeated action or delayed single-press fallback.
- Source down is consumed immediately; a short press is consumed without output/replay.
  Source up stays owned even after cancellation, editing or pause until capture loss.
- Keyboard autorepeat is consumed without canceling recognition or emitting extra output.
  Duplicate non-repeat down, changed modifiers/Fn, another captured down, unrelated dragging,
  scrolling (also smooth/momentum/diagonal), editing/recording/configuration changes,
  pause, emergency bypass, queue saturation, Secure Input and capture loss cancel.
- One constant-size pending candidate. Another matched hold cancels the previous candidate
  and can start its own; already consumed releases remain owned. Tagged Rebind feedback
  does not cancel recognition. Movement delivered as a drag of the held source mouse
  button preserves the original deadline; no directional gesture is recognized.
  Losing Rebind UI focus cancels explicit recording only, leaving background recognition active.
- Native worker polls between CF run-loop iterations (nominally 20 ms while active).
  No callback timer, task, output, UI or I/O. A worker more than 100 ms late at the
  threshold cancels rather than dispatching a stale action. This is a safety bound,
  not a measured latency/performance guarantee.
- Holds use receipt and polling from the same Dispatch uptime clock. Double-press/wheel
  timing keeps original Quartz timestamps. PrivacyInfo.xcprivacy declares timer/elapsed
  time reason 35F9.1, no tracking/data collection. No timestamps are persisted or sent.
- Normal, double and long press for the same enabled chord conflict, including with
  button-direction rules. Current schema 5 migrates schemas 1–4 in memory; stable IDs,
  output, activation and enabled state survive.
  Old thresholds default to 500; malformed/out-of-range durations and legacy hold modes
  are rejected without overwriting data. Saving is atomic.

## Verified

- After the correction, the user reports “Да, все сочетания работают, задержка тоже”
  in response to the requested TextEdit retest. Existing configuration: G603 Button 5,
  no modifiers, Long press 1000 ms → Command+A; Control + Button 4 ordinary shortcut.
  Device context: LIGHTSPEED with G HUB installed. This is user-performed verification
  of the configured output and perceived delay; the agent did not generate these inputs.
  No numeric timing measurement or separate results for short press, motion variants,
  one-shot delivery, suppression, cancellation, keyboard or lifecycle were supplied.

- Follow-up `scripts/dev.sh test -resultBundlePath build/Phase2HoldFixTests.xcresult`:
  **100 tests / 16 suites / 0 failures**. Five additional test functions cover repeated
  owned mouse drags without deadline reset or repeat delivery, changed flags during a
  drag, the user's exact two-rule configuration (Button 5, no modifiers, 1000 ms),
  and focus loss both with and without an explicit recorder. No tap or posting is run.

- `scripts/dev.sh test -resultBundlePath build/Phase2HoldTests-Verified.xcresult`:
  **95 tests / 15 suites / 0 failures**, including 22 new hold/mailbox/persistence cases.
  Threshold boundary, once-only firing, short release, repeat, drag, modifiers, queue,
  editing/recording/pause, secure/capture reset, independent clock origins,
  stale/regressed/extreme times, invalid/conflicting data and literal schema-3
  migration/byte preservation are covered. Tests never start a tap or post events.
- Final Debug and universal Release build; strict/deep signature check passes.
  Release privacy manifest is packaged and passes plutil lint. These do not prove
  Intel/macOS 26 runtime or hardware behavior; host was previously inventoried as
  Apple Silicon macOS 27.0.1, Xcode 27.0 / Swift 6.4 / SDK 27.
- Native Russian editor: mode selection, 500→600 ms stepper, full cancellation hint,
  wheel hides modes/duration, Escape cancellation. Three-mode picker initially wrapped
  its label poorly; the final screenshot shows its label above full-width segments.
- The user's existing ordinary Control + Button 4 → physical A shortcut is visible
  intact after new-schema loading (A/Ф label follows current keyboard layout).
  The agent did not save/delete/change the user's configuration or grant permission.
- During the initial UI check, the new locally signed bundle showed AX/post access
  unavailable after rebuilding and needed user authorization for hardware checks.
  Subsequent user screenshots show the engine active; the latest retest succeeds.
  Do not treat an unavailable grant on a different local build as a failed remap.

Logs: `/tmp/rebind-hold-{tests-verified,build-final,release-final}.log`;
result: `build/Phase2HoldTests-Verified.xcresult` (ignored).
Expected AppIntents metadata-skip warning and hosted system autoShortcut diagnostics;
no Swift/concurrency warnings. EN/DE/FR layouts and VoiceOver are not manually verified.

## User-assisted physical walkthrough

Use G603 LIGHTSPEED with the currently installed G HUB and a disposable TextEdit document.

1. Completely quit/relaunch the final Debug Rebind.app; confirm actual AX and event-post
   access. Keep its path/signing stable during the walkthrough; refresh/relaunch if asked.
2. In All mice, make Button 5 → Command+A, Long press, 500 ms. Record a normal press
   to identify the source; select the activation mode separately. Use a new chord or edit
   an existing rule; an enabled normal/double rule for the same chord conflicts.
3. Short press/release: no Select All. Hold past threshold: one Select All while still
   holding. Clear selection with another input, continue holding: no second output.
4. Release and hold again: one new output. Try thresholds 100/1000/5000 ms; confirm
   actual timing and behavior with the mouse's real event stream. Repeat on a physical
   keyboard: its autorepeat must not cancel the long press or emit repeated shortcuts.
5. Before threshold, move with the same button held: expect one output at the original
   threshold. Change modifiers, press another key/button or scroll: expect cancellation
   and safe source release. Also try smooth/diagonal wheel paths.
6. Pause, edit, close/open the window, sleep/wake, revoke/restore permissions and
   enable Secure Input during the pending hold. Verify no stale output or stuck input.
   Device disconnect and missed release must be tested; no hardware claim is made.
7. Check ordinary/double/wheel regressions, keyboard navigation and VoiceOver, all
   languages, save/relaunch persistence and the unchanged ordinary G603 rule.

Button-hold pointer direction is implemented separately; [hardware verification remains pending](phase-2-pointer-gesture.md).
Held synthetic output, repeating actions, primary button
mapping, special keys, per-device rules and multitouch are separate unfinished work.

## Failed G603 attempt and correction

- User screenshot: engine active, enabled Control + Button 4 ordinary rule and
  Button 5 long press → Command+A, no modifiers, 1000 ms. Read-only inspection of
  saved schema-4 metadata confirms that configuration; no user rules were edited.
- Identified two independently reproducible implementation problems: every owned
  `otherMouseDragged` canceled a mouse hold, and `didResignActive` called
  `mailbox.record(nil)` even with no active recorder, clearing temporal recognition.
  Corrected both. These explain possible cancellation paths; the failed hardware
  attempt has no captured event trace, so its exact cause is not established.
- Apple documents `otherMouseDragged` as motion with an auxiliary button held:
  [CGEventType.otherMouseDragged](https://developer.apple.com/documentation/coregraphics/cgeventtype/othermousedragged).
  Rechecked current LinearMouse configuration/recorder and release notes (MIT, native
  macOS; release 0.12.0 adds long press). Existing native worker remains sufficient;
  no runtime package, private API, vendor driver or copied third-party code.
- Follow-up build logs: `/tmp/rebind-hold-fix-{tests,build,release}.log`;
  result `build/Phase2HoldFixTests.xcresult`. Debug and universal Release succeed.
  Remaining warning is expected AppIntents extraction skip; hosted tests also emit
  system autoShortcut service diagnostics, with no Swift/concurrency warnings.
- Subsequent user retest confirms the configured combinations and delay work. Remaining
  checks: separate stationary/motion results, short press, one-shot/release, cancellation,
  keyboard and lifecycle. Exact cause of the first failure remains unconfirmed without
  an event trace; successful retest does not isolate which correction resolved it.
