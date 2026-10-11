# UI-009 — Mouse rules and conditional trigger editor

- Updated: 2026-10-11.
- Stage: `in_design`.
- Owner: `/root` design, 2026-10-11.
- Ownership checked: live Rebind.sketch through MCP; new Mouse screens/components/annotations only. UI-007 native ownership and existing code edits remain independent.
- Owned surfaces: new Sketch Mouse compositions; this task, affected DESIGN/STATE/history pointers. Existing symbols/styles reused without modifying their sources.
- Requirements: SPEC §§2, 3.2–3.3, 4, 10–11; M1/M2/R1; PLAN Phases 2, 8–9.
- Code baseline: `main` / `bf36465`; unrelated AdvancedSettingsView/AdvancedConfirmationAlert edits preserved.

## Outcome and scope

Design category-wide Mouse rules and a focused editor for recorded numeric middle/additional buttons, discrete wheel and four cardinal button-held pointer gestures. Preserve manual profiles, exact primary modifiers, existing Press/Double Press/Hold behavior and per-rule hold duration. No physical-device inventory, typed button codes, primary/secondary capture claim, smooth-wheel support or new gesture mechanism.

## Acceptance

- [ ] Populated/empty Mouse list, Light/Dark and compact/localized review.
- [ ] Button/wheel/pointer editor with applicable activation, recording/cancel/retry, unavailable/conflict/failure states.
- [ ] Self-contained Sketch behavior/accessibility and EN/RU/DE/FR copy annotations; live screenshot review and actual save.
- [ ] Concise task/STATE/DESIGN/history handoff and `git diff --check`.

## Source and verification

Rebind.sketch, original 69 screen/state frames inspected in Sketch 2026.3.1 / public API 2.0.0. New work is independent of native Advanced integration. Authored examples do not establish hardware support. No app runtime, recording, remapping or permission changes are authorized by this design scope.

## Next

Complete the bounded Mouse package and release it for implementation from live Sketch. Native input safety/timing, accessibility and localization acceptance remain separate.
