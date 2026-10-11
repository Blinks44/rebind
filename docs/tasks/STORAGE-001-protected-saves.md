# STORAGE-001 — Preserve files changed after launch

- Updated: 2026-10-11.
- Stage: `done`; bounded persistence/software-restoration acceptance only.
- Owner: Unassigned; `/root` released engineering-only ownership on 2026-10-11.
- Owned surfaces: ConfigurationStore, scoped AppModel persistence/error handling, persistence/model tests, isolated Advanced/Main native layout fixtures and this evidence. Existing input safety and independent Sketch work are preserved.
- Requirements: SPEC §§3.3, 9, 12, 15.12; PLAN Phases 3, 7, 10.
- Code baseline: `ed0b5d9`; clean at startup. No Sketch or app visual changes.

## Outcome and scope

Ordinary saves must reject a configuration file that becomes corrupt, incompatible or oversized after the app has loaded a healthy snapshot. Preserve original bytes and the prior selection/rules/queued output on failure; allow immediate in-memory Pause. Keep recoverable filesystem write failures retryable. Reuse the current bounded codec and atomic write, with no new schema/dependency/capture mechanism.

Also exercise the existing export → reset → import → explicit resume path against temporary authored profiles and the real matcher, without a global tap or native output. Full native/hardware acceptance stays separate in UI-007 and the profiles walkthrough.

## Acceptance

- [x] Before-fix tests reproduce the ordinary-save overwrite.
- [x] Direct store saves and profile/rule/language paths preserve corrupt/future/oversized originals and lock editing with existing recovery semantics.
- [x] Filesystem retry and deliberate Pause preserve their existing behavior.
- [x] Restored profiles/rules are paused until resume, then select and match the restored actions; held source ownership and old pending output remain safe.
- [x] Relevant tests/build, scoped evidence, STATE and history updated; unresolved hardware checks retained.

## Verification

[Evidence](../verification/protected-saves-and-restoration.md): before-fix corrupt/future/oversized regressions fail; targeted 45 functions / 152 executions pass. Final full suite **596 functions / 1,544 executions**, zero failures/skips; Debug build/local signature pass. Native layout fixtures now isolate deliberately protected files per state. Initial XCTest reporting stall and failed fixture run are recorded; the known About QoS warning remains. No production engine, real rules/grants/login or native output changed; no agent commit. Baseline `ed0b5d9` plus the owned uncommitted files above.

## Next

2026-10-11 [user follow-up](../verification/profiles.md#user-switching-follow-up--2026-10-11) confirms distinct Button 4 output and no old action during the requested switch scenario; activation, individual routes and build identity were not restated. The subsequent restart check confirms selection/rules/pause persistence, with build/OS/restart method not restated. A further user report confirms the backup-restoration happy path; exact sequence/artifact not restated. Next check Advanced keyboard/focus/VoiceOver in UI-007; detailed restoration, actual login launch and broader cancellation/routes remain separate.
