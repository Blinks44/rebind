# Phase 2 — Double press → shortcut

Status: implemented; software behavior tests and Russian native-editor checks
pass. **Physical recording, source suppression and recipient delivery are still
unverified.** Phase 1/2 hardware exit criteria remain open. See the
[keyboard/button](phase-1.md) and [wheel](phase-2-wheel.md) walkthroughs.

## Implemented contract

- Ordinary physical keys or middle/extra mouse buttons with exact primary
  modifiers, category-wide scope, ordinary output shortcut. Record the source
  once and choose **Double press**; output recording remains an ordinary shortcut.
- First down is consumed, its up is consumed, and a second matching down within
  the interval produces one output. The second up is consumed even if paused
  or modifiers change. A lone press has no effect and is not replayed later.
  A third press starts a new pair; a fourth can complete it.
- Time is measured from first down to second down using delivered monotonic
  Quartz timestamps. The interval is the macOS `NSEvent.doubleClickInterval`,
  read on MainActor at app start and rule configuration/save/pause/resume.
  After changing system double-click speed, pause/resume to refresh it.
  No per-binding timing setting or asynchronous timeout is introduced.
- One candidate at a time. Another captured key or mouse-button down, eligible
  scroll impulse, primary/Fn modifier-set change, source repeat/duplicate down
  or source drag cancels it. Left/right mouse down is observed only to cancel;
  primary buttons remain unmappable and always pass through. Ordinary pointer
  movement between clicks is allowed: this is a timed double press, not native
  spatial double/triple-click recognition. Unsupported smooth scroll is untouched.
- A completed first release is required, with the original modifier set and
  within the interval. Long first holds do not qualify. Out-of-order second
  down fails open; tag-marked Rebind output never advances or cancels a pair.
- Pause, recording start/cancel, editing, configuration change and queue overflow
  cancel recognition while preserving owned releases. Secure Input, suspension
  and lost capture discard queued output/recognition and clear capture ownership.
  Reserved ⌃⌥⇧⌘ Escape still wins; no synthetic held output is created.
- Press and double-press rules for the same physical source/modifier combination
  conflict. There is no delayed single-press fallback. Disabled rules can coexist,
  but enabling conflicting ones is rejected. Double-press wheel rules are invalid.
- No physical attribution: two keyboards/mice in the same category can contribute
  to a pair. Test this limit explicitly; no per-device support is implied.
- Activation was introduced in schema 3; current schema 4 preserves it and adds
  a default duration for the separate long-press mode. Version-1 key/button and version-2 wheel rules load
  as ordinary press without disk rewrite, retaining IDs, output, modifiers and
  enabled state. Saving is atomic; disguised legacy double rules, invalid enum
  values/null, future versions and enabled conflicts remain rejected.

## Verification performed — 2026-10-08

Host: Apple Silicon, macOS 27.0.1 (26A434), Xcode 27.0, Swift 6.4, SDK 27.0;
minimum macOS 26. No macOS 26/Intel execution claim.

- `scripts/dev.sh test -resultBundlePath build/Phase2DoublePressTests-Final.xcresult`:
  **69 tests / 11 suites / 0 failures**, including 22 new tests for key/numeric
  button pairs, exact interval boundary, expired/held/repeated/dragged sources,
  intervening presses/modifiers, timestamp regression/overflow, pair grouping,
  tagged feedback, conflict rejection, single mailbox evaluation, lifecycle
  cancellation, queue overflow/emergency bypass, recording, legacy schema 1/2
  migration, wheel validity and double-rule persistence.
  Hosted tests never start a global tap/post input or load real user configuration.
- Final Debug and universal Release build succeeded; Release arm64/x86_64 signature
  passes `codesign --verify --strict --verbose=2`. No source/concurrency warnings.
  Expected skipped AppIntents metadata extraction; hosted runner emitted existing
  `com.apple.linkd.autoShortcut` service messages without test failures.
- Actual Debug app inspected in Russian: keyboard and mouse activation selectors,
  full wrapped double-press explanation, missing-permission disabled recording/save,
  wheel hiding the activation selector, switching back restoring ordinary press,
  and Escape cancellation. Initial popup clipped labels; segmented native control
  fixes this. No real rule saved, input recorded, shortcut posted or TCC grant made.
- Catalog contains 66 translated EN/RU/DE/FR keys. Populated-rule editing, other
  language layouts, VoiceOver and appearance checks still need verification.

## Pending physical walkthrough

Record Mac/OS, devices/connections, OEM tools, keyboard layout, system double-click
speed, signing identity/bundle path and actual AX/listen/post permissions. Use a
disposable TextEdit document with a harmless output such as Command+A.

1. Complete Phase 1's permission and ordinary key/Button 4 walkthrough first.
2. Record Control+Option+[ordinary key] once, choose Double press, record Command+A,
   save and enable. Check a lone press causes neither output nor leaked source.
   Release then press rapidly: exactly one Select All, no leaked key-up/repeat.
3. Try slow pairs, long first hold, repeat, different second key, changed modifiers
   away and back, another mouse click between presses, three and four rapid presses.
   Check no delayed action after stopping and unmapped inputs retain normal behavior.
4. Repeat with Control+Button 4 and another button beyond 5 if observable. Test
   dragging cancels; simple movement between clicks may still qualify. Change system
   double-click speed, pause/resume, and verify timing follows the updated setting.
5. Pause/open editor/start recording/change rules while the first source is held
   or after release. Verify stale pairs never fire and owned releases do not leak.
   Check emergency bypass, Secure Input (without logging text), sleep/session lock,
   permission revocation, disabled tap/retry and quit with the existing safety checks.
6. Edit/save/relaunch the rule and verify activation/output/ID/enabled state.
   Attempt an enabled ordinary-press rule for the same chord: surface conflict and
   preserve disk/running rules. Verify wheel rules still work and cannot use Double press.
7. Check two devices: current category rules cannot attribute the two presses to
   one device. Do not mark per-device behavior verified. Check keyboard navigation,
   VoiceOver and EN/DE/FR editor/list layouts separately.

Held synthetic output, native click counts, triple-click, Caps Lock/Fn-only, pointer gestures
and per-device rules remain future work; this slice does not close their criteria.

Long-press trigger activation is implemented separately; see the [hold walkthrough](phase-2-hold.md).
