# Phase 5: integrated four-finger tap (experimental)

## Implemented subset

Built-in trackpad only: an unmodified, light, stationary single four-finger tap
can send a configured keyboard shortcut through Rebind's serial action worker.
The trigger is a named preset in the editor, not a gesture recorder. Rules use
normal profile selection, enable/edit/delete and versioned local persistence.
Schema 22 preserves schemas 1–21, including inactive profiles, without rewriting
on load. Unsupported activation/modifier/action payloads are rejected.

This first integration does not yet expose the full shared action catalog for
touch. It does not remove SPEC §5's eventual requirement. Three-finger taps,
physical multi-finger clicks, double taps, corners, modifier combinations and
external Magic Trackpad remain separate implementation/hardware gates.

## Runtime and limits

- Private MultitouchSupport is isolated in NativeTrackpadDevice. Only a built-in
  default device is accepted, on macOS major versions 26–27. Neither macOS 26 nor
  Intel execution has been verified. Future OS versions fail unavailable.
- C signatures/contact layout were compared with pinned Apache-2.0 Subsurface;
  the full notice is bundled. No app SPM dependency, Scribe/SwiftSyntax macros,
  external helper, haptics, seizure, system preference change or GPL code.
- Count is checked before reading native memory; at most 16 records are examined
  and four active contacts copied into a fixed 64-frame ring. Overflow, invalid
  metadata, unknown release time, backwards/repeated native IDs, nonmonotonic
  time or stale (>100 ms) frames cancel. Forward gaps also cancel an active
  stroke or pending output. Between strokes, after known neutral, a forward
  ID gap may start a fresh stroke; it never bridges an unfinished contact sequence.
  Callback time/frame are preserved even for an empty contact array: a known
  consecutive zero-contact callback can finish a stroke without a terminal record.
  Callback timing is used throughout, rather than mixing record and callback clocks.
  Coordinates/contact IDs are transient and never logged, displayed or persisted.
- One process-owned native device/registration/context is retained until exit.
  Acceptance closes before MTDeviceStop; native callback quiescence is not a
  documented guarantee, so no unretained released Swift context is reused. Pause,
  edit/record, profile changes, permissions, Secure Input and protected sessions
  invalidate the mailbox/session; callbacks refuse protected runtime snapshots.
  Actual stop/restart/wake behavior remains a hardware check. MainActor stop can
  be delayed if the UI thread is blocked; no delayed output is replayed.
- Three-second arming delay after capture starts. Candidate bounds now allow
  30–400 ms contact duration, ≤150 ms arrival/lift spread, at least two peak-count
  frames and individual movement ≤0.04 normalized units, neutral before a stroke.
  The second peak frame may arrive in 8 ms; no fixed 15 ms peak dwell is required.
  Identity replacement/bounce, five contacts, >50 ms active-frame gaps, holds and
  larger movement still reject a stroke. Pressure is not a click classifier.
- A completed candidate waits 60 ms. Any real key/modifier/button/wheel event,
  new contact, focus change, capture loss or revision change cancels it. Existing
  Quartz observation supplies the activity counter even for remapped buttons;
  tagged Rebind output is excluded. The counter is sampled at native receipt,
  not retroactively when the UI consumes buffered contacts.
- Empty native tails preserve an already qualified release, but cannot qualify
  an incomplete release without native timing. Repeat taps produce one action each; rapid taps within
  the settling interval cancel the previous candidate.
- One bounded gesture dispatch slot; busy ordinary/workspace queues discard the
  gesture. Posting expires after 100 ms and rechecks cancellation, session/access,
  held modifiers/buttons/output key. Complete tagged down/up pairs go to the
  captured foreground PID through public CGEvent.postToPid. The existing public
  AX client rechecks current application PID on the action thread before posting,
  covering delayed MainActor focus notifications. No delivery ack/retry.
- A button-free 60 ms interval is a conservative condition, not physical-source
  proof or universal tap/click exclusivity. The current contact-observer path does not suppress native gestures; [selective suppression feasibility](../research/native-gesture-suppression.md) remains unestablished.
  System conflicts/double effects remain possible and are disclosed in the UI.

## Software verification: 2026-10-09–10

