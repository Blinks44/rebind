# UI-006 — macOS materials and control consistency

- Updated: 2026-10-11.
- Stage: `done`; bounded Sketch review/polish only, native adoption separate.
- Owner: Unassigned; `/root` saved, reviewed and released the scope.
- Baseline: `main` / `b453d8d` plus preserved independent native changes; no agent commit.
- Requirements: SPEC §§10–11, DESIGN; PLAN Phase 8.

## Saved result and review

Reviewed recent Settings and representative navigation/editor/permissions compositions. Restored native Apple glass profile controls, added shared elevated opaque cards, matched Light/Dark popup/capture/menu geometry and corrected Dark section/compact spacing. Final polish removes Activation's two decorative separators in both shared theme sources and documents Apple's control-size shape families in Sketch Foundations.

Live source/date and ready scopes: [DESIGN](../DESIGN.md). [Review and dated compile-only evidence](../verification/material-design-review.md) distinguish Sketch checks from native behavior. Source saved 2026-10-11; all 2,323 original local nodes, all 47 prior screen rectangles and Brand preserved; final ZIP CRC passes. No app source/build/runtime/real configuration change or Git commit by this follow-up.

## Next

Native agent: inspect current Sketch and adopt reviewed materials/shape treatment while preserving full-main sizing; verify actual accessibility and appearance. Design agent: Advanced is ready in UI-007; continue Mouse rules and editor.
