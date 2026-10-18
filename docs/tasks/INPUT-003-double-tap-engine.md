# INPUT-003: Three/four-finger double tap engine and storage

- Updated: 2026-10-19 (manual evidence reconciliation; original software runs unchanged).
- Stage: `awaiting_verification`; engine/data and UI-014 editor released, hardware acceptance open.
- Owner: Unassigned; `/root` Swift agent released engine/data ownership on 2026-10-12.
- Ownership checked: `main` / `afb7411` plus INPUT-002 uncommitted engine/data changes; UI-013 is now saved/released; its Sketch and completion notes are independent work.
- Owned surfaces: Trackpad sequence/session/runtime/capture and short-contact centroid, typed trigger model, schema/migration, scoped trigger labels, tests and affected status/evidence sections. No editor layout, action catalog, Sketch or real configuration/permission edits.
- Requirements: SPEC §§3.4, 4, 6, 9, 12; PLAN Phase 5.
- Code baseline: `afb7411` plus INPUT-002; no agent commit.

## Outcome and acceptance

Connect three/four-finger double taps to guarded shortcut output. Reuse the pure sequence and existing contact/click guards. Two-finger doubles, clicks, corners, modifiers and broader actions remain separate slices.

- [x] Distinct configured single/double rules round-trip; historical schemas cannot carry new triggers.
- [x] A valid pair emits exactly one double, with no single fallback. A lone tap waits only if its double rule is configured.
- [x] Click/activity, movement, uncertainty/loss, focus/profile, lifecycle and late polling cancel safely and recover.
- [x] Targeted tests, all final regression tests (including the isolated timeout recheck) and Debug build pass; evidence and handoff recorded.
- [ ] Physical accuracy, latency, click exclusion and native gesture conflicts verified on an identified build/hardware.

## Mechanism decision

Preserve private acquisition and synchronous bounded callback. Sequence on the consumer using a snapshot of the existing system double-click interval. Retain in-memory origin centroid only, never configuration/diagnostics. Preliminary contact qualification can retain a pair before the 60 ms settling window; no action is eligible until settling completes. Reject uncertainty and avoid replaying an older single into a newly started contact. [Research and final evidence](../verification/double-tap-engine.md) record native alternatives, licensing/access limits and the conservative mismatch policy.

## Implementation and review

Distinct single/double identities, schema 26 migrations, runtime interval/rule snapshots, consumer sequence arbitration and guarded worker submission are implemented. Origin centroid remains transient and excluded from diagnostic Codable payloads. At the engine/data handoff the editor still created only four-finger single rules; [UI-014](UI-014-trackpad-presets.md) subsequently integrated all four preset identities and conflict guidance.

[Evidence](../verification/double-tap-engine.md): 86 targeted functions / 356 executions pass before the final interval guard. On final code, all 627 Swift Testing functions and 11 native XCTest functions pass in the full run; the remaining Settings matrix exceeds a 60 s command limit and passes its isolated 180 s recheck. Total covered: **639 functions / 1,801 executions**. No source changes between those final runs. Standalone Debug and strict/deep ad-hoc signature pass. Earlier interrupted About attempt and runtime warnings are recorded, not hidden or claimed as a clean full invocation.

Reviewed configured-only routing, lone/pair/third-tap arbitration, deadline exclusivity, receipt/poll separation, delayed-click and movement/loss cancellation/recovery, one-slot output, profile/focus invalidation, schema protection and four-language labels. The native classifier's duration/travel/placement limits, callback acquisition and worker sender remain preserved. Untimed nonzero frames now fail closed. No editor/Sketch/real configuration edits or agent commit. `git diff --check` passes.

## Current manual evidence — recorded 2026-10-19

Built-in three-finger double delivery is user-confirmed in checklist 3.1. Four-finger/external doubles, measured timing and full native/click exclusion are not established. The later shared-adapter artifact still needs affected regression. Source and artifact limits: [October 18 manual checklist](../verification/manual-test-2026-10-18.md). No build/test rerun; retain `awaiting_verification` for remaining acceptance.

## Next handoff

Verify four-finger and external double taps, first pair after idle and the built-in regression on a named current bundle. Preserve native coexistence/click safety and full UI-014 accessibility gates.
