# UI-003: General settings and background behavior

- Updated: 2026-10-16 (documentation reconciliation)
- Stage: awaiting_verification
- Owner: Unassigned; implementation released
- Requirements: SPEC §§6, 8, 10–11; S1
- Code baseline: initial `acce2f4` / `b453d8d`, feedback adoption `59f5754`; integrated in `1a0801b`. Later presence/device additions retain their own evidence.

## Current outcome and decisions

Since 1.2.0, General also holds Excluded Apps, moved from the retired Input tab ([UI-025](UI-025-devices-in-main-window.md)).

General projects actual runtime/global pause and real SMAppService login state through the shared app model. Register/unregister are explicit operations; approval, errors, busy/unavailable and external state changes remain distinct. There is no persisted login boolean or helper. Main and Menu Bar routes reuse the same model. The separate Settings scene is removed by [FIX-001](FIX-001-wheel-and-window-regressions.md); Menu Bar Settings, battery/Devices and Command-comma now route into the main window. Earlier standard-window evidence below remains historical. Current visual source is [DESIGN](../DESIGN.md); [historical handoff](../history/settings-design-through-2026-10-11.md#general) is not a visual implementation contract.

Failed resume stays paused. Explicit pause cancels output immediately and stays paused in memory even when saving fails, exposing the error; it must not restart input to restore an old disk preference. Suppressed releases retain ownership; durable pause after a failed write is not established.

The full-main overflow root cause was pinned vertical sizing inside NavigationSplitView. Removing it restored viewport/column bounds without clipping or per-locale heights. Keep full-main integration coverage. Separate negative-geometry warnings were isolated to the AppKit sharing indicator during inspection; [evidence](../verification/appkit-sharing-indicator.md) supports no production workaround on that host.

## Acceptance and verification

- [x] Actual-state login/runtime, recovery feedback and current shared design-system implementation.
- [x] Software transition/storage/ownership checks, full-window geometry and scoped native navigation/AX title checks.
- [x] Real registration/removal, external Login Items change and login relaunch with the same profile and pause state: user-confirmed on the 2026-10-15 checklist (debug build), reported 2026-10-16.
- [ ] Login relaunch with missing access.
- [ ] Complete main/standard/Menu Bar traversal, keyboard/VoiceOver, six-language widths and accessibility preferences.
- [ ] macOS 26; Intel only if claimed.

[Native evidence](../verification/general-settings-native.md) owns commands/artifacts and walkthroughs. Initial integration: 529 Swift Testing + two XCTest cases; full-main repair: 529 + three, zero failures. Geometry covered 264 General and 224 full Settings combinations. Scoped French/Russian/Dark navigation and AX labels were checked, not actual login or spoken VoiceOver. The 2026-10-12 feedback adoption passed 23 selected functions, 728 native viewports, Debug/signature and English Light/German Dark compact review. No checks were rerun by this cleanup.

## Next handoff

Verify actual login/lifecycle and native accessibility on a named current bundle. Preserve the integrated General/Permissions/Input/Language/Advanced and whole-app styling; old instructions to implement those surfaces are superseded.
