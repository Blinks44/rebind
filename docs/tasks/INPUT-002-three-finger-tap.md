# INPUT-002: Three-finger single tap engine and storage

- Updated: 2026-10-12.
- Stage: `awaiting_verification`; engine/data and UI-014 editor released, native/hardware acceptance open.
- Owner: Unassigned; `/root` Swift implementation agent released engine/data ownership on 2026-10-11.
- Ownership checked: `main` / `afb7411`, clean checkout at start. UI-013 remains owned by the separate Sketch design agent.
- Owned surfaces: Trackpad engine/session/gate, InputTrigger and single-tap model, configuration schema/migration, touch diagnostic exclusion, their tests, one trigger display label with EN/RU/DE/FR translations, this task and scoped evidence/status sections. No editor layout/preset selector, shared action catalog, Sketch or real configuration edits.
- Requirements: SPEC §§3.4, 4, 6, 9, 12; PLAN Phase 5.
- Code baseline: `afb7411`; no agent commit.

## Outcome and scope

Connect qualified three-finger single taps to the existing guarded PID-targeted shortcut worker, independently of four-finger rules. Persist distinct triggers without changing existing rules; keep capture, click settling, overflow, focus/activity/revision and protected-session guards. The original engine/data handoff preceded the preset design release; UI-014 subsequently connected preset editing and conditional conflict guidance. Do not enable real rules or imply hardware verification.

## Acceptance

- [x] Three/four taps resolve only their configured shortcut; absent, disabled and inactive-profile rules never fall back to another tap.
- [x] Click/activity, profile/focus, stale/malformed/lost frames and delayed output cancel safely; fresh taps recover with no duplicate output.
- [x] Versioned round-trip and legacy migration preserve selection, pause, preferences and old rules; historical schemas reject a new trigger payload.
- [x] Targeted tests, full regression and Debug build pass; limitations and next step recorded.
- [ ] Native three-finger accuracy/latency/click exclusion and Look Up coexistence verified on identified hardware before release support.

## Research and decisions

[Refreshed research/evidence](../verification/three-finger-tap-engine.md) records native alternatives, OpenMultitouchSupport audit and unavailable SPI/current-SHA access. Reuse the existing private acquisition adapter and short-contact recognizer; no new library or upstream code. Three-finger Look Up reservations require native acceptance and clear preset UX. No suppression or external-trackpad claim.

## Implementation and review

Typed per-preset routing, qualified native session handoff and schema 25 are implemented. [Final evidence](../verification/three-finger-tap-engine.md): **48 targeted functions / 183 executions** and **614 full-suite functions / 1,649 executions**, zero failures/skips; standalone Debug build and strict/deep local signature pass. Existing About native-fixture QoS warning remains. Final binary digest is recorded in the evidence; baseline `afb7411` plus owned uncommitted source/tests, no agent commit.

Reviewed cancellation, one-slot/no-fallback output, profile/configuration invalidation, migration protection and four-finger regressions. Callback acquisition, worker sender, permissions, thresholds, editor layout and Sketch were preserved by this engine slice. No claim of physical three-finger verification; the subsequent editor/help reconciliation is recorded in UI-014. `git diff --check` passes.

## Next handoff

[UI-014](UI-014-trackpad-presets.md) subsequently integrated the four supported single/double preset identities and conflict guidance from released UI-013. Perform a user-led physical three/four tap comparison and native Look Up coexistence check on a named build. INPUT-001's existing confirmed subsets and open gates remain separate; full editor accessibility/material acceptance stays in UI-014.
