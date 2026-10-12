# UI-017 — Settings navigation and language control adoption

- Updated: 2026-10-12.
- Stage: `awaiting_verification`; bounded navigation/Language adoption integrated.
- Owner: Unassigned; `/root` released the bounded implementation on 2026-10-12.
- Ownership checked: `main` / `59f5754` plus preserved uncommitted editor/design work, 2026-10-12.
- Owned surfaces: Settings shell/navigation, scoped shared menu sizing, Language selector/feedback, affected native layout evidence/status. No Sketch, engine, login behavior or configuration contract changes.
- Requirements: SPEC §§10–11; PLAN Phase 8; released UI-011/UI-012/UI-015.

## Outcome

Continue native adoption while Magic Mouse hardware is unavailable until the next day. Implement the released inset glass Settings track and compact Language menu using the existing section/draft/save/reopen models. Preserve full-main minimum-size repair, localization and accessible selected/disabled controls. Other Settings body/recovery styling and main/profile materials remain separate.

## Acceptance

- [x] Inspect live Light/Dark Settings controls and feedback directly in Sketch.
- [x] Stable 35 pt track/27 pt tabs with 4 pt inset and narrow localized fallback; compact 24 pt Language selector and existing draft/apply semantics.
- [x] Native full-main/standalone four-language bounds and existing language/storage regressions; Debug/signature checks.
- [x] Scoped no-engine live navigation/selection review; record accessibility/adaptive/minimum-OS limits and user checks.
- [x] Evidence/task/STATE/history and affected-link/diff review; release ownership.

## Next step

[Evidence](../verification/settings-control-adoption.md): 29 functions / 89 runs, 544 native viewports, final Debug/signature pass. Isolated live five-section navigation, Light/Dark/German compact, language draft discard/apply/failure and menu Escape/Down/Return/focus checks pass. Current artifact hashes and commands are in the evidence. Full tab/activation focus, VoiceOver/adaptive preferences, minimum-OS and actual production language relaunch remain open. No engine/schema/translation/Sketch change or agent commit.

Next user check: named ordinary build, all Settings sections/resizing, Language menu cancellation and focused keyboard selection, plus prior editor activation/popups. Next implementation: remaining Settings feedback/recovery and main/profile navigation from live Sketch. Magic Mouse is explicitly deferred until hardware is available; no probe/source/dependency was added before the user redirected the task.

Shared follow-up: [UI-016 shared-component fidelity correction](../verification/editor-design-adoption.md#shared-components-and-sketch-fidelity--2026-10-12) updates Settings tracks/menus too. Current combined checks and artifact supersede this task's initial material/restoration evidence; full native keyboard/accessibility acceptance stays open.
