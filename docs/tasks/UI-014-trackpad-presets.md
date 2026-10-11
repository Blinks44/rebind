# UI-014 — Trackpad tap preset editor

- Updated: 2026-10-12.
- Stage: `awaiting_verification`; bounded tap editor released, physical/accessibility acceptance open.
- Owner: Unassigned; `/root` Swift agent released implementation ownership on 2026-10-12.
- Ownership checked: `main` / `afb7411` plus INPUT-002/003 work. UI-013 is saved/released; no Sketch edits.
- Owned surfaces: BindingEditor/Draft, opt-in capture-control wrapping, scoped Trackpad preset presentation, localized tap guidance, editor tests and affected status/evidence sections. Preserve engine, other editor behavior and concurrent design work.
- Requirements: SPEC §§3.4, 4, 9; PLAN Phase 5; released UI-013 Screens 93/99/106 and Foundations 16/22.

## Outcome and acceptance

Expose the four implemented three/four-finger single/double tap identities through one complete preset selector and independent shortcut recorder. Inspect the live saved Sketch before visual integration; target release membership/shared actions remain broader than current engine support.

- [x] Presets create/edit exact identities, preserve shortcut/ID/enabled state, and validate within the selected profile.
- [x] Selection never records a touch or executes an action; output cancellation/stale requests preserve previous values.
- [x] Native conflict guidance is conditional on possible OS settings, never claims to read grants/settings or suppress gestures; system settings are changed only by the user.
- [x] EN/RU/DE/FR, native compact Light/Dark editor checks, meaningful behavioral tests and Debug build.
- [ ] Physical accuracy, coexistence, keyboard/VoiceOver and adaptive material acceptance on identified builds.

## Source and checks

Live MCP inspection on 2026-10-12: Rebind.sketch, document `4B31A177-0924-4510-AC9B-D71EB9C06470`, Sketch 2026.3.1/API 2.0.0. Read Screens 93/99/106, shared Complete preset component and Foundations 16/22; screenshot reviewed. Source locator/digest stays in DESIGN. No Sketch edits or production configuration/permission/action execution.

[Evidence](../verification/trackpad-preset-editor.md): 647 full-regression functions / 1,824 expanded executions, zero failures/skips; 160 native viewport checks, scoped live RU appearance/menu/record-cancel/AX review and final Debug/strict signature pass. Known About QoS and aggregate matrix window-count warnings remain. Initial native assertion/rendering limitations and additional feedback-fixture recheck are recorded honestly. No agent commit.

This adopts only the four engine-backed tap presets and shortcut action. Other gestures/shared actions, final lists/keycaps and broader UI-011/012/013 adoption remain separate. Missing hardware does not prevent preset editing; only output capture needs actual permissions/runtime availability. System Settings opens through public app lookup, without a private pane URL or setting writes.

Completion freshness check discovered concurrent [UI-015](UI-015-production-design-review.md) in design, refining shared Sketch sources without native code ownership. This integration uses the released UI-013 revision inspected above; reconcile any subsequently released control/capture refinement before claiming final visual adoption. No UI-015/Sketch source was edited by this task.

## Next step

Verify physical three/four single/double taps, timing/click exclusion, Look Up/Zoom coexistence and capture cancellation on the identified ordinary build in the evidence. Complete keyboard/VoiceOver/adaptive preferences and production locale contexts. Continue remaining touch engine/action/list slices independently; do not mark Phase 5 or the final design adoption complete.
