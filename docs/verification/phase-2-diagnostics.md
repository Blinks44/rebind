# Phase 2 input diagnostics: 2026-10-08

Scope: SPEC §§6, 9, 12; Phase 2 safe event metadata viewer.
Status: implemented, software-tested, Russian native UI inspected and basic G603
side-button collection user-verified. **Remaining physical safety/performance checks
remain open.**

## Contract


- Open **Input Diagnostics** at the bottom of the main window, then explicitly start
  a 60-second session. Opening alone never starts collection. Observation continues
  when another app has focus, so TextEdit can receive the configured output.
- Mouse buttons (unbounded UInt32 code), press/release/drag, discrete wheel direction,
  generic unsupported scroll, primary modifiers/Fn flag, elapsed milliseconds and
  engine decision only. Code CG is the zero-based Quartz code; human Button 4 means 3.
  Drag metadata is associated with the held gesture source, not a physical-device ID.
- **No keyboard events or key codes**, characters, absolute pointer coordinates,
  trajectories/deltas, CGEvent objects, output shortcuts/parameters, process/window
  identity or device attribution. Rebind-tagged feedback is ignored. A vendor button
  converted into a keyboard event is intentionally absent from this viewer.
- “Passed through”/“Consumed” reports the tap's source-event decision. “Queued” means
  accepted for dispatch, not successful injection or effect in another app. Delayed
  mouse-hold activation has a separate queued row with **source** modifiers. Keyboard
  holds are excluded. Rule behavior is not changed by log quota/overflow/clear/stop.
- Standard-library `InlineArray<128, InputDiagnostic?>` provides fixed inline storage.
  Constant-time overwrite retains the newest 128 entries; no dynamic callback array
  growth/COW or string formatting. At most 20 accepted entries per one-second window;
  overflow is counted, never accumulated for later delivery. Snapshot arrays are
  copied only for a changed revision on the existing main-actor refresh timer.
- After 60 seconds collection stops even without another input; rows remain for
  inspection. A regressed clock stops/erases the session. Clear erases rows/counters
  without extending the deadline or resetting the current quota; Start begins fresh.
- Close sheet/Escape or a Rebind window, sleep/session suspension, Secure Input,
  permission/capture loss, tap/output failure, termination and emergency bypass
  stop/erase collection. Returning to an ordinary context never restarts it silently.
  UI refresh propagates backend clearing; no disk storage/export/telemetry/console log.
- Diagnostic-only demand can keep the existing tap installed while rules are paused,
  without enabling rules or executing output. Start is an explicit tap retry, still
  gated by actual current permission checks and runtime failures. No second tap,
  monitor, helper or new permission. Diagnostic-only mode does not subscribe to idle
  pointer motion; existing gesture rules retain their conditional subscription.
- Primary mouse ups are included in the existing mask for down/up metadata symmetry;
  primary mapping remains unsupported and unmatched releases pass through. Unsupported
  scroll keeps passthrough/cancellation behavior and checks protected state before logging.
- UI is translated EN/RU/DE/FR, with native Table, explicit Start/Stop/Clear/Close and
  collection/engine statuses. Full Advanced Settings integration remains later work.

## Verification

- `apps/rebind/scripts/dev.sh doctor`: Xcode 27.0 (27A266a), Swift 6.4, SDK 27.0,
  Apple Silicon macOS 27.0.1 (26A434), deployment 26 unchanged.
- `apps/rebind/scripts/dev.sh test -resultBundlePath build/Phase2DiagnosticsTests.xcresult`:
  **159 tests / 24 suites / 0 failures**, 16 new functions covering opt-in/stop/clear,
  chronological ring overflow, burst limits, idle expiry, clock regression/extremes,
  keyboard/tag/receipt exclusion, independent snapshots, paused passthrough, unchanged
  output/release behavior under throttling, source hold modifiers, unsupported scroll,
  protected-context/failure reset, emergency bypass and revision-based snapshots.
  All prior 143 tests retained. No real tap, global posting or user storage in tests.
- Russian native panel inspected on the exact Debug bundle: all six columns/full
  hints/limits fit, empty state/status visible, Start disabled without actual grants,
  Escape closes. Existing three mouse rows preserved, no user binding/enabled state
  changed. Populated table, real Start/Stop/expiry, other locale layouts, VoiceOver
  and high-polling performance remain pending.
- Before any new UI actions, the previous Xcode copy showed rules paused and an
  interrupted-tap status. Cause not established; this is an observation, not evidence
  that diagnostics caused a fault. Its current saved leftward gesture is Button 4
  without modifiers; Option in the earlier walkthrough was a recommended test chord,
  not independent evidence of the current saved configuration.
- Quit that previous copy normally, checked process absence, inspected the new Debug
  copy, then quit the inspection copy for user Xcode testing. No two active engines,
  rules saved/toggled, TCC reset or permission granted by the agent. The new ad-hoc
  inspection copy lacked AX/post access; the user's stable Xcode copy needs its own
  actual permission check. Earlier user-confirmed remaps do not verify this viewer.

Build/signature/catalog results are recorded in [the historical evidence summary](../history/implementation-through-2026-10-10.md). Logs
`/tmp/rebind-diagnostics-{doctor,tests,build-final,release-final}.log`;
result `build/Phase2DiagnosticsTests.xcresult` (ignored).

## User hardware result: 2026-10-08

Manual test report, 2026-10-08: diagnostics collection succeeded. A supplied
panel screenshot records the previously reported G603 LIGHTSPEED/G HUB setup. It shows Button 4 → CG 3 and
Button 5 → CG 4, down/up pairs and Button 5 drag rows. Collection is active around
31–33 seconds; rules are paused and the displayed decisions are passed through.
This verifies basic collection and populated Russian table metadata. It does not
establish physical-device attribution from Quartz events.

The omitted counter reads 609. It counts rate-limit exclusions and ring overwrites;
the screenshot does not distinguish them or establish hardware event loss or
performance. Middle-button CG 2, active-rule output, expiry and explicit/protected
clearing are not shown and remain physical checks. Software/build evidence above
is unchanged; this confirmation required documentation changes only.

## Remaining physical checks

1. Run a single rebuilt Xcode copy (⌘R), confirm its actual permissions, keep the
   existing rules. With rules paused, verify middle Button 3 shows CG 2 down/up with
   normal passthrough and no queued output. Side Buttons 4/5 → CG 3/4 and their
   passed-through decisions are already visible in the user screenshot.
2. Enable working rules and check ordinary/hold/leftward gesture in disposable TextEdit
   with the panel open in the background. Check queue versus source consumption,
   source modifier labels, no duplicate output and no keyboard/feedback rows.
3. Check wheel and smooth/diagonal scroll; unsupported rows must still pass through.
   Test a driver-converted keyboard button separately; absence is expected by policy.
4. Stop (rows retained), Clear, restart, wait 60 seconds without input (collection stops),
   and close/Escape/reopen (empty/off). Confirm sleep, protected input and permission
   loss erase data and require explicit restart. Never supply password text.
5. Under rapid clicks/motion/wheel, omitted count may rise; no delayed log burst or
   changed remapping. High polling-rate performance, missing-up/device disconnect and
   other lifecycle/fault checks remain separate physical gates.
