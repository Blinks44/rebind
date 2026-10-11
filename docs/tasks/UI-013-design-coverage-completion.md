# UI-013 — Complete remaining product design coverage

- Updated: 2026-10-11.
- Stage: `in_design`.
- Owner: `/root` Sketch design agent.
- Ownership checked: 2026-10-11 / `main` `ed0b5d9`; active, clean checkout at start.
- Owned surfaces: new Trackpad/Magic Mouse, action-parameter/validation, profile/empty/search frames and their Sketch components/annotations; concise DESIGN/STATE/PLAN/task status. Preserve existing native code, Brand and released UI-011/UI-012 sources.
- Requirements: SPEC §§3.4–5, 8–11; PLAN Phase 8–9 design coverage.

## Outcome and acceptance

Complete the final planned product design in the established live Sketch direction. User clarification on 2026-10-11: release waits for the planned functionality, including Magic Mouse; temporary implementation limitations and four-finger-only placeholders do not belong in the target design. Remove or replace such visual specimens. Inspect SPEC's target contracts and actual implementation to identify work still required, without turning current implementation gaps into product screens. Sketch owns the visual states, four-language copy, interaction and accessibility annotations. Genuine permission, device, conflict and failure states remain part of the final product.

- [ ] Final Trackpad and Magic Mouse lists, one curated gesture selector per category, shared actions and genuine device/conflict/recovery states; remove touch trigger recorders, separate gesture parameters and temporary capability placeholders.
- [ ] Action parameters, loading/empty/failed/missing/invalid/unavailable states and recovery.
- [ ] Profile creation/copy/rename/delete/limits/failures and category empty/search states.
- [ ] Cross-screen Light/Dark/localization/accessibility review; saved source and preservation checks.
- [ ] Concise current-source/readiness records and `git diff --check`.

## Source and limits

2026-10-11 preset clarification: replace the initial touch gesture-builder compositions with complete preset selection. Keyboard/conventional mouse input recording and output-shortcut recording remain. Updated SPEC §§3.4–4, AGENTS and the project-local swiftui-design-principles skill; no native app source changes are part of this task.

Starting source: Rebind.sketch saved 2026-10-11, 89 screen/state frames, Foundations 14–15. Document ID is a lookup hint and must be refreshed. Native implementation/runtime/hardware acceptance is separate; this task does not add input mechanisms or execute actions.

## Next step

Complete and review the new live states, save Sketch, then release the ready design for native adoption through MCP.
