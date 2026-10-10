# INPUT-001 — reliable integrated four-finger tap

- Updated: 2026-10-10, buffered-release repair after comparative hardware feedback; hardware acceptance still open.
- Stage: `awaiting_verification`
- Owner: Unassigned; `/root` completed the bounded buffered-release repair. No UI/catalog or Sketch edits.
- Owned surfaces when claimed: `rebind/Engine/Trackpad/`, affected trackpad tests/copy and this record; coordinate any shared UI/catalog changes.
- Requirements: SPEC §3.4, §§6–7/12, T1/T2, S1/S3; PLAN Phase 5.
- Baseline inspected: `f549764` (`feat: phase 5`); prior repairs are committed. The new TrackpadTapSession/test repair remains uncommitted. Compare current HEAD/status before continuing.

## Outcome and scope

Make the already integrated experimental **built-in single four-finger tap → keyboard shortcut** usable and safe after ordinary physical clicks. Latest user-assisted comparison reports 8/10 Rebind taps initially, then loss of recognition after clicking/tapping; BTT reports 10/10 and continued operation. Exact app artifacts, BTT version/settings, execution overlap and diagnostic counters were not supplied. Earlier possible click output remains unresolved. Output delivery does not close usability/exclusivity acceptance. Do not restart gesture integration or expand gesture scope to solve this task.

Existing fixes retain timed zero-contact releases, allow natural finger spread/travel and 400 ms duration, settle for 60 ms and recover across idle forward native-frame gaps. Active-stroke/pending-output gaps, stale/malformed input and cancellation remain guarded. Private acquisition is Experimental; no system gesture suppression or physical mouse-source attribution.

## Acceptance

- [ ] User-assisted rebuilt-app repetition establishes recognition success frequency and perceived delay for 10–20 natural taps in disposable tabs.
- [ ] Quick and held physical clicks do not send Command-W; a subsequent tap works without relaunch/toggle.
- [ ] Repeat taps, modest rolling placement, motion/hold negatives and pause/profile/focus cancellation behave as specified.
- [ ] Sleep/wake/stop/recovery/protected-context/native-conflict checks have evidence before stronger capability claims; macOS 26/Intel remain separate checks.
- [ ] Save exact app/revision, OS/device, rule and observed results; update capability/task/STATE without overstating user feedback.

## Implementation and verification

Existing implementation: `ShortContactRecognizer`, `FourFingerTapGate`, native bounded buffer/device/session/runtime, targeted existing-worker dispatch. Broader pure `TrackpadTapSequence`/corner components are software-tested but not integrated into production recognition.

Prior repair samples processing time after dequeue, separates receipt/poll clocks and preserves already observed neutrality across activity-only changes while cancelling pending output. Three regressions failed before those fixes. The new repair handles a release buffered before mouse-up but consumed with the newer activity counter: output is cancelled, while a valid fresh same-revision zero-contact observation rearms the next stroke. The new parameterized regression failed in both cases before repair and passes afterward. Stale, future, malformed, active-contact and old-revision frames cannot rearm; negative tests verify recovery after a later valid release. Duration/travel/finger thresholds and the 60 ms click-check delay are unchanged. Focus/rule changes, uncertain/active contacts, stale frames and true backwards clocks still cancel.

`--diagnose-trackpad` explicitly enables one-minute aggregate developer-console counters for recognition, cancellation, queueing and posting. No raw contact/keyboard/target/configuration data; no callback logging or serialization under the shared lock. Protection/revocation clears diagnostics. This mode uses the saved rules and does not configure or post a test action itself. [Instructions/evidence](../verification/phase-5-four-finger-tap.md#timing-races-recovery-and-opt-in-diagnostics--2026-10-10).

Current verification: `scripts/dev.sh test -resultBundlePath build/TrackpadBufferedReleaseFinal.xcresult`: **490 tests / 64 suites / 0 failures**, including Debug compilation; `scripts/dev.sh release`: **BUILD SUCCEEDED**. Both strict/deep signature checks pass; Release is universal. Existing AppIntents metadata-skip warning remains. The agent performed no manual trackpad/output test; the comparison above is user-reported. [Buffered-release evidence](../verification/phase-5-four-finger-tap.md#buffered-release-after-mouse-up--2026-10-10). [Renewed library audit](../research/trackpad-tap-reliability.md) adds Touchy/MultiTouch/BTT integration analysis; no dependency or upstream code added.

## Next handoff

Have the user quit other Rebind copies/BTT, start the just-built bundle with `--diagnose-trackpad`, and alternate natural taps and quick/held clicks in disposable tabs. Wait for the one-minute summary and record recognized/delivered counts, click-only output and recovery. If recognition stops again, continue tapping within the one-minute diagnostic window and share that report. Use actual rejection counts to select the next fix; the reproduced buffered-release bug does not yet explain the sustained hardware failure. Physical-click false positives remain unresolved hardware acceptance, not an established fix. Do not launch another engine or change their rules on the user's behalf merely to collect evidence.
