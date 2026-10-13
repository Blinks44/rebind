# Phase 2 button-hold pointer gestures: 2026-10-08

Scope: SPEC §§2, 3.2, 4, 6, 9; Phase 2 button-hold + direction recognition.
Status: implemented, software-tested and Russian editor inspected. **Configured G603 leftward gesture happy path user-verified; broader hardware checks pending.**
The earlier user-confirmed G603 ordinary/long-press results do not verify this feature.

## Contract

- Middle/extra numeric Quartz buttons (index ≥2), category-wide All mice scope,
  exact Command/Control/Option/Shift. No physical device attribution or fixed maximum.
- Record the physical source button/modifiers; select a direction separately. Four
  direction rules can share a chord. Duplicate directions or any enabled ordinary,
  double/long-press rule on that chord conflict. Primary buttons remain unmappable.
- Product decision, 2026-10-08: left/right/up/down are the complete mouse pointer
  gesture set. Diagonals, circles/spirals and multi-stroke figures are out of scope;
  separate multitouch requirements are unchanged.
- Capture matched source down immediately. A short click or incomplete gesture is
  consumed, with no replay or delayed click fallback. Unmatched presses pass through.
- Accumulate relative integer `mouseEventDeltaX/Y`, rather than absolute cursor position.
  Net movement must reach 50 Quartz delta units on its dominant axis; that axis must
  be at least twice the perpendicular axis. This is not a calibrated physical distance
  or logical-point guarantee. DPI, acceleration and driver transformations affect sensitivity.
  Negative X is left, positive X right, negative Y up, positive Y down; hardware validation pending.
- One action at the first qualifying stroke, while the source is still down. Ambiguous
  diagonals or an unconfigured first substantial direction cancel, without choosing
  another outcome later. No per-frame repeats, direction sequences or held synthetic output.
- Gesture movement is consumed until source release, cancellation or five seconds from
  source down. The existing worker polls expiry even without more input. A missed up
  therefore cannot leave the pointer motion stream suppressed indefinitely. Source up
  remains owned after cancellation; capture loss clears all ownership. Full missing-up,
  disconnect and OS cursor behavior still need physical checks.
- Other key/button downs, duplicate source down, changed modifiers/Fn, unrelated dragging,
  scroll (including unsupported smooth/momentum), editing/recording/configuration changes,
  pause, queue denial, regressed time, missing deltas and extreme deltas cancel. Rebind's
  tagged feedback is ignored. Secure Input/suspension/stop/capture loss clear acquisition.
- Single constant-size gesture session. Another gesture source cannot take it over while
  its source is still owned; simultaneous mouse-button chords are not implemented.
- Support both `otherMouseDragged` and a driver-delivered `mouseMoved` stream. Subscribe
  to high-frequency `mouseMoved` only when enabled compiled gesture rules require it;
  otherwise keep the ordinary tap mask. Idle movement passes through unchanged.
  Mask changes happen on the worker; failed recreation clears pending output/acquisition.
- No Tasks, actor hops, output, UI, file I/O or logging inside the tap callback. Existing
  16-entry queue and tagged balanced shortcut sender remain. No new permission or helper.
- Schema 5 migrates schemas 1–4 in memory without rewriting the file until a successful
  atomic save. Stable IDs, output, enabled state, activation and hold durations survive.
  Legacy files disguising gestures, malformed directions, invalid scopes/buttons/modes,
  conflicts and future schemas are rejected without overwriting valid data.

## Verified in software and UI

- `apps/rebind/scripts/dev.sh doctor`: Xcode 27.0, Swift 6.4, SDK 27.0; Apple Silicon macOS 27.0.1
  (26A434). Deployment remains macOS 26, strict Swift 6, default MainActor for UI.
