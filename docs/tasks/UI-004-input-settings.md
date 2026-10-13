# UI-004 — Input settings and per-binding hold timing

- Updated: 2026-10-12.
- Stage: `awaiting_verification`; native integration/software/layout/live save-retry pass; hardware/accessibility acceptance open.
- Owner: Unassigned; `/root` released bounded Input material/copy adoption on 2026-10-12. Sketch read-only.
- Ownership checked: 2026-10-11, `main` / `acce2f4`; prior design owners released, concurrent trackpad engineering and UI-001 native implementation preserved.
- Owned surfaces: native InputSettingsView/HoldDurationRow/BindingEditor, tests and scoped catalog integration; shared Settings/task/evidence/index updates with UI-005. Saved Sketch sources remain historical design deliverables.
- Requirements: SPEC §§3.1–3.4, 10–11; PLAN Phases 7–9.
- Code baseline: design delivery used `acce2f4`; native implementation uses `main` / `b453d8d` plus preserved General/permission work. Refinements/evidence uncommitted; no agent commit.

## Outcome and scope

Implement Settings → Input as an honest overview of existing timing: per-binding hold duration, system double-press interval and fixed pointer recognition. Add a focused hold-editor composition using the existing 100–5,000 ms range and 100 ms step. Current experimental Trackpad copy describes the built-in three/four-finger single/double tap → shortcut pool and retained native gestures. No global threshold override or unsupported recorder is introduced.

## Acceptance

- [x] Saved Input Light/Dark and compact EN/RU/DE/FR layouts.
- [x] Saved hold-editor layout, reusable sources, four-language copy and scoped behavior contracts.
- [x] MCP screenshot review, representative resize/restoration and saved-document preservation checks.
- [x] Task/evidence, DESIGN/STATE/index/history updated; native implementation acceptance kept separate.

## Saved design and verification

Current visual revision: materials/alignment review, saved 2026-10-11. Shared Input card/profile/sidebar materials and Dark section controls supersede affected original exports below; behavior/copy contracts remain valid.

`Rebind.sketch`, saved 2026-10-11, document ID `E50CA3D9-82B1-44C0-AC97-39F1A9663700` (resolve again). SHA-256 `9d37daa77514e03e0160141ea7dec33c2e234d32973596bd01e96ba33758f774`.

[Delivery](../verification/input-settings.md) owns seven frames (33–39), four new sources in live Sketch, behavior/native acceptance and 18-key four-language copy. Input is screenshot-reviewed in EN/RU/DE/FR and Light/Dark; hold/editor failure layouts are reviewed in English, with translated rendered acceptance remaining native work. Three-frame resize restoration matches all 96 local screen-node frames; saved ZIP comparison preserves all 1,838 original local nodes and adds 209. Fifteen outbound routes valid. No app source change, new build/runtime/hardware check or Git commit.

Existing per-binding duration, macOS double-click interval and fixed recognition remain the behavior source. Global adjustable gesture thresholds are not introduced; remaining advanced tuning does not become complete through this bounded overview. Native accessibility, save transitions, editor locales/Dark and physical input acceptance remain open.

## Native integration and acceptance

Input overview/Hold row integrated with existing engine/Stepper/storage constraints. All 18 four-language keys integrated; one scoped heading alias preserves category capitalization. Full suite: **539 Swift Testing + five XCTest tests, 544 total / zero failures**. Full Settings geometry now covers 352 combinations; standard Settings/failure/editor coverage also passes. Live French 575 → 675 ms, storage failure/draft retention/retry/file readback and Russian Dark/compact settings navigation checked. [Native artifacts, commands and limits](../verification/input-language-native.md).

Actual keyboard/mouse timing/cancellation, full keyboard/focus/spoken VoiceOver/accessibility preferences and remaining editor appearance/error states remain open. Layout/AX/software evidence does not certify hardware accuracy. Current material adoption is separate.

## Next handoff

2026-10-12 Input material/copy adoption is complete: raised shared cards/adaptive headings, nine scoped EN/RU/DE/FR entries and accurate current tap-preset guidance. Live Sketch shared sources/states inspected; English Light/Dark components and compact German full-main reviewed. Final **20 functions / 74 executions**, **608 native viewports**, Debug/signature pass. Implementation committed externally in `2bc4b97`; no agent commit. Existing Advanced/Trackpad work preserved. Hardware, spoken VoiceOver/focus/system preferences and macOS 26/Intel remain open.

- **Verification:** check actual Hold timing/cancellation and complete native accessibility/editor acceptance on the identified bundle. Preserve full-main coverage when adopting materials or adding Advanced; global tuning remains separate.
- **Implementation:** continue remaining main/profile/action materials and reviewed copy from live Sketch using existing components. Preserve the delivered Settings surfaces and capability limits.
- User-facing handoff name: **Input settings and per-binding hold timing**. No task ID or previous chat is required to continue verification.
