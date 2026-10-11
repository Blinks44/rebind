# UI-012 — Semantic feedback and state accents

- Updated: 2026-10-11.
- Stage: `in_design`.
- Owner: Current Sketch design agent; bounded ownership claimed 2026-10-11.
- Owned surfaces: shared feedback/status sources, semantic state styles, existing feedback instances and relevant Sketch Foundations. Preserve Brand, glass-control geometry, native implementation and all product behavior/copy.
- Requirements: SPEC §§10–11; PLAN Phase 8 functional states and accessibility.
- Baseline: `main` / `8daa97b` plus independent uncommitted native About/Mouse work; saved UI-011 Sketch revision.

## Outcome

Make errors, warnings, success and informational/progress states recognizable through consistent surface, icon and text hierarchy. Apply to current feedback screens and keep the reusable contract in live Sketch for further design. Existing state coverage and semantic colors do not yet provide consistent visual emphasis.

## Checks

- [ ] Inspect live sources and current error/recovery/success states; reuse semantic variables and native iconography.
- [ ] Refine shared feedback and apply correct severity to existing states without changing behavior or translations.
- [ ] Review Light/Dark, compact/localized layouts and color-independent recognition; save Sketch and verify preservation.
- [ ] Update concise source/status records, links and `git diff --check`.

## References and next step

Apple HIG [Color](https://developer.apple.com/design/human-interface-guidelines/color), [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback) and [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility): consistent semantic use, proportionate interruption and more than color alone. Native adaptive materials, contrast, focus and VoiceOver require separate verification.

Next: refine the existing reusable feedback sources and review the resulting screens live.
