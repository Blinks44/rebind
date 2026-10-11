# UI-012 — Semantic feedback and state accents

- Updated: 2026-10-11.
- Stage: `ready_for_implementation`.
- Owner: Unassigned; bounded design ownership released 2026-10-11.
- Owned surfaces: shared feedback/status sources, semantic state styles, existing feedback instances and relevant Sketch Foundations. Preserve Brand, glass-control geometry, native implementation and all product behavior/copy.
- Requirements: SPEC §§10–11; PLAN Phase 8 functional states and accessibility.
- Baseline: `main` / `8daa97b` and saved UI-011 Sketch revision at start. External HEAD advanced to `9253799` during work; independent native/Trackpad work preserved. No app code changes or agent Git commit by this task.

## Outcome

Make errors, warnings, success and informational/progress states recognizable through consistent surface, icon and text hierarchy. Apply to current feedback screens and keep the reusable contract in live Sketch for further design. Existing state coverage and semantic colors do not yet provide consistent visual emphasis.

## Checks

- [x] Inspect live sources and current error/recovery/success states; reuse semantic variables and native iconography.
- [x] Refine shared feedback and apply correct severity to existing states without changing behavior or translations.
- [x] Review Light/Dark, compact/localized layouts and color-independent recognition; save Sketch and verify preservation.
- [x] Update concise source/status records, links and `git diff --check`.

## Saved source and review

Rebind.sketch saved/reviewed 2026-10-11: document ID `A610E1D4-B7CF-4D5D-9357-1292E3177726`, SHA-256 `fa4897163d679b783e139ef2ffc5c98a749e6c53a2f0efb7c9ceeb85c4349a46`. Resolve IDs freshly. Foundations **15 · Feedback / Semantic states & accessibility** owns the reusable Light/Dark examples and future-state rules; shared Inline sources and semantic surface styles remain live.

Applied severity to current editor save/conflict/unavailable feedback, permission recovery/setup/status, login failures/approval, runtime-start recovery, Language feedback, Advanced failure/completion/validation and diagnostic status. Neutral/help/paused states remain calm. Product behavior and existing text are unchanged.

Live MCP screenshots reviewed the shared Light/Dark samples, affected errors/warnings/success/info, compact German layouts and neutral controls. Opaque sample-token calculations: title contrast ≥11.4:1, body ≥5.7:1, icons ≥4.4:1; standalone Light error text strengthened to 6.0:1 against the canvas. These calculations do not certify native adaptive accessibility. All 15 Mouse editor footer gaps remain positive (19–101 pt).

Save callback and archive CRC pass. Every baseline layer ID and existing text remains; all 89 screen IDs/names/bounds and Brand page JSON match the saved baseline. No app build/runtime, real configuration/grant changes, routine exports or agent commit. Links/status and `git diff --check` reviewed.

## References and next step

Apple HIG [Color](https://developer.apple.com/design/human-interface-guidelines/color), [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback) and [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility): consistent semantic use, proportionate interruption and more than color alone. Native adaptive materials, contrast, focus and VoiceOver require separate verification.

Next design: apply Foundations 15 to subsequent Trackpad/Magic Mouse, profile and action-validation states. Next implementation: adopt the saved feedback surfaces/icons in the native app from live Sketch; verify focus/VoiceOver, adaptive appearance and four-language reflow. Earlier native checks predate this revision.
