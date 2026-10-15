# UI-009: Mouse rules and conditional trigger editor

- Updated: 2026-10-16 (documentation reconciliation; dated checks unchanged).
- Stage: `awaiting_verification`.
- Owner: Unassigned; bounded native implementation released 2026-10-11 on `main` / `8daa97b` plus the scoped uncommitted changes below.
- Ownership checked: live Rebind.sketch through MCP and current task records. Independent About implementation and UI-011 shared-material design preserved.
- Owned surfaces: Mouse detail/list, conditional editor and capture draft, validation, associated tests/catalog and scoped evidence pointers. Sketch/shared sources were read only during implementation.
- Requirements: SPEC §§2, 3.2–3.3, 4, 10–11; M1/M2/R1; PLAN Phases 2, 8–9.
- Code baseline: `main` / `bf36465` at design start; external HEAD advanced to `8daa97b` during work. Design phase made no app source edits or Git commit; native changes are recorded below.

## Outcome and scope

Design category-wide Mouse rules and a focused editor for recorded numeric middle/additional buttons, discrete wheel and four cardinal button-held pointer gestures. Preserve manual profiles, exact primary modifiers, existing Press/Double Press/Hold behavior and per-rule hold duration. Rules remain category-wide; device inventory and phase-less continuous wheel handling were added separately under DEVICE-001/002/003. Primary/secondary capture and typed button codes remain outside the trigger contract.

## Design acceptance

- [x] Populated/empty Mouse list, Light/Dark and compact/localized review.
- [x] Button/wheel/pointer editor with applicable activation, recording/cancel/retry, unavailable/conflict/failure states.
- [x] Self-contained Sketch behavior/accessibility and EN/RU/DE/FR copy annotations; live screenshot review and actual save.
- [x] Concise task/STATE/DESIGN/history handoff and `git diff --check`.

## Source and verification

The former Rebind.sketch Mouse delivery was saved/reviewed 2026-10-11 (SHA-256 `54ef795e2e9f349d7ec685012217fbea75f4b9b0286892922e8a7c1d1faa4889`). Twenty new list/editor states were reviewed through MCP, including compact/localized variants; 69 baseline screen IDs/names/bounds were retained. Activation overrides, Dark contrast and wrapping were repaired. This design slice did not test capture/hardware/native accessibility. Its frame/component inventory and visual materials are superseded by [DESIGN](../DESIGN.md) and [UI-023](UI-023-main-window-soft-adoption.md); read the current live source for a visual change.

## Native implementation: 2026-10-11

Implemented category-wide selected-profile Mouse list/search, per-rule enabled state, edit/delete, empty/no-results feedback, permission recovery and diagnostics. The editor separates trigger/output capture; button activation/Hold, discrete wheel and cardinal pointer direction show only applicable controls. Type changes reset trigger options while retaining the action. Existing identity/enabled state and unrestricted numeric button indexes are retained. Only the editor's exact recording request can update its draft; cancelled/stale/wrong-type results retain values. Save uses shared configuration validation, displays conflicts, and retains the draft after storage failure. Nested permission recovery preserves unsaved edits. Secure Input/suspended/stopped capture is unavailable; global pause alone permits recording.

Live Screens 70/75/77/79 and Foundations 11–13 were inspected through MCP before implementation. No new capture/action mechanism or dependency: existing synchronous tap/recorder/matcher and persistence remain. The earlier glass-control revision was later superseded by the integrated soft design system (UI-023). The dated native checks below establish their original functionality/layout scope; full current appearance/accessibility acceptance remains open.

- [x] Mouse list and conditional editor implementation with EN/RU/DE/FR copy.
- [x] Draft ownership/type-reset/conflict/profile/numeric-button/search and capture availability software checks.
- [x] Four-language Light/Dark native size matrices and bounded live editor/type-switch review.
- [ ] Real capture, Escape/cancellation/retry, storage-failure UI, timing/release/safety acceptance on identified hardware.
- [ ] Full keyboard/VoiceOver, production-language contexts and accessibility materials.
- [x] Original glass-material adoption superseded by whole-app soft-system integration in UI-023; complete native appearance/accessibility acceptance remains open.

Checks, exact final artifacts, observed results and evidence limits are in [Mouse native verification](../verification/mouse-native.md). Existing About work is preserved; no agent commit, real configuration/grant/login change or configured remapping.

## Next

Native verification: in an explicitly identified build and authorized test profile, verify trigger/output recording and Escape retain the draft, then button/wheel/pointer timing and source-release behavior. Complete keyboard/VoiceOver and adaptive-material checks. Do not repeat already confirmed hardware subsets without a new concern; this editor integration adds no hardware-support claim.

Design: reconcile newer per-app/gesture-button/Devices states from INPUT-011 and DEVICE-002/003 against live Sketch; Magic Mouse editors depend on its hardware-defined presets. Core Mouse/Trackpad editor styling is already integrated.