- `apps/rebind/scripts/dev.sh test -resultBundlePath build/Phase2PointerGestureTests-Final.xcresult`:
  **131 tests / 20 suites / 0 failures**, 31 added test functions across matcher/mailbox,
  relative-field adapter/tap-mask policy and persistence. All prior 100 tests pass.
  Covers four directions, threshold/dominance/timeout boundaries, noise/net reversal,
  one-shot/rearming, modifier isolation, diagonal/wrong-direction cancellation, pause,
  queue saturation, recording, secure reset including no active gesture, ownership,
  extreme numeric inputs, schema-4 literal byte preservation and rule-family conflicts.
  Tests construct but never post Quartz events or start a tap; temporary stores only.
- `apps/rebind/scripts/dev.sh build` and `apps/rebind/scripts/dev.sh release`: **BUILD SUCCEEDED**. Release
  contains arm64/x86_64, strict/deep signature verification and packaged privacy-manifest
  lint pass. No Intel/macOS 26 execution claim. Expected AppIntents metadata-skip warning
  and hosted system autoShortcut diagnostics; no Swift/concurrency warnings.
- Native Russian Debug editor: mouse input menu includes Button + movement, hides press
  modes, exposes all four directions, keyboard Tab/Space opens the direction menu, Up
  selection updates, complete instructions fit, Escape cancels. Existing Control +
  Button 4 and Button 5 / 1000 ms rows remain intact. No user rule was saved/changed.
  Other languages/VoiceOver/appearance checks remain pending.
- The inspected ad-hoc Debug copy lacks AX/post permission after rebuilding; user action
  is required for that copy or the rebuilt Xcode copy before hardware testing. No TCC
  reset or agent-granted permissions. Multiple local copies share the bundle ID;
  do not run two active engines during the walkthrough.

Logs: `/tmp/rebind-pointer-{doctor,tests-final,build-final,release-final}.log`;
result `build/Phase2PointerGestureTests-Final.xcresult` (ignored). No dependency installed.

## User-reported hardware result: 2026-10-08

Manual test report, 2026-10-08: **Option + Button 4 + move Left → Command+A**
worked in TextEdit. Evidence source: tester report, not agent-observed input. The device was previously
identified as Logitech G603 over LIGHTSPEED with G HUB installed. This confirms
the requested configured happy path, not physical device attribution or all gesture
directions. No separate cursor, suppression, one-shot/release, timing, cancellation,
timeout/disconnect or lifecycle result was supplied; those checks remain open.

## Physical walkthrough (leftward happy path confirmed; remaining checks pending)

Use G603 LIGHTSPEED with G HUB and a disposable TextEdit document.

1. Quit existing Rebind copies; rebuild/run from Xcode (⌘R). Confirm actual AX/post access
   and engine active. Keep that path stable during checks; rebuilds may invalidate ad-hoc trust.
2. Keep the working Control + Button 4 ordinary and Button 5 hold rules. Add **Option +
   Button 4**, input **Button + movement**, direction **Left**, output **Command+A**.
   Record the source while holding Option, then choose direction; save normally.
3. Hold Option and Button 4, move clearly left within five seconds. Expect Select All once,
   no original button click/drag. Release and repeat. Check cursor behavior and screen edges.
4. Add Right/Up/Down on the same chord with harmless distinct shortcuts and check axes.
   Try slow/fast motion and different DPI/acceleration without changing G HUB assignments.
5. Check jitter/short click/no movement, diagonal and an unconfigured direction. No action
   or click fallback should occur. Check modifier transitions, another key/button, scroll,
   pause, editor, global focus/background/window closure, sleep/wake and permission loss.
6. Hold beyond five seconds or disconnect: pointer must not remain trapped; no stale action.
   Verify source release ownership and safe recovery. Repeat ordinary/long-press, wheel
   and double-press regression walkthroughs; test two mice without claiming source attribution.

Native system actions, adjustable gesture thresholds, primary-button mappings, mouse-button
chords, per-device routing and multitouch remain separate unfinished work.
