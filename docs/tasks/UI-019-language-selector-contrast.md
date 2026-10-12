# UI-019 — Distinct Language selector

- Updated: 2026-10-12.
- Stage: `awaiting_verification`.
- Owner: Unassigned; `/root` released native implementation 2026-10-12.
- Ownership checked: Started on `main` / `59f5754`; existing work was committed externally as `7921b98` during this session. Final native slice is uncommitted on `7921b98`; no agent commit.
- Owned surfaces: Opt-in distinct branch of EditorGlassSurface/EditorMenuSelector, LanguageSettingsView, three adaptive color assets and concise project records. Sketch was read-only; existing copy, behavior and unrelated work were preserved.
- Requirements: SPEC §§10–11; DESIGN compact glass control family.

## Outcome and acceptance

Make the Language selector visibly distinct from its raised Settings card while retaining the compact 24 pt geometry, native menu semantics and glass direction.

- [x] Refine the reusable source materials; preserve other control roles and copy.
- [x] Review Light/Dark, EN/RU/DE/FR and menu/error/reopen specimens live through MCP.
- [x] Save Sketch, update source/handoff records and run `git diff --check`.
- [x] Adopt the released surface in the shared native control without changing other selectors or the language activation contract.
- [x] Build, run existing language/layout regressions and review the Light native selector in an isolated no-engine fixture.
- [ ] Complete native Dark/menu/focus/VoiceOver and adaptive-preference acceptance on the named build.

## Evidence and next step

Rebind.sketch saved/reviewed **2026-10-12**, refreshed document ID `C7326969-08D8-4B1C-8899-AA9277A9763D`, SHA-256 `8e0b0c19b3a0cd736d89087a8507167edf97af36093047e109cc6a181c3c84fa`. The reusable compact Language materials now separate the selector from its raised card; Foundations 14 carries the scoped native annotation. Inspect those live sources directly for adoption.

Agent-observed MCP screenshots cover all eight Language frames (40–47) and Foundations 14, including Light/Dark, compact RU/DE/FR, the open menu, save failure and reopen feedback. Final source styles link their edge/shadow colors to Color Variables. Saved archive CRC passes; all 125 screen IDs/names/frames and Brand page content match the pre-save baseline. No routine image export or Git commit. Existing copy and native edits were preserved; no app build/runtime checks were run for this design-only change.

## Native adoption — 2026-10-12

The subsequent refinement is integrated on top of UI-017. Shared controls add an opt-in distinct surface; only Language enables it. Adaptive source surface/edge/shadow assets, native Clear glass and the opaque Reduce Transparency branch preserve 24 pt geometry, menu tracking/focus, translations and draft/apply/reopen behavior. Increase Contrast strengthens the edge independently of the system focus ring. Other compact/editor controls retain their defaults.

[Native evidence](../verification/language-selector-refinement.md): 12 functions / 49 expanded executions, 608 native viewports, final ordinary Debug/signature and scoped Light live review pass. Automated approval-service rate limits blocked further computer-use checks; Dark/menu/keyboard/VoiceOver/preferences and macOS 26/Intel remain open. No production configuration, permissions or input interception were changed.

Next: **Review the isolated Language fixture in Light/Dark; open the menu, cancel with Escape and verify focus.** Disabled/VoiceOver/adaptive checks remain separate. Identify a fresh production artifact before broader acceptance; concurrent UI-020 owns the profile-selector slice and can replace shared Debug output.
