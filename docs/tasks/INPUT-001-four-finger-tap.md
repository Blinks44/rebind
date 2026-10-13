# INPUT-001: reliable integrated four-finger tap

- Updated: 2026-10-12, foreground round-trip cancellation, timing/scheduling and callback guards software-verified; physical delivery 10/10, no delayed pause/resume outputs and fresh recovery 5/5 user-confirmed. Focus-switching walkthrough user-confirmed; measured timing and broader safety/platform acceptance remain open.
- Stage: `awaiting_verification`
- Owner: Unassigned; `/root` released foreground round-trip cancellation after final software checks 2026-10-12. Measured timing and broader safety/platform acceptance remain open.
- Owned surfaces when claimed: `apps/rebind/rebind/Engine/Trackpad/`, affected trackpad tests/copy and this record; coordinate any shared UI/catalog changes.
- Requirements: SPEC §3.4, §§6–7/12, T1/T2, S1/S3; PLAN Phase 5.
- Code revision: `main` / `a6471db` includes timing diagnostics and foreground cancellation/tests. The checkout advanced externally from `e74ae71` during checks without changing the tested source. Completion records remain uncommitted; no agent commit. Historical evidence retains its original revisions.

## Outcome and scope

Make the already integrated experimental **built-in single four-finger tap → keyboard shortcut** usable and safe after ordinary physical clicks. An earlier user-assisted comparison reported 8/10 Rebind taps initially, then loss of recognition after clicking/tapping; BTT reports 10/10 and continued operation. Exact app artifacts, BTT version/settings and execution overlap were not supplied for that comparison. A subsequent packaged Debug diagnostic run reported 1,342 frames, 37 qualified/queued taps and 37 output cancellations, with no posted output. Its 44 foreground-change counts mixed capture/focus changes with sender failures; the old sender cannot distinguish an unavailable AX focus result, a different AX PID or invalidation during the AX read. After the native output-target repair, a fresh repository Debug run reports 1,692 frames and 25 qualified/queued/posted outputs, without output cancellation/failure; the user estimates roughly 10/10 successful taps in the requested retest. This confirms the configured delivery happy path, not a controlled click-only exclusivity or full lifecycle test. A separate user check confirms physical clicks alone do not send Command-W and a subsequent tap works. This supersedes the earlier possible click-output report for the tested setup; exact click count/hold durations were not supplied. Do not restart gesture integration or expand gesture scope to solve this task.

Existing fixes retain timed zero-contact releases, allow natural finger spread/travel and 400 ms duration, settle for 60 ms and recover across idle forward native-frame gaps. Active-stroke/pending-output gaps, stale/malformed input and cancellation remain guarded. Private acquisition is Experimental; no system gesture suppression or physical mouse-source attribution.

## Acceptance

- [x] Software guard: callbacks admitted before reset/restart/overflow cannot publish into or overflow the recovered queue; 200 injected restarts produce only fresh readiness results.
- [x] User follow-up 2026-10-12 confirms the requested focus-switching/fresh-tap walkthrough; counts/timing and running artifact were not independently captured.
- [x] Software guard: observed foreground round trips cannot revive old runtimes, buffered strokes or dequeued output; stable polling, fresh recovery and keyboard dispatch/release ownership pass injected checks.
- [x] Post-repair physical walkthrough user-confirmed 2026-10-12: 10/10 ordinary taps, zero delayed pause/resume outputs, 5/5 fresh taps after resume. Controlled busy-UI/latency testing remains separate.
- [x] Rebuilt built-in single four-finger tap → configured Command-W delivery is user-confirmed (~10/10), supported by 25 qualified/queued/posted outputs in one diagnostic run.
- [ ] Measure latency and verify repeat frequency over additional sessions/conditions; the reported estimate is not a measured failure-rate benchmark.
- [x] User confirms physical clicks alone do not send Command-W and subsequent taps still work in the current built-in setup.
- [ ] Verify separately documented quick/held durations, mixed-input timing and repeated-session stress; the confirmation did not enumerate these variants.
- [x] Requested pause/resume, sleep/wake and mixed-input walkthrough user-confirmed 2026-10-11; counts/timing not supplied.
- [ ] Remaining repeat/rolling placement, motion/hold negatives, quantified mixed-input stress and profile/focus/protected cancellation have scoped evidence.
- [ ] Sleep/wake/stop/recovery/protected-context/native-conflict checks have evidence before stronger capability claims; macOS 26/Intel remain separate checks.
- [ ] Save exact app/revision, OS/device, rule and observed results; update capability/task/STATE without overstating user feedback.

