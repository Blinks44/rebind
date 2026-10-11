# INPUT-001 — reliable integrated four-finger tap

- Updated: 2026-10-11, buffer-loss/readiness race repaired and injected stress verified; hardware timing and broader safety/platform acceptance remain open.
- Stage: `awaiting_verification`
- Owner: Unassigned; `/root` released buffer-overflow/polling safety slice 2026-10-11. Native Trackpad buffer/session/capture and scoped tests only; no UI/catalog or Sketch edits.
- Owned surfaces when claimed: `rebind/Engine/Trackpad/`, affected trackpad tests/copy and this record; coordinate any shared UI/catalog changes.
- Requirements: SPEC §3.4, §§6–7/12, T1/T2, S1/S3; PLAN Phase 5.
- Code baseline: `main` / `9253799` plus uncommitted buffer safety changes; began at `8daa97b`, then independent Mouse/About/design work was committed externally. Earlier capture/output repairs are committed; historical evidence below retains its original revisions. No agent commit.

## Outcome and scope

Make the already integrated experimental **built-in single four-finger tap → keyboard shortcut** usable and safe after ordinary physical clicks. An earlier user-assisted comparison reported 8/10 Rebind taps initially, then loss of recognition after clicking/tapping; BTT reports 10/10 and continued operation. Exact app artifacts, BTT version/settings and execution overlap were not supplied for that comparison. A subsequent packaged Debug diagnostic run reported 1,342 frames, 37 qualified/queued taps and 37 output cancellations, with no posted output. Its 44 foreground-change counts mixed capture/focus changes with sender failures; the old sender cannot distinguish an unavailable AX focus result, a different AX PID or invalidation during the AX read. After the native output-target repair, a fresh repository Debug run reports 1,692 frames and 25 qualified/queued/posted outputs, without output cancellation/failure; the user estimates roughly 10/10 successful taps in the requested retest. This confirms the configured delivery happy path, not a controlled click-only exclusivity or full lifecycle test. A separate user check confirms physical clicks alone do not send Command-W and a subsequent tap works. This supersedes the earlier possible click-output report for the tested setup; exact click count/hold durations were not supplied. Do not restart gesture integration or expand gesture scope to solve this task.

Existing fixes retain timed zero-contact releases, allow natural finger spread/travel and 400 ms duration, settle for 60 ms and recover across idle forward native-frame gaps. Active-stroke/pending-output gaps, stale/malformed input and cancellation remain guarded. Private acquisition is Experimental; no system gesture suppression or physical mouse-source attribution.

## Acceptance

- [x] Rebuilt built-in single four-finger tap → configured Command-W delivery is user-confirmed (~10/10), supported by 25 qualified/queued/posted outputs in one diagnostic run.
- [ ] Measure latency and verify repeat frequency over additional sessions/conditions; the reported estimate is not a measured failure-rate benchmark.
- [x] User confirms physical clicks alone do not send Command-W and subsequent taps still work in the current built-in setup.
- [ ] Verify separately documented quick/held durations, mixed-input timing and repeated-session stress; the confirmation did not enumerate these variants.
- [x] Requested pause/resume, sleep/wake and mixed-input walkthrough user-confirmed 2026-10-11; counts/timing not supplied.
- [ ] Remaining repeat/rolling placement, motion/hold negatives, quantified mixed-input stress and profile/focus/protected cancellation have scoped evidence.
- [ ] Sleep/wake/stop/recovery/protected-context/native-conflict checks have evidence before stronger capability claims; macOS 26/Intel remain separate checks.
- [ ] Save exact app/revision, OS/device, rule and observed results; update capability/task/STATE without overstating user feedback.

## Implementation and verification

Existing implementation: `ShortContactRecognizer`, `FourFingerTapGate`, native bounded buffer/device/session/runtime, targeted existing-worker dispatch. Broader pure `TrackpadTapSequence`/corner components are software-tested but not integrated into production recognition.

Prior repair samples processing time after dequeue, separates receipt/poll clocks and preserves already observed neutrality across activity-only changes while cancelling pending output. Three regressions failed before those fixes. The new repair handles a release buffered before mouse-up but consumed with the newer activity counter: output is cancelled, while a valid fresh same-revision zero-contact observation rearms the next stroke. The new parameterized regression failed in both cases before repair and passes afterward. Stale, future, malformed, active-contact and old-revision frames cannot rearm; negative tests verify recovery after a later valid release. Duration/travel/finger thresholds and the 60 ms click-check delay are unchanged. Focus/rule changes, uncertain/active contacts, stale frames and true backwards clocks still cancel.

