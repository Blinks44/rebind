# INPUT-001 — reliable integrated four-finger tap

- Updated: 2026-10-10, timing/recovery repair and renewed library audit; hardware acceptance still open.
- Stage: `awaiting_verification`
- Owner: Unassigned; last bounded repair by `/root`. No UI/catalog or Sketch edits.
- Owned surfaces when claimed: `rebind/Engine/Trackpad/`, affected trackpad tests/copy and this record; coordinate any shared UI/catalog changes.
- Requirements: SPEC §3.4, §§6–7/12, T1/T2, S1/S3; PLAN Phase 5.
- Baseline inspected: `6c1a5be`; schema 22 and recognition/recovery changes exist. Compare current HEAD/status before continuing.

## Outcome and scope

Make the already integrated experimental **built-in single four-finger tap → keyboard shortcut** usable and safe after ordinary physical clicks. Prior output was confirmed; latest manual report describes roughly 1 in 20 taps, possible output after a click and extended failure after clicks. The exact tested bundle was not identified. Output delivery does not close usability/exclusivity acceptance. Do not restart gesture integration or expand gesture scope to solve this task.

Existing fixes retain timed zero-contact releases, allow natural finger spread/travel and 400 ms duration, settle for 60 ms and recover across idle forward native-frame gaps. Active-stroke/pending-output gaps, stale/malformed input and cancellation remain guarded. Private acquisition is Experimental; no system gesture suppression or physical mouse-source attribution.

## Acceptance

- [ ] User-assisted rebuilt-app repetition establishes recognition success frequency and perceived delay for 10–20 natural taps in disposable tabs.
- [ ] Quick and held physical clicks do not send Command-W; a subsequent tap works without relaunch/toggle.
- [ ] Repeat taps, modest rolling placement, motion/hold negatives and pause/profile/focus cancellation behave as specified.
- [ ] Sleep/wake/stop/recovery/protected-context/native-conflict checks have evidence before stronger capability claims; macOS 26/Intel remain separate checks.
- [ ] Save exact app/revision, OS/device, rule and observed results; update capability/task/STATE without overstating user feedback.

## Implementation and verification

Existing implementation: `ShortContactRecognizer`, `FourFingerTapGate`, native bounded buffer/device/session/runtime, targeted existing-worker dispatch. Broader pure `TrackpadTapSequence`/corner components are software-tested but not integrated into production recognition.

Current repair samples processing time after dequeue, separates receipt/poll clocks and preserves already observed neutrality across activity-only changes while cancelling pending output. Three new regression tests failed against the preceding implementation and pass after the repair. Duration/travel/finger thresholds and the 60 ms click-check delay are unchanged. Focus/rule changes, uncertain/active contacts, stale frames and true backwards clocks still cancel.

`--diagnose-trackpad` explicitly enables one-minute aggregate developer-console counters for recognition, cancellation, queueing and posting. No raw contact/keyboard/target/configuration data; no callback logging or serialization under the shared lock. Protection/revocation clears diagnostics. This mode uses the saved rules and does not configure or post a test action itself. [Instructions/evidence](../verification/phase-5-four-finger-tap.md#timing-races-recovery-and-opt-in-diagnostics--2026-10-10).

Current verification: `scripts/dev.sh test -resultBundlePath build/TrackpadReliabilityFinalTests.xcresult`: **488 tests / 64 suites / 0 failures**, including Debug compilation; `scripts/dev.sh release`: **BUILD SUCCEEDED**. Both strict/deep signature checks pass; Release is universal. Existing AppIntents metadata-skip warning remains. No manual trackpad/output acceptance was performed. [Renewed library audit](../research/trackpad-tap-reliability.md) adds Touchy/MultiTouch/BTT integration analysis; no dependency or upstream code added.

## Next handoff

Have the user quit other Rebind copies/BTT, start the just-built bundle with `--diagnose-trackpad`, and alternate natural taps and quick/held clicks in disposable tabs. Wait for the one-minute summary and record recognized/delivered counts, click-only output and recovery. Use actual rejection counts to select the next fix. Physical-click false positives remain unresolved hardware acceptance, not an established fix. Do not launch another engine or change their rules on the user's behalf merely to collect evidence.