## Implementation and verification

Existing implementation: `ShortContactRecognizer`, `TrackpadTapGate`, native bounded buffer/device/session/runtime, targeted existing-worker dispatch. INPUT-002/003 now integrate three/four-finger single/double `TrackpadTapSequence` arbitration, exposed through UI-014. Corner recognition remains software-tested without production integration.

Prior repair samples processing time after dequeue, separates receipt/poll clocks and preserves already observed neutrality across activity-only changes while cancelling pending output. Three regressions failed before those fixes. The new repair handles a release buffered before mouse-up but consumed with the newer activity counter: output is cancelled, while a valid fresh same-revision zero-contact observation rearms the next stroke. The new parameterized regression failed in both cases before repair and passes afterward. Stale, future, malformed, active-contact and old-revision frames cannot rearm; negative tests verify recovery after a later valid release. Duration/travel/finger thresholds and the 60 ms click-check delay are unchanged. Focus/rule changes, uncertain/active contacts, stale frames and true backwards clocks still cancel.

`--diagnose-trackpad` explicitly enables one-minute aggregate developer-console counters for recognition, cancellation, queueing and posting. No raw contact/keyboard/target/configuration data; no callback logging or serialization under the shared lock. Protection/revocation clears diagnostics. This mode uses the saved rules and does not configure or post a test action itself. [Instructions/evidence](../verification/phase-5-four-finger-tap.md#timing-races-recovery-and-opt-in-diagnostics-2026-10-10).

Current output repair replaces target AX-tree focus lookup with the public thread-safe `NSRunningApplication.isActive`/termination/regular-policy check on the captured PID, checked twice. Main-run-loop caching and the final posting race remain; mailbox focus/activity/rule validation and PID-directed balanced output remain mandatory. Final permission/session/held-input checks are repeated before posting. `output-target-inactive` is separate from capture `foreground-changed`; runtime invalidation stays separate. Native input callbacks/thresholds are unchanged. [Research/evidence](../verification/phase-5-four-finger-tap.md#output-target-validation-2026-10-11).

Latest bounded hardware follow-up: [focus-switching/fresh-tap walkthrough](../verification/trackpad-focus-cancellation.md#user-hardware-follow-up-2026-10-12) user-confirmed. Earlier quantified hardware evidence: [post-generation-repair user walkthrough](../verification/trackpad-callback-generation.md#user-hardware-follow-up-2026-10-12): 10/10 delivery, zero delayed pause/resume outputs and 5/5 fresh recovery. Earlier [diagnostic delivery retest](../verification/phase-5-four-finger-tap.md#successful-single-tap-retest-2026-10-11) retains its aggregate evidence. Running digest/target/settings were not independently captured; current report supplies counts, not measured latency.

Earlier output-target software verification: `apps/rebind/scripts/dev.sh test -resultBundlePath build/TrackpadOutputValidationTests.xcresult`: **493 tests / 65 suites / 0 failures**, including Debug compilation; `apps/rebind/scripts/dev.sh release`: **BUILD SUCCEEDED**. Both strict/deep signature checks pass; Release is universal. Existing AppIntents metadata-skip warning remains. The agent performed no manual trackpad/output test; comparison and diagnostic evidence are user-reported. New injected tests exercise the sender itself, cancellation during preparation and 37 dispatches following real-button event pairs without native output. [Buffered-release evidence](../verification/phase-5-four-finger-tap.md#buffered-release-after-mouse-up-2026-10-10). [Renewed library audit](../research/trackpad-tap-reliability.md) adds Touchy/MultiTouch/BTT integration analysis; no dependency or upstream code added.

## Next handoff

Preserve the successful delivery/click-only recovery and pause/resume/sleep/wake/mixed-input confirmations, including the quantified post-repair 10/10 delivery and 5/5 fresh recovery without delayed pause outputs. Next prepare controlled busy-consumer scheduling/latency measurement on an identified build; keep quick/held-duration and quantified mixed-input stress separate. Use diagnostics only if symptoms recur; do not repeat confirmed scenarios or adjust thresholds without new evidence. Broader protected-session/native conflicts/minimum-OS/Intel remain open. Do not launch another engine or change rules/permissions on the user's behalf.

## User lifecycle follow-up: 2026-10-11

The user reports the requested remaining four-finger-tap checks all work: pause/resume, sleep/wake and mixed input. This is user-reported acceptance of that bounded walkthrough; exact app digest, OS/device, counts, timing and individual stress variants were not restated. Preserve prior delivery/click-only evidence. No measured latency, minimum-OS/Intel, native-conflict or complete protected-context certification follows from this report. Do not repeat the confirmed scenarios without a new concern. Next: remaining quantified stress/platform/safety acceptance before stronger capability claims.

## Buffer loss and polling readiness: 2026-10-11

Repaired loss during queue draining and readiness with queued contacts. Overflow quarantines new frames until acknowledged; recognition cancels on loss during/after the bounded turn. Final readiness checks queue/acceptance/loss under the existing buffer mutex, with clocks/diagnostics/mailbox operations outside. Thresholds, acquisition mechanism, output guards and experimental/no-suppression scope remain.

Before-fix regressions failed; 40 targeted functions / 106 executions now pass. Full regression: **591 tests / 1,496 expanded executions / zero failures**, Debug build and local signature pass. Injected 200 overflow/recovery cycles produce 200 fresh readiness results, zero cancelled-candidate outputs and zero duplicates. Exact commands, artifact hashes, warning/review limits and remaining hardware gates: [buffer safety evidence](../verification/trackpad-buffer-safety.md). Independent saved design changes were preserved; task remains `awaiting_verification`, ownership released.

## In-flight callback generations: 2026-10-12

Callbacks now retain the admitted queue generation and validate it before publication/capacity checks. Reset/restart/overflow advances the generation, preventing delayed frames from contaminating recognition or clearing a full fresh queue. Native reads remain outside locks; acquisition, thresholds, schema and output guards are unchanged. Scope covers admission before invalidation, not undocumented private-framework callback quiescence.

Four deterministic regressions failed before repair. Final scoped checks: **46 functions / 117 executions**, including the Settings fixture retry; **200 injected restarts**, zero obsolete readiness results/duplicates and 200 fresh results. Final full retry: **653 functions / 1,835 executions / zero failures**; Debug/signature pass. The initial full run lost the Settings test runner (exit 0); isolated and full retries pass without source changes. Existing aggregate-window/service warnings and hardware/platform gates remain. [Exact evidence, limits and final artifact](../verification/trackpad-callback-generation.md). No agent commit or production capture launch; ownership released. Next: measured physical busy-consumer cancellation/fresh-tap recovery on that artifact, preserving prior user-confirmed subsets.

## Consumer scheduling and timing: 2026-10-12

Added one-minute opt-in fixed age buckets for frame dequeue and successfully posted queue age, using the existing monotonic clocks. Queue admission time is transient; coordinates/text/target identity and exact durations never enter reports. Callback acquisition, thresholds, single/double arbitration, schema and output safety gates remain unchanged. Diagnostic recording occurs after the balanced pair to avoid a mailbox-lock wait inside the final posting window.

[Evidence and review](../verification/trackpad-scheduling-timing.md): final user-run regression inspected by the agent, **659 functions / 1,860 expanded executions / zero failures/skips**. All final diagnostic/sender/scheduling tests pass, including 400 injected stall/recovery cycles and exact expiry boundaries. Debug/signature pass. Earlier interruptions/access limits remain historical in evidence; final test-host acceptance is resolved. Existing aggregate-window/service console warnings remain separate from passing xcresult status. No production capture/output/rule change or agent commit; independent `.gitignore` work preserved.

Next: collect opt-in aggregate timing on the identified artifact before physical latency/stress claims. Preserve confirmed ordinary delivery/pause/recovery; do not repeat those without a new symptom.

## Foreground round-trip cancellation: 2026-10-12

Repaired A → B → A reviving old touch work: focus changes and activation notifications now advance the existing transient input-activity snapshot. The poll updates foreground before reading runtime; delayed notifications invalidate even if the sampled PID is unchanged. Buffered contacts and worker output use their existing snapshot guards. Stable polling and general keyboard/mouse action revision/press ownership remain intact. No threshold/schema/acquisition/Sketch change.

Before repair, all seven injected cases failed. Final scoped checks: **89 functions / 283 executions**; full regression: **666 functions / 1,870 executions / zero failures/skips**; ordinary Debug/signature pass on source `a6471db`. [Evidence, artifact and limits](../verification/trackpad-focus-cancellation.md). Existing timing work and independent changes are preserved; no agent commit or production capture/output. This bounded software repair is complete; task stays `awaiting_verification` for physical/platform gates. User follow-up confirms the requested focus-switching/fresh-tap walkthrough; [scope and evidence limits](../verification/trackpad-focus-cancellation.md#user-hardware-follow-up-2026-10-12) remain explicit. Next: aggregate timing measurement on an identified ordinary bundle, retaining confirmed scenarios.