The user confirms integrated app output (2026-10-10), but reports approximately
one successful tap out of seven and noticeable delay versus BetterTouchTool. This
is a usability failure, not Phase 5 acceptance. After the responsiveness change,
the user reports somewhat better detection initially, then complete loss of tap
output after physical four-finger clicks. Synthetic click → neutral → separated
tap sequences reproduce an idle-frame-gap cancellation loop. The recovery fix
allows forward frame gaps only after known neutral and outside pending output.
The actual hardware cause and recovery still need confirmation; no input trace
was collected from the reported failure. The responsiveness fix preserves
empty-callback timing, widens natural-contact tolerances and reduces the click
check from 500 to 60 ms. The probe’s observed +12/+28 ms button pair fits that
window; other-device timing and real end-to-end latency are not established.

Swift Testing covers the pure recognizer/session, timestamped empty release,
8 ms peak frames, 320 ms rolling contacts with small drift, click-to-tap recovery
with forward idle ID gaps, backwards/repeated IDs with recovery, qualified empty tails, repeated
single taps, gaps/invalid/stale frames, click/activity/focus cancellation, arming,
delayed clicks at +12/+28/+59 ms, late poll, bounded buffer/pointer copy, schema/profile compatibility, duplicate
rules, queue expiry and targeted dispatch with injected senders. No test creates
or starts a native device, posts real input, changes permissions or writes user
configuration. See [the historical software-check register](../history/implementation-through-2026-10-10.md#historical-software-check-register) for exact prior commands/counts/build evidence; current work is indexed by [STATE](../STATE.md).

Current Sketch Rebind document 10246E46-59D2-4110-95FB-7576E75168A9 and keyboard/
editor frames were inspected read-only. Existing native sidebar/form conventions
were reused. On 2026-10-10 the trackpad category's vertical fixedSize regression was
reproduced and fixed. Russian native sidebar/header/Add and preset editor/Cancel
were screenshot-verified after rebuild, including repeated category transitions.
Compact resizing, other locales/VoiceOver and real capture remain unverified;
compilation alone does not establish them.

## User hardware walkthrough

1. Run one rebuilt Rebind copy with its actual Accessibility/posting permission.
2. Use a test profile. Select **Built-in Trackpad**, add a rule, record **⌘W**
   as output and save; enable rules. Trigger is already **Four-finger tap**.
3. Switch to a disposable browser tab, release keys/buttons, wait at least three
   seconds. Tap four fingers naturally and lift them. Repeat 10–20 times using disposable
   tabs. Expect one tab per tap with a short response after lift. Record successes,
   target app, OS/Mac, perceived latency and any original effect. Do not infer a
   measured 60 ms end-to-end latency from the software settling constant.
4. Repeat with slightly rolling placement/lift and small fingertip shifts.
   A physical four-finger press (including a quick click), hold,
   movement, three-finger tap and new contact during settling must not produce
   the configured shortcut. Then lift all fingers and try another series of
   light taps without restarting, toggling rules or changing profiles: tap output
   must recover. Check both a quick physical click and a longer held click.
   Ordinary native behavior remains active.
5. Tap then switch app/profile or pause before dispatch during the short click check: no delayed close.
   Switch profiles back/resume and wait three seconds; repeat the positive case.
6. Relaunch and confirm the saved rule, then test sleep/wake, lock/unlock and
   access revocation/restoration. No old action may fire after recovery.

If a system gesture also fires, pause the test and inspect its System Settings
assignment before testing again. Rebind never disables native settings itself.
T1/T2 and production adapter lifecycle remain unchecked until these real checks.
## Timing races, recovery and opt-in diagnostics: 2026-10-10

Baseline `6c1a5be` plus uncommitted changes in Trackpad capture/gate/session/recognizer/diagnostics, EngineMailbox, ShortcutSender, ActionWorker and trackpad tests. Latest manual feedback reports very low recognition and possible physical-click output; exact tested bundle unknown. Hardware reliability/exclusivity is **not accepted**.

Three deterministic regressions were reproduced before repair: a callback received before a poll decision but consumed afterward, a new contact queued during pending settling, and mouse-up after a known contact release without another idle zero callback. Each corresponding test failed before its fix. The consumer now samples time after dequeue (bounded to 64 frames/turn); poll and receipt clocks are independently monotonic. Activity-only updates retain known neutrality while cancelling pending output; active/uncertain contacts and foreground/rule changes do not retain it. Thresholds remain unchanged. Backwards clocks, stale/obsolete input and pending-click cancellation still have negative tests.

Final checks on Apple Silicon/macOS 27.0.1, Xcode 27.0/Swift 6.4/SDK 27:

- `apps/rebind/scripts/dev.sh test -resultBundlePath build/TrackpadReliabilityFinalTests.xcresult`: **TEST SUCCEEDED**, 488 tests / 64 suites / zero failures. This includes Debug app compilation. Initial diagnostics builds exposed missing Synchronization import and default-MainActor extension isolation; both corrected before the final run.
- `apps/rebind/scripts/dev.sh release`: **BUILD SUCCEEDED**. Existing unused AppIntents metadata extraction warning remains; no new compiler diagnostics. Test-host linkd/autoShortcut connection messages are nonfatal test-environment output, not evidence of gesture delivery.
- `codesign --verify --deep --strict` passes for both bundles; Release `lipo -archs`: `x86_64 arm64`. Minimum macOS 26/Intel execution remains unverified.
- Debug executable SHA-256 `a4390f1ccf5cbc01dcbd94bda83ccff719a85a90659d29f2e28d7de0bc9c2b3a`; Debug implementation dylib `dc551faa24087dd0708fb6b71bebe9231d5e52c238c10f9e650805c3f474b3f4`; Release executable `13b0f20317a45d9cd7950b3f37d86a18ad9ad21330f0d4305358a13d9e7f980c`. These identify current ignored local artifacts, not a committed revision.
- No actual tap, Command-W output, rule/permission mutation or manual latency/click-exclusivity test performed by the agent.

### User-assisted diagnostic run

Quit existing Rebind copies and competing gesture remappers. From the repository, start the just-built packaged executable, with the existing test rule and disposable target tabs:

```sh
build/DerivedData/Build/Products/Debug/Rebind.app/Contents/MacOS/Rebind --diagnose-trackpad
```

Alternatively add `--diagnose-trackpad` under Xcode scheme → Run → Arguments, rebuild and use the debug console. Remove it after the check. Avoid simultaneously running the Terminal and Xcode copies.

This is **the real app**, not the standalone probe: saved rules remain active. After the existing 3-second arming delay, perform 10–20 natural taps, then quick/held clicks and further taps. A click-only Command-W is a failed safety check. After 60 seconds, share only the `trackpad_diagnostics={...}` summary and observed success frequency/recovery.

Counters are fixed safe reason names: frames, qualified taps, queueing/posting, recognition motion/contact/time/neutrality rejection, gate cancellation, buffer staleness/overflow, output held-input/target/deadline failures and capture availability. Rejections may count frames or completed sequences; do not interpret their sum as the number of gestures. `output-posted` is Quartz submission, not delivery acknowledgement. No text, coordinates, contact IDs, key/button codes, target identity or rules are included. Opt-in developer output is limited to a startup notice and one bounded aggregate JSON report; no diagnostic file is created. Aggregate collection expires after one minute and data is cleared on protected-context/access loss. Normal launch enables no report. Pure tests cover expiry, one-shot reporting and secure-context clearing. Acquisition/callback ownership and native-gesture passthrough remain unchanged.

Next gate: rebuilt-app hardware frequency, click-only negatives and post-click recovery with this report. [Research decision](../research/trackpad-tap-reliability.md), [task](../tasks/INPUT-001-four-finger-tap.md). No broader gesture or BTT-equivalence claim.

## Buffered release after mouse-up: 2026-10-10

User-reported built-in-trackpad comparison: Rebind initially delivered 8/10 taps, then stopped responding after clicks/taps; BTT delivered 10/10 and continued operating. Exact app artifacts, BTT version/settings, overlap and diagnostic report were not supplied. This establishes a reported regression, not controlled latency or click-exclusivity acceptance.

Baseline `f549764`, with uncommitted changes confined to `TrackpadTapSession.swift` and `TrackpadIntegrationTests.swift` plus affected records. The new parameterized regression reproduced a release buffered before physical mouse-up but consumed after the activity counter advanced. Both timestamped and untimed zero-contact cases failed against the baseline: the next tap could not qualify without an extra idle callback. This is a concrete recovery bug, not yet an explanation of the sustained hardware failure.

The repair cancels output for an activity-mismatched frame but retains its neutral observation only when valid, same-revision, nonfuture and at most 100 ms old. Active-contact, malformed, stale, future and different-revision frames cannot rearm. Five negative cases verify cancellation and recovery after a later valid release. No thresholds, settling delay, callback ABI, capture ownership, dispatch guards or dependencies changed.

Checks on the previously recorded Apple Silicon/macOS 27.0.1/Xcode 27 toolchain:

- Before repair: `apps/rebind/scripts/dev.sh test -only-testing:apps/rebind/rebindTests/TrackpadIntegrationTests -resultBundlePath build/TrackpadBufferedReleaseBefore.xcresult`: **TEST FAILED**, both new release-order cases failed; 26 test functions / one suite / two issues.
- After repair: `apps/rebind/scripts/dev.sh test -resultBundlePath build/TrackpadBufferedReleaseFinal.xcresult`: **TEST SUCCEEDED**, 490 tests / 64 suites / zero failures, including Debug app compilation.
- `apps/rebind/scripts/dev.sh release`: **BUILD SUCCEEDED**. Existing AppIntents metadata-skip warning remains. Both bundles pass `codesign --verify --deep --strict`.
- Debug implementation dylib SHA-256: `c55c5c7bde615cb5d8c59ae4e866ccdc3402adc25a3f6c412b030959cdfad9ef`; Release executable: `868acf306921c22d47a8ef533aff7339c63aa52df1780bd8acef041532f466d1`.
- No actual app/remapping launch, user-rule/permission changes, Sketch edit or agent commit. Hardware recovery, click-only output and minimum-OS/Intel checks remain open.

Next: use the fresh packaged Debug executable with `--diagnose-trackpad` as above, with other Rebind copies/BTT closed. Alternate taps and quick/held clicks, then continue tapping if recognition stops within the one-minute report window. Save the aggregate report and observed delivery/click-only results. Do not claim the sustained failure fixed without that evidence.

## Output target validation: 2026-10-11

User-reported packaged Debug run on the built-in trackpad: 1,342 frames, 37 qualified taps, 37 queued actions and 37 cancelled outputs; no posted output. One capture start, 64 activity changes and 13 obsolete frames were recorded. Recognition continued. The 44 `foreground-changed` counts mixed capture focus changes with sender focus-read/target/runtime failures, so they do not prove 44 app switches or establish which sender subcheck failed. Exact running artifact digest and target applications were not supplied; the locally preceding Debug implementation digest is recorded above.

Baseline `acce2f4`, with uncommitted `ShortcutSender.swift`, `TrackpadDiagnostics.swift` and new `TrackpadShortcutSenderTests.swift`, plus scoped records. The public AppKit target-activity/termination/regular-policy check replaces AX-tree focused-application reads for this sender only. Checks run twice around event construction; mailbox focus/activity/revision guards and PID-directed balanced output are retained. Permission/protected-session and held-input checks repeat immediately before posting. No recognition thresholds, callback changes, rule/grant edits, dependency or source adoption.

`output-target-inactive` now identifies native output target rejection separately from capture `foreground-changed`; `output-runtime-changed` identifies invalidated dispatch. Apple documents NSRunningApplication as thread-safe with main-run-loop caching. That cache and the final focus/post race remain limitations; no atomic delivery/focus guarantee or global-output fallback is claimed. [Research](../research/trackpad-tap-reliability.md#output-validation-follow-up-2026-10-11).

Checks on the existing Apple Silicon/macOS 27.0.1/Xcode 27 toolchain:

- `apps/rebind/scripts/dev.sh test -resultBundlePath build/TrackpadOutputValidationTests.xcresult`: **TEST SUCCEEDED**, 493 tests / 65 suites / zero failures, including Debug compilation.
- New injected tests exercise the sender itself: tagged balanced Command-W pair to the captured PID, eight cancellation cases including changes during preparation, and 37 worker dispatches after real-button event pairs. No native input/output or AX/UI requests are made by those tests; they do not prove hardware recovery.
- `apps/rebind/scripts/dev.sh release`: **BUILD SUCCEEDED**. Both bundles pass `codesign --verify --deep --strict`; Release architectures `x86_64 arm64`. Existing AppIntents metadata-skip warning and nonfatal test-host linkd messages remain.
- Debug implementation dylib SHA-256: `b3c6c7ff9aabb99180c02f9ec2178183b131018cf6f3a114fa5c72af78cc90f3`; Release executable: `251e32ef3bfad4654a841a0ad757c4e6dce09b8fa33b7a13c372d8c2b20f6a33`.
- No agent app/remapping launch, rules/permissions mutation, Sketch edit or commit. Prior actual post-click failure remains reported; the new output check is awaiting hardware verification.

Next: quit other Rebind/BTT copies and launch the fresh packaged Debug executable with `--diagnose-trackpad`. Test natural taps, quick/held clicks and further taps in disposable tabs. Share the one-minute report and actual delivery/click-only behavior. Check `output-posted`, `output-target-inactive`, `output-runtime-changed` and other output guards before further recognition changes. Minimum-OS/Intel, latency and click exclusivity remain open.

## Successful single-tap retest: 2026-10-11

User-assisted retest of the repository packaged Debug executable with `--diagnose-trackpad`, following the requested tap/click/tap walkthrough: roughly 10/10 successful configured Command-W delivery reported. The one-minute aggregate contains 1,692 frames, one capture start, 25 qualified taps, 25 queued actions and 25 posted outputs. No output cancellation, unavailable/expired output or inactive-target/runtime rejection was reported. Three foreground changes, 182 input-activity changes and 23 obsolete frames occurred without capture restart in the reporting window. Recognition rejection counters are per-frame/sequence aggregates, not an attempted-tap denominator.

The local Debug implementation dylib still matches `b3c6c7ff9aabb99180c02f9ec2178183b131018cf6f3a114fa5c72af78cc90f3` from the output-target repair above; baseline `acce2f4` plus that uncommitted repair. The user supplied the executable invocation, not an independently captured running-process digest. Built-in trackpad and configured action carry forward from this task; host OS was previously recorded as macOS 27.0.1. Exact target applications, number/type of physical clicks, independent click-only outcome, BTT process state and measured latency were not supplied.

This supports a rebuilt configured single-tap delivery happy path and supersedes the previous all-cancelled-output observation for this retest. `output-posted` alone is Quartz submission; actual delivery is supported by the separate user confirmation. It does not establish universal recognition, no accidental click-only output, measured 10/10 reliability across sessions, native suppression or full T1/T2/safety acceptance.

Documentation-only evidence update: no source/assets/rules/permissions changed, no app launch, new build/test run or commit by the agent. Prior 493-test/Debug/Release/signature checks retain their scope. Next check quick/held physical clicks alone produce no Command-W and the next tap works; then deliberate pause/resume and sleep/wake. Use diagnostics if a symptom returns; repeating this confirmed delivery run is not a prerequisite for independent work.

### Click-only exclusion and subsequent-tap confirmation

Follow-up user check, 2026-10-11: physical clicks alone did not send the configured Command-W, and taps afterward continued working. This directly confirms the requested negative/recovery scenario on the current built-in-trackpad setup and supersedes the earlier suspected click-only output for that scenario. Same configured binding/build context as the successful retest above; no new aggregate report, click count, hold durations or target-app list supplied. Do not infer every quick/held/mixed-input variant, pause/sleep recovery or universal click suppression from this confirmation.

Recorded as a user-verified subset in the task/capability/roadmap. No implementation, build/test rerun, actual input action, permission/rule change or commit by the agent. Next hardware gate is deliberate pause/resume and sleep/wake; mixed-input/hold-duration stress and broader platform/native-conflict checks remain. Independent implementation can proceed without repeating the successful delivery/click-only scenario.

## User lifecycle follow-up: 2026-10-11

User reports successful pause/resume, sleep/wake and mixed-input checks in response to the pending walkthrough. No new exact artifact/device/OS identifiers, counts or timing measurements were supplied; no native actions were executed by the agent. This closes the reported walkthrough subset, while quantified stress, native conflicts/protected contexts and macOS 26/Intel remain open.
