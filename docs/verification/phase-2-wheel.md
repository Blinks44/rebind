# Phase 2 — Discrete wheel → shortcut

Status: implemented; pure behavior and constructed Quartz-event tests pass.
**Physical capture, recording, suppression and recipient delivery are unverified.**
Phase 1's end-to-end exit criterion remains open; see its
[keyboard/button walkthrough](phase-1.md).

## Implemented contract

- All-mice category scope, up/down/left/right, exact Command/Control/Option/Shift
  set (including none) → an ordinary output shortcut pulse.
- Only delivered discrete, single-axis line events are eligible. Continuous,
  nonzero scroll-phase/momentum-phase, third-axis, zero-delta and diagonal
  events pass through. Fn-flagged and unmatched modifiers pass through.
- Direction means the delivered Quartz direction: positive axis 1 is up,
  positive axis 2 is left. Natural scrolling and OEM/other utilities may change
  the delivered direction. Record with the intended settings and re-record
  after changing them. This does not identify a physical mouse; another utility
  can convert trackpad or smooth input to an eligible discrete event.
- The first matched event dispatches immediately. At most one output pulse is
  queued per 100 ms, shared across wheel directions and modifier rules.
  Intermediate matching events are suppressed without output. Line magnitude
  does not multiply actions; there is no accumulation, delayed catch-up or
  persistent pressed state. Keyboard/button mappings use their existing policy.
- Queue overflow, pause, editing, suspension, Secure Input, tagged feedback and
  regressed timestamps pass through. Configuration changes, recording
  start/cancel, suspension and capture loss reset the limiter and discard pending
  output. Shortcut construction/delivery limits from Phase 1 still apply.
- Explicit **Scroll Wheel** recording captures one eligible event, consumes
  that event and never executes an action. Button and output recorders ignore
  wheel input. Escape cancels; switching mouse-input type cancels and clears the
  source while retaining the output. Missing permissions disable recording.
- Wheel rules were introduced in schema 2; current schema 5 preserves them as
  ordinary-press mappings. Schema 1/2/3/4 rules migrate in memory with
  their IDs, enabled state, modifiers and output unchanged. Loading does not
  rewrite disk; a successful save writes schema 5 atomically. Unknown/corrupt
  versions remain protected from editing/overwrite.

## Verification performed — 2026-10-08

Host: Apple Silicon, macOS 27.0.1 (26A434), Xcode 27.0, Swift 6.4, SDK 27.0;
deployment minimum remains macOS 26. No macOS 26 or Intel execution claim.

- `apps/rebind/scripts/dev.sh test -resultBundlePath build/Phase2WheelTests-Final.xcresult`:
  **47 tests in 8 suites passed**, including 23 new tests for direction/metadata,
  unsupported event passthrough, throttle boundaries/bursts/alternating axes,
  timestamp overflow/regression, exact modifiers, recording, queue bounds,
  pause/Secure Input/suspension/editing, old-format migration and wheel round trip.
  Events were constructed, never globally posted; hosted tests do not start a tap.
- Final `apps/rebind/scripts/dev.sh build` and `apps/rebind/scripts/dev.sh release` succeeded. Release
  contains arm64/x86_64 and passes `codesign --verify --strict --verbose=2`.
  No Swift/concurrency warnings; expected AppIntents metadata-extraction warning
  because this app does not use AppIntents. Hosted tests emitted system
  `com.apple.linkd.autoShortcut` connection messages without test failures.
- Russian mouse-category footer, editor's button/wheel selector, full wrapped
  wheel hint, missing-permission disabled controls and Escape cancellation
  inspected in the actual Debug app. No rule was saved and no access granted.
  Catalog has 62 keys with nonempty EN/RU/DE/FR translations. Other language
  layouts, appearance settings, VoiceOver and populated-rule editing remain open.

## Pending physical walkthrough

Record Mac/OS build, signing identity and exact bundle path, permission states,
mouse model/connection, keyboard layout, natural-scroll setting and any OEM or
scroll utilities. Use a disposable TextEdit document; choose a harmless output
such as Command+A. Complete Phase 1's keyboard/Button 4 checks as well.

1. Grant the required access through Rebind's permission UI, refresh actual
   status and relaunch if requested. Keep the signed bundle and path stable.
2. In **All mice**, add a **Scroll Wheel** rule. Hold Control and turn the wheel
   upward; verify recorded direction/modifiers, record output, save and enable.
   In TextEdit check one output and no original scroll for a slow matching event.
   Check plain scroll and Control+Shift scroll keep their original behavior.
3. Repeat for down and a horizontal/tilt wheel's left/right events. Check
   modifier press order and changed natural-scroll settings; label directions
   follow delivered OS events, not an inferred physical motion.
4. Spin rapidly and alternate axes. Verify no catch-up after stopping and no
   more than one output per 100 ms across wheel rules. Recipient behavior and
   event-path latency still need observation; unit timing is not hardware proof.
5. Verify smooth trackpad, momentum, diagonal and zero-delta phase events retain
   their original behavior while a wheel rule exists. Repeat with utilities
   disabled and enabled; document any transformed events that become eligible.
6. Pause/resume, open/cancel the editor, change input type while recording,
   use Secure Input without recording text, sleep/wake, revoke/restore access
   and retry after a disabled tap. Check pending actions do not fire afterward.
7. Edit/save/relaunch a wheel rule; verify direction, modifiers, ID and output.
   Test a disposable legacy version-1 configuration: opening preserves disk
   bytes and rules, saving writes current version 4. Back up real user data first.
8. Check keyboard navigation, VoiceOver, EN/DE/FR layout and Increase Contrast.
   Two mice may both match category-wide rules; no per-device support follows
   from this slice. Magic Mouse touch remains deferred; button-hold pointer gestures
   are implemented separately with their own pending hardware check.

Do not mark the wheel requirement or Phase 2 complete without these results.
