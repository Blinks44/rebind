# UI-007 — Advanced settings and safe configuration management

- Updated: 2026-10-11.
- Stage: `in_progress`; design released, native Advanced implementation underway.
- Owner: `/root` native implementation, 2026-10-11; Sketch remains read-only.
- Baseline: `main` / `b453d8d` plus independent General implementation and existing design deliveries.
- Requirements: SPEC §§7, 9–11, 15.12; PLAN Phases 7–9.
- Ownership: new Advanced frames/components; existing shared style reuse only. Original screen IDs, Brand, app code and UI-003 records preserved.

## Outcome

Deliver Settings → Advanced in the current macOS 26 design system: existing opt-in safe mouse diagnostics, validated configuration import/export, explicit replacement/reset confirmation, protected-file and failure states, Light/Dark and compact EN/RU/DE/FR copy. Import/export/reset are design requirements, not current implementation claims.

## Acceptance

- [x] Inspected actual diagnostics/storage and live Sketch; reused Apple macOS 26 alerts, progress and buttons.
- [x] Completed overview, diagnostic, import/reset and protected/failure compositions.
- [x] Reviewed Light/Dark, RU/DE/FR 880×600 overview and translated diagnostic sizing; fixed German footer clipping and blocked-state guidance.
- [x] Saved and reviewed source; behavior and four-language copy are inside Sketch, ownership released. No routine exports or separate visual manual.

## Saved source and review

Open **Rebind.sketch** through MCP: Screens **48–69**, Foundations **05** (behavior/native/accessibility) and **06–10** (EN/RU/DE/FR copy), Symbols (paired Advanced action cards and diagnostic table row). Resolve the document afresh; [DESIGN](../DESIGN.md) is the short locator/current revision. All 22 new screen/state compositions were inspected through live screenshots after their relevant edits; original 47 screens and Brand remain intact. Final saved ZIP CRC, all 2,323 previous local IDs/47 screen rectangles, 2,896 unique final local IDs and unchanged Brand were checked. All 192 original localized copy values were found in the Sketch annotations before deleting their temporary JSON duplicate. The shape/Activation correction is recorded in UI-006.

Native file panels, alerts, focus rings and accessibility adaptations use macOS controls; their actual Dark/localized rendering and transitions require app verification. Mock counts/events are authored examples. No app build/runtime/real import/reset test or Git commit by this design task.

## Next

Native ownership: Advanced settings/model/file operations, scoped AppModel replacement and stale-editor guards, diagnostics presentation, String Catalog additions, behavioral/native layout tests and affected status/evidence records. Preserve existing General/Input/Language work and independent design edits. Required checks: atomic replacement/reset rollback, protected originals and destination aliases, cancellation/stale review, paused import, language activation, native sizing/panels/confirmation and accessibility review.

Implement Advanced from live Sketch using the completed UI-008 backup foundation and existing diagnostics/Language contracts; verify atomic replacement/reset, cancellation/protected originals, four languages and native accessibility. Next design package: Mouse rules and editor.
