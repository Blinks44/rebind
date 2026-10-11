# UI-013 — Complete remaining product design coverage

- Updated: 2026-10-12.
- Stage: `ready_for_implementation`.
- Owner: Unassigned; `/root` design and scoped corrections saved/released.
- Ownership checked: 2026-10-11 / `main` `ed0b5d9`; active, clean checkout at start.
- Owned surfaces: new Trackpad/Magic Mouse, action-parameter/validation, profile/empty/search frames and their Sketch components/annotations; concise DESIGN/STATE/PLAN/task status. Preserve existing native code, Brand and released UI-011/UI-012 sources.
- Requirements: SPEC §§3.4–5, 8–11; PLAN Phase 8–9 design coverage.
- Follow-up ownership: 2026-10-12 / `main` `afb7411`; compact new touch/editor canvas rows and correct shared keycap/chord alignment, preserving concurrent native input work.

## Outcome and acceptance

Complete the final planned product design in the established live Sketch direction. User clarification on 2026-10-11: release waits for the planned functionality, including Magic Mouse; temporary implementation limitations and four-finger-only placeholders do not belong in the target design. Remove or replace such visual specimens. Inspect SPEC's target contracts and actual implementation to identify work still required, without turning current implementation gaps into product screens. Sketch owns the visual states, four-language copy, interaction and accessibility annotations. Genuine permission, device, conflict and failure states remain part of the final product.

- [x] Final Trackpad and Magic Mouse lists, one curated gesture selector per category, shared actions and genuine device/conflict/recovery states; remove touch trigger recorders, separate gesture parameters and temporary capability placeholders.
- [x] Action parameters, loading/empty/failed/missing/invalid/unavailable states and recovery.
- [x] Profile creation/copy/rename/delete/limits/failures and category empty/search states.
- [x] Cross-screen Light/Dark/localization/accessibility design review; saved source and preservation checks. Native accessibility acceptance remains separate.
- [x] Concise current-source/readiness records and `git diff --check`.

## Source and limits

2026-10-11 preset clarification: replace the initial touch gesture-builder compositions with complete preset selection. Keyboard/conventional mouse input recording and output-shortcut recording remain. Updated SPEC §§3.4–4, AGENTS and the project-local swiftui-design-principles skill; no native app source changes are part of this task.

Starting source: Rebind.sketch saved 2026-10-11, 89 screen/state frames, Foundations 14–15. Document ID is a lookup hint and must be refreshed. Native implementation/runtime/hardware acceptance is separate; this task does not add input mechanisms or execute actions.

## Saved result and verification

Rebind.sketch saved/reviewed through live MCP, latest correction **2026-10-12**: **125 screen/state frames**, Foundations **16–22**, document ID `4B31A177-0924-4510-AC9B-D71EB9C06470`, SHA-256 `5250db199656efb0cba7757cde50758c5fd85ad361dbbb3483dbf5d098a4e3c8`. The source contains complete touch preset menus, shared action forms/catalog/recovery, profile management, category empty/search states, Dark and localized editor specimens, EN/RU/DE/FR copy and native interaction/accessibility annotations. Initial touch recording specimen 98 was removed; output recording remains independent.

Live screenshot review covered the new compositions, paired severity/material states, localized editors and Input revisions. Fixed clipped Magic Mouse headings, empty-name field content, destructive-alert treatment and missing action translation columns. Saved archive CRC passes; all 89 baseline screen IDs/names/bounds remain and Brand is unchanged. Temporary implementation/Experimental product copy was replaced in screens, component specimens and source defaults. Required device/conflict/permission/runtime states remain.

Project-local design skill override and manifest were reviewed; JSON parses and frontmatter is unchanged. The skill-creator validator could not run because the local Python environment lacks `yaml` (`ModuleNotFoundError`); no dependency was installed. Documentation links/status were reviewed and `git diff --check` passes. No app code/build/runtime/hardware checks, routine exports or agent Git commit. External commit `afb7411` captured the earlier in-progress instruction/task changes; the saved Sketch and completion notes are separate artifacts.

Native adoption must inspect the current source through MCP. VoiceOver, keyboard traversal, adaptive materials, actual four-language reflow, permissions, gesture coexistence and hardware execution remain native acceptance gates; design specimens do not certify them.

2026-10-12 follow-up: closed the deleted-frame canvas gap, packed editors into three full rows and moved subsequent sections upward (28 frame positions changed). Centered the reusable character keycap and chord separator; explicit Dark source overrides preserve the same alignment. Live Light/Dark, Mouse/touch, conflict and RU/DE/FR screenshots plus the Sketch canvas confirm the correction. Geometry checks find no new-section overlaps. Saved CRC passes; all 125 frame IDs/names/sizes remain, other pages and Brand are unchanged. No additional planned design package remains; next work is native adoption/review.

## Next step

Implement the prepared final interface from live Sketch, including the shared glass/feedback revisions and curated touch selectors; preserve existing engine/storage work and verify native behavior on identified builds.
