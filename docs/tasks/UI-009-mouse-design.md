# UI-009 — Mouse rules and conditional trigger editor

- Updated: 2026-10-11.
- Stage: `awaiting_verification`.
- Owner: Unassigned; bounded native implementation released 2026-10-11 on `main` / `8daa97b` plus the scoped uncommitted changes below.
- Ownership checked: live Rebind.sketch through MCP and current task records. Independent About implementation and UI-011 shared-material design preserved.
- Owned surfaces: Mouse detail/list, conditional editor and capture draft, validation, associated tests/catalog and scoped evidence pointers. Sketch/shared sources were read only during implementation.
- Requirements: SPEC §§2, 3.2–3.3, 4, 10–11; M1/M2/R1; PLAN Phases 2, 8–9.
- Code baseline: `main` / `bf36465` at design start; external HEAD advanced to `8daa97b` during work. Design phase made no app source edits or Git commit; native changes are recorded below.

## Outcome and scope

Design category-wide Mouse rules and a focused editor for recorded numeric middle/additional buttons, discrete wheel and four cardinal button-held pointer gestures. Preserve manual profiles, exact primary modifiers, existing Press/Double Press/Hold behavior and per-rule hold duration. No physical-device inventory, typed button codes, primary/secondary capture claim, smooth-wheel support or new gesture mechanism.

## Design acceptance

- [x] Populated/empty Mouse list, Light/Dark and compact/localized review.
- [x] Button/wheel/pointer editor with applicable activation, recording/cancel/retry, unavailable/conflict/failure states.
- [x] Self-contained Sketch behavior/accessibility and EN/RU/DE/FR copy annotations; live screenshot review and actual save.
- [x] Concise task/STATE/DESIGN/history handoff and `git diff --check`.

## Source and verification

Rebind.sketch saved and reviewed live on 2026-10-11 in Sketch 2026.3.1 / public API 2.0.0. Screens **70–89** are released; Foundations **11–13** own interaction/accessibility and four-language copy. New capture/listening/disabled-save sources reuse existing native controls and semantic styles. The document is self-contained; inspect it directly through MCP.

Successful save callback and saved archive inspection: document ID `B9108B54-6C2B-4897-921A-F5762B7FC5B8`, SHA-256 `54ef795e2e9f349d7ec685012217fbea75f4b9b0286892922e8a7c1d1faa4889`, 89 screen/state frames. Every baseline source ID remains; all 69 original screen names/IDs/bounds match. Existing Brand and shared sources were outside mutation scope. Save regenerated the document ID; resolve it freshly.

Live MCP screenshots checked all new states, Light/Dark, German 880 × 600 list and RU/DE/FR editors. Corrected activation overrides, Dark popup contrast, recording footers and annotation wrapping/pins; final sheet actions and annotation text remain within bounds. Compact list intentionally scrolls. Repository handoff links/status and `git diff --check` pass; no routine PNG exports or versioned verification images.

Design review does not establish hardware support or native behavior. Button 9 is an authored numeric example, not a hardware result. No app build/runtime, recording, remapping, configuration or permission changes were performed during the design phase. Native keyboard/VoiceOver/adaptive materials, localization, capture cancellation and physical timing acceptance remain open; existing capability evidence is unchanged.

## Native implementation — 2026-10-11

Implemented category-wide selected-profile Mouse list/search, per-rule enabled state, edit/delete, empty/no-results feedback, permission recovery and diagnostics. The editor separates trigger/output capture; button activation/Hold, discrete wheel and cardinal pointer direction show only applicable controls. Type changes reset trigger options while retaining the action. Existing identity/enabled state and unrestricted numeric button indexes are retained. Only the editor's exact recording request can update its draft; cancelled/stale/wrong-type results retain values. Save uses shared configuration validation, displays conflicts, and retains the draft after storage failure. Nested permission recovery preserves unsaved edits. Secure Input/suspended/stopped capture is unavailable; global pause alone permits recording.

Live Screens 70/75/77/79 and Foundations 11–13 were inspected through MCP before implementation. No new capture/action mechanism or dependency: existing synchronous tap/recorder/matcher and persistence remain. The later [UI-011 glass-control revision](UI-011-control-unification.md) is now saved/reviewed and released; Live Foundations 14 and Screen 75 were refreshed read only after release: 36 pt glass form controls, one activation track and wider section spacing require a separate native adoption pass. The checks below verify functionality and the earlier materials; they do not certify the revised appearance.

- [x] Mouse list and conditional editor implementation with EN/RU/DE/FR copy.
- [x] Draft ownership/type-reset/conflict/profile/numeric-button/search and capture availability software checks.
- [x] Four-language Light/Dark native size matrices and bounded live editor/type-switch review.
- [ ] Real capture, Escape/cancellation/retry, storage-failure UI, timing/release/safety acceptance on identified hardware.
- [ ] Full keyboard/VoiceOver, production-language contexts and accessibility materials.
- [ ] Adopt the released UI-011 materials; no independent Sketch edit/save during native work.

Checks, exact final artifacts, observed results and evidence limits are in [Mouse native verification](../verification/mouse-native.md). Existing About work is preserved; no agent commit, real configuration/grant/login change or configured remapping.

## Next

Native verification: in an explicitly identified build and authorized test profile, verify trigger/output recording and Escape retain the draft, then button/wheel/pointer timing and source-release behavior. Complete keyboard/VoiceOver and adaptive-material checks. Do not repeat already confirmed hardware subsets without a new concern; this editor integration adds no hardware-support claim.

Design: UI-011 is released; next cover Trackpad/Magic Mouse available, experimental and unavailable states within existing acquisition/support limits.
