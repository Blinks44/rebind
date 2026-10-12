# UI-019 — Distinct Language selector

- Updated: 2026-10-12.
- Stage: `ready_for_implementation`.
- Owner: Unassigned; `/root` saved/reviewed and released the bounded design edit.
- Ownership checked: `main` / `59f5754`, live Rebind.sketch. Preserve existing native changes and UI-018 copy work.
- Owned surfaces: Light/Dark compact Language selector shared materials and scoped Foundations 14 control annotation; concise task/STATE/DESIGN/history notes. Existing labels and translation overrides are preserved.
- Requirements: SPEC §§10–11; DESIGN compact glass control family.

## Outcome and acceptance

Make the Language selector visibly distinct from its raised Settings card while retaining the compact 24 pt geometry, native menu semantics and glass direction.

- [x] Refine the reusable source materials; preserve other control roles and copy.
- [x] Review Light/Dark, EN/RU/DE/FR and menu/error/reopen specimens live through MCP.
- [x] Save Sketch, update source/handoff records and run `git diff --check`.

## Evidence and next step

Rebind.sketch saved/reviewed **2026-10-12**, refreshed document ID `C7326969-08D8-4B1C-8899-AA9277A9763D`, SHA-256 `8e0b0c19b3a0cd736d89087a8507167edf97af36093047e109cc6a181c3c84fa`. The reusable compact Language materials now separate the selector from its raised card; Foundations 14 carries the scoped native annotation. Inspect those live sources directly for adoption.

Agent-observed MCP screenshots cover all eight Language frames (40–47) and Foundations 14, including Light/Dark, compact RU/DE/FR, the open menu, save failure and reopen feedback. Final source styles link their edge/shadow colors to Color Variables. Saved archive CRC passes; all 125 screen IDs/names/frames and Brand page content match the pre-save baseline. No routine image export or Git commit. Existing copy and native edits were preserved; no app build/runtime checks were run for this design-only change.

Existing Language implementation is integrated under UI-017; it still needs this subsequent design refinement. Native adoption and adaptive/focus/VoiceOver acceptance remain separate. Next: **Implement the refined Language selector from live Sketch**, scoped to compact Language controls.
