# UI-011 — Consistent glass controls

- Updated: 2026-10-11.
- Stage: `ready_for_implementation`.
- Owner: Unassigned; bounded design ownership released.
- Ownership checked: live Rebind.sketch and current task records, 2026-10-11.
- Owned surfaces: shared selector, activation and Settings navigation materials; affected editor layouts; Sketch Foundations annotations and concise repository handoff. Brand and native About work are preserved.
- Requirements: SPEC §§10–11; PLAN Phase 8. Control material/spacing refinement does not change behavior.
- Code baseline: `main` / `8daa97b`; existing uncommitted native About and earlier design records preserved. No app code changes.

## Outcome and scope

Unify form selectors, segmented activation and Settings tabs into a purposeful Light/Dark Liquid Glass control family. Improve editor spacing while retaining readable raised capture/content surfaces, native interaction semantics and four-language copy. This explicitly revises the earlier flat Medium popup direction in UI-006/UI-009.

## Acceptance

- [x] Shared selection family applied to existing screens; editor controls align and have sufficient space.
- [x] Live Light/Dark, activation states, Settings navigation and compact/localized review.
- [x] Self-contained Sketch annotations, successful save, preserved unrelated source and concise handoff.
- [x] Repository links/status and `git diff --check`.

## Saved source and review

Rebind.sketch saved/reviewed on 2026-10-11: document ID `CE76D2BF-CBDD-4ACF-9F21-E64B28B46305`, SHA-256 `8db83ccdb486a40c9f1f05c2bbf44a1d794e1aa215d58cb87b9b80cc281e7505`. Resolve IDs freshly. Foundations **14 · Controls / Glass family & native states** owns the current material/spacing/state contract; Foundations 04/11 were reconciled. Existing shared action/activation/secondary controls, 41 Settings tab tracks, compact Language selectors and Mouse editors are released.

Live MCP screenshot review covered Light/Dark, Press/Hold, Mouse recording/error/empty and EN/RU/DE/FR editor states, Keyboard editors and compact/localized Settings. Removed stacked Light/Dark action materials, retained selected tabs/localized labels and corrected the dense unavailable-screen footer gap. All 15 Mouse editors keep positive form/footer separation; all 41 Settings tracks share the revised geometry/material roles.

Save callback succeeded; ZIP CRC passes, all baseline layer IDs remain, 89 screen names/IDs remain and Brand page JSON matches the baseline. Mouse editor heights/canvas positions intentionally changed; Screens 01–74 bounds remain. No routine exports, app code/build/runtime, configuration or permission changes and no Git commit by this task. Independent native Mouse/About work remains preserved. Repository links/status and `git diff --check` reviewed.

## Next

Implementation: adopt the saved shared glass controls and editor spacing from live Sketch, including the integrated Mouse implementation. This revision supersedes the earlier flat Medium-popup treatment; earlier native screenshots do not verify these revised materials. Preserve native semantics, pinned actions and the full-main sizing repair. Native focus/VoiceOver, adaptive materials and four-language resizing remain open.

Design: continue Trackpad/Magic Mouse coverage within actual acquisition/support limits.
