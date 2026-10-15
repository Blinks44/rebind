# INPUT-001: Reliable integrated four-finger tap

- Updated: 2026-10-16 (documentation reconciliation)
- Stage: awaiting_verification
- Owner: Unassigned; software repairs released
- Requirements: SPEC §§3.4, 6–7, 12; T1/T2, S1/S3
- Code baseline: timing/focus repairs verified on `a6471db`; integrated source exists in `1a0801b`. Later preset/action changes have separate tasks. No new physical/software checks in this cleanup.

## Current outcome

Built-in four-finger delivery and click-only recovery have scoped user confirmation. The bounded recognizer/buffer/gate and existing worker retain cancellation, target, permission/session, held-input, expiry and balanced-output guards. Later three/four single/double, corner/click, shared-action and external-category additions are integrated under INPUT-002–009; corner recognition is no longer an unwired future slice.

The original output failure was reproduced: 1,342 frames, 37 qualified/queued outputs and 37 cancellations, no posted output. Sender AX focus lookup was replaced by public target activity/termination/policy checks on the captured PID. The successful retest reported 1,692 frames and 25 qualified/queued/posted outputs, approximately 10/10 delivery. Original BTT comparison, target/settings/build unknowns and diagnostic interpretation are retained in [tap evidence](../verification/phase-5-four-finger-tap.md). This is not a controlled latency/failure-rate benchmark.

## Acceptance and evidence

- [x] Configured delivery, physical-click-only exclusion/subsequent-tap recovery and requested pause/resume/sleep/wake/mixed-input walkthrough user-confirmed, 2026-10-11.
- [x] Post-generation repair: 10/10 delivery, zero delayed pause/resume outputs and 5/5 fresh recovery reported, 2026-10-12.
- [x] Requested foreground-switching/fresh-tap walkthrough user-confirmed; exact count/timing/running digest not captured.
- [x] Deterministic injected buffer/readiness, in-flight generation, scheduling/expiry and foreground round-trip cancellation checks; no obsolete/duplicate outputs in their bounded regressions.
- [ ] Measured physical latency and repeat frequency across additional sessions/conditions.
- [ ] Separately quantified quick/held durations, rolling placement, movement/hold negatives, mixed-input stress and protected/profile/focus cancellation.
- [ ] Broader sleep/wake/stop/recovery/native conflicts and macOS 26; Intel only if claimed.
- [ ] Exact current bundle/revision, OS/device/settings and evidence source recorded before stronger claims.

| Repair / retained decision | Dated verification owner |
| --- | --- |
| Release buffered before mouse-up: cancel stale output while valid fresh neutrality rearms recognition; stale/future/malformed frames cannot rearm | [Tap recovery/output target](../verification/phase-5-four-finger-tap.md); original 493-test regression and Release/signatures |
| Queue loss quarantines frames; final readiness checks acceptance/loss/queue atomically with clocks/diagnostics outside the mutex | [Buffer safety](../verification/trackpad-buffer-safety.md); 200 overflow/recovery cycles, 591 full-suite tests |
| Admitted callback generation must still match before publication/capacity checks; stale copies cannot contaminate a restarted queue | [Callback generations](../verification/trackpad-callback-generation.md); 200 injected restarts, final 653-function regression |
| Fixed frame/posted-queue age buckets, stale consumer/worker rejection and fresh recovery; diagnostic work stays outside the final posting window | [Scheduling](../verification/trackpad-scheduling-timing.md); 400 injected stall/recovery cycles, final 659 functions / 1,860 executions |
| A → B → A must not revive buffered recognition/dequeued output; notifications and foreground sampling invalidate existing activity snapshots | [Foreground cancellation](../verification/trackpad-focus-cancellation.md); seven before-fix failures, final 666 functions / 1,870 executions on `a6471db` |

All reports retain exact commands, artifacts, failures/retries/warnings and limits. They distinguish injected software checks from user hardware reports; temporary artifacts are supplementary. The output target race cannot be eliminated by a public readback, so final runtime/session/ownership guards remain mandatory. Private touch acquisition stays Experimental; general native gesture suppression is not established. Configured corner/click replacement has its own later evidence.

## Next handoff

Prepare controlled busy-consumer physical timing/stress measurement on an identified current build. Use the existing opt-in aggregate diagnostics only within an authorized physical run; they measure queue/frame age, not finger-lift-to-visible-action latency. Preserve the confirmed scenarios and thresholds unless new evidence warrants a change. Do not start another engine or alter real rules/grants on the user's behalf.
