# UI-014: Trackpad preset editor

- Updated: 2026-10-16 (documentation reconciliation)
- Stage: awaiting_verification
- Owner: Unassigned; implementation released
- Requirements: SPEC §§3.4, 4, 9–11
- Code baseline: original editor on `afb7411` plus INPUT-002/003; expanded editor is integrated in `1a0801b`. No new native/hardware checks in this cleanup.

## Current outcome and acceptance

The editor exposes twelve complete tap/double-tap/corner/physical-click presets for built-in and external trackpad categories, one optional held primary modifier and the shared action catalog. [INPUT-004](INPUT-004-two-finger-double-tap.md) through [INPUT-009](INPUT-009-held-output-exclusions-catalog.md) own later engine/action/modifier additions. The original four-preset shortcut-only scope is historical.

- [x] Create/edit exact preset identities within the selected profile, retaining rule ID/enabled state and action.
- [x] One selector rather than touch recording or independent finger/type/direction controls; independent output-shortcut recorder retains previous output on cancellation/stale requests.
- [x] Conditional native coexistence guidance and public System Settings route without changing settings or claiming a grant.
- [x] Original software, native compact/layout and selector interaction checks.
- [ ] Physical accuracy, timing/click exclusion, native gesture coexistence and external hardware.
- [ ] Complete keyboard/VoiceOver, capture cancellation, six-language layouts and adaptive preferences on named current builds.

## Dated verification

Live Sketch inspection on 2026-10-12 used the former released UI-013 source; current visuals come from [DESIGN](../DESIGN.md) and integrated soft components. No Sketch edits or production rule/grant/action execution occurred in that editor slice.

[Original editor evidence](../verification/trackpad-preset-editor.md): 647 regression functions / 1,824 expanded executions, zero failures/skips; 160 native viewports, scoped Russian appearance/menu/record-cancel/AX review and Debug/signature pass. Its [selector follow-up](../verification/trackpad-preset-editor.md#direct-menu-and-full-area-hit-testing-follow-up) fixed whole-capsule hit testing and an unintended submenu: eight functions / 23 executions passed, including that viewport matrix. Four direct menu items were correct for the historical artifact, not today's complete pool. Original render/assertion and About/window-count warnings retain their documented limits.

## Next handoff

Verify the current preset pool and shared actions on named built-in/external hardware, including modifier matching, Look Up/Smart Zoom/secondary-click/Tap to click coexistence, capture cancellation and native accessibility. Do not recreate the already integrated selector/action/list surfaces or infer full touch release readiness from the old editor tests.