`--diagnose-trackpad` explicitly enables one-minute aggregate developer-console counters for recognition, cancellation, queueing and posting. No raw contact/keyboard/target/configuration data; no callback logging or serialization under the shared lock. Protection/revocation clears diagnostics. This mode uses the saved rules and does not configure or post a test action itself. [Instructions/evidence](../verification/phase-5-four-finger-tap.md#timing-races-recovery-and-opt-in-diagnostics--2026-10-10).

Current output repair replaces target AX-tree focus lookup with the public thread-safe `NSRunningApplication.isActive`/termination/regular-policy check on the captured PID, checked twice. Main-run-loop caching and the final posting race remain; mailbox focus/activity/rule validation and PID-directed balanced output remain mandatory. Final permission/session/held-input checks are repeated before posting. `output-target-inactive` is separate from capture `foreground-changed`; runtime invalidation stays separate. Native input callbacks/thresholds are unchanged. [Research/evidence](../verification/phase-5-four-finger-tap.md#output-target-validation--2026-10-11).

Latest hardware evidence: [successful user-assisted retest](../verification/phase-5-four-finger-tap.md#successful-single-tap-retest--2026-10-11), with local Debug implementation digest matching the previous build. Target applications, tap/click phase counts and BTT process state were not independently recorded.

Earlier output-target software verification: `scripts/dev.sh test -resultBundlePath build/TrackpadOutputValidationTests.xcresult`: **493 tests / 65 suites / 0 failures**, including Debug compilation; `scripts/dev.sh release`: **BUILD SUCCEEDED**. Both strict/deep signature checks pass; Release is universal. Existing AppIntents metadata-skip warning remains. The agent performed no manual trackpad/output test; comparison and diagnostic evidence are user-reported. New injected tests exercise the sender itself, cancellation during preparation and 37 dispatches following real-button event pairs without native output. [Buffered-release evidence](../verification/phase-5-four-finger-tap.md#buffered-release-after-mouse-up--2026-10-10). [Renewed library audit](../research/trackpad-tap-reliability.md) adds Touchy/MultiTouch/BTT integration analysis; no dependency or upstream code added.

## Next handoff

Preserve the successful delivery/click-only recovery and pause/resume/sleep/wake/mixed-input confirmations. Next verify delayed/busy-consumer cancellation and fresh-tap recovery on an identified build, retaining separate measured latency, quick/held-duration and quantified mixed-input stress checks. Use diagnostics only if symptoms recur; do not repeat confirmed scenarios or adjust thresholds without new evidence. Broader protected-session/native conflicts/minimum-OS/Intel remain open. Do not launch another engine or change rules/permissions on the user's behalf.

## User lifecycle follow-up — 2026-10-11

The user reports the requested remaining four-finger-tap checks all work: pause/resume, sleep/wake and mixed input. This is user-reported acceptance of that bounded walkthrough; exact app digest, OS/device, counts, timing and individual stress variants were not restated. Preserve prior delivery/click-only evidence. No measured latency, minimum-OS/Intel, native-conflict or complete protected-context certification follows from this report. Do not repeat the confirmed scenarios without a new concern. Next: remaining quantified stress/platform/safety acceptance before stronger capability claims.

## Buffer loss and polling readiness — 2026-10-11

Repaired loss during queue draining and readiness with queued contacts. Overflow quarantines new frames until acknowledged; recognition cancels on loss during/after the bounded turn. Final readiness checks queue/acceptance/loss under the existing buffer mutex, with clocks/diagnostics/mailbox operations outside. Thresholds, acquisition mechanism, output guards and experimental/no-suppression scope remain.

Before-fix regressions failed; 40 targeted functions / 106 executions now pass. Full regression: **591 tests / 1,496 expanded executions / zero failures**, Debug build and local signature pass. Injected 200 overflow/recovery cycles produce 200 fresh readiness results, zero cancelled-candidate outputs and zero duplicates. Exact commands, artifact hashes, warning/review limits and remaining hardware gates: [buffer safety evidence](../verification/trackpad-buffer-safety.md). Independent saved design changes were preserved; task remains `awaiting_verification`, ownership released.
