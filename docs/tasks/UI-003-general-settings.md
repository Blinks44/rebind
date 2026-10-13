# UI-003 — General settings and background behavior

- Updated: 2026-10-12.
- Stage: `awaiting_verification`; General feedback adopted; actual login/relaunch/accessibility acceptance remains open.
- Owner: Unassigned; `/root` released bounded General feedback adoption on 2026-10-12. Real login/restart checks remain user-led.
- Ownership checked: 2026-10-12, `main` / `59f5754`; inspected actual source/diff and released UI-016/UI-017 ownership. Preserved uncommitted editor/design work; current Sketch document resolved directly through MCP.
- Owned surfaces: GeneralSettingsView, LoginItemSettingsRow, GeneralSettingsLayoutTests and affected task/evidence/status sections for the current slice. No shared-component, Sketch, engine, login-service or catalog edits.
- Requirements: SPEC §§6, 8, 10–11, S1; PLAN Phases 7–9.
- Initial code baseline: `acce2f4`; external commit `b453d8d` captured the first General implementation. Current feedback slice is `59f5754` plus the files above and preserved uncommitted work; no agent commit.

## Outcome and scope

Complete Settings → General with global enabled state, actual Launch at Login state and clear window/Menu Bar/quit behavior. Reuse the saved Settings shell and Apple controls. Native General/Permissions Settings share the existing delegate model; public SMAppService integration uses actual system state.

## Acceptance

- [x] Saved Light/Dark, active/paused, login off/on/approval/error and compact/localization layouts.
- [x] Reusable live sources, four-language copy and honest permission/engine/login state contract.
- [x] Final MCP screenshots, resizing/restoration checks and saved-document integrity evidence.
- [x] Task/evidence, DESIGN/STATE/index/history updated and ownership released.

## Saved design and verification

Current visual revision: materials/alignment review, saved 2026-10-11. Shared elevation/profile materials, Dark section controls and compact General offsets supersede affected original exports below. Behavior/copy and native regression evidence remain valid; reconcile appearance without undoing the full-main sizing repair.

`Rebind.sketch`, 2026-10-11, document ID `56ED9B64-CF2D-4FE8-AB0E-4EA4E3501214` (resolve again). SHA-256 `7ba3c8b345ae4b38eb1f8a7114d7cd8c9f7bdecdbe6491bb711f011f33868063`.

[Delivery evidence](../verification/general-settings.md) owns ten frame IDs (23–32), four Light/Dark sources in live Sketch, sizing and native state contracts. Copy has 25 new keys × EN/RU/DE/FR, now integrated exactly into the app catalog; two supplemental recovery/session keys added. Busy/not-found states reuse the recovery composition through the documented behavior/copy contract.

All ten frames screenshot-checked. Expanded Light/Dark and minimum Russian checks performed; final three-frame resize restoration matches all 96 local node frames. Saved ZIP/digest/node comparison retains 1,494 original nodes unchanged and adds 344; 21 prototype routes valid. That design slice performed no native build or app-source change. Subsequent native evidence is recorded below; actual login/accessibility acceptance remains open.

## Current implementation and checks

`SettingsView` serves main and standard Settings routes with General and Permissions. `GeneralSettingsView` projects actual runtime, global pause and existing window/Menu Bar behavior. `LoginItemModel`/`SystemLoginItemService` use actual SMAppService status, explicit register/async unregister, approval, refreshed failures, external changes and bounded retries. No configuration login boolean, package/helper or input callback changes.

[Native verification](../verification/general-settings-native.md) owns final artifact digests, native fixture images and remaining checks. Debug/full test: **529 Swift Testing cases / 71 suites + two native XCTest cases, 531 total / zero failures**. General geometry covers 264 state/locale/appearance/size combinations; existing main geometry covers 72. Universal Release and signatures pass. Isolated live French General/Permissions navigation and named-toggle AX representation checked; spoken VoiceOver and real login are not verified.

Safety clarification: failed resume retains paused state; explicit pause cancels output and remains paused in memory even if saving fails. It must not restart input to restore a disk preference. Suppressed releases retain ownership; durable pause after a failed write is not claimed.

- [x] Native General/Permissions routes, actual-state login/runtime and four-language integration.
- [x] Software transition/storage/ownership tests, native geometry, curated fixture review and AX title repair.
- [ ] Actual registration/approval/removal, external OS state and real login/relaunch with paused/missing-access conditions.
- [ ] Full main/standard/Menu Bar routes, keyboard/VoiceOver/accessibility preferences, macOS 26 and Intel execution.

## Reported full-main-window regression and repair

The initial standalone General fixtures and rules-page main tests missed General inside `NavigationSplitView`. A native full-main reproduction measured a 1588 pt split inside a 750 pt viewport, shifted −419 pt. Pinned Settings/runtime vertical `fixedSize` caused the expansion; removing it restores exact viewport bounds without clipping or hardcoded heights. Repair evidence owns probes, current artifacts and limits.

Native Russian General → Permissions → rules → Settings transitions checked in an isolated visible full-main hierarchy. New permanent coverage checks 224 full Settings state/locale/appearance/size combinations and both native columns. Full suite: **529 Swift Testing cases / 71 suites plus three native XCTest cases, 532 total / zero failures**. Subsequent targeted native tests pass with consistent AppKit/SwiftUI appearance. Cached Dark sidebar images remain excluded; a follow-up visible Dark General/Permissions navigation and compact 880 × 600 resize review passed without observed overflow. Two curated Dark captures retained. Temporary inspection tests removed; build-for-testing/signatures pass with unchanged executable digests. Live AppKit transition geometry warnings still need isolation; real login and VoiceOver remain open. Repair evidence records the successful short inspections, failed extended hold and evidence limits. ENGINEERING records the sizing hazard and full-window integration requirement.

## Next handoff

- **Verification:** on an explicitly identified bundle, perform the six actual login/lifecycle/accessibility checks in the native evidence. Real user login/permission changes remain user-controlled.
- **Code:** continue remaining Settings → Permissions feedback/material adoption from current live Sketch and existing components. Input, Language and Advanced already have native implementation; do not recreate them from historical next-step notes.
- **Design:** review justified native feedback arrangement/scrolling differences against the saved source; existing design remains released.
- User-facing name: **General settings and background behavior**. General implementation is available; required native acceptance remains open.

## AppKit warning isolation — 2026-10-11

[Captured stacks and controlled runs](../verification/appkit-sharing-indicator.md) attribute the warning to NSWindowSharingSessionRecipientIndicator receiving (-1, -1) during selective sharing/inspection. The same actual-main fixture without Computer Use emits zero such warnings. No production control/layout workaround was added; temporary instrumentation removed. The warning investigation is complete on this host; real login/relaunch and accessibility acceptance remain open. The then-next Advanced slices have since been implemented in UI-008/UI-007; current next work is listed below.

## General feedback adoption — 2026-10-12

Adopted existing shared semantic feedback/recovery controls from live General and Foundations 04/14/15. Runtime/login failures, missing access/protected configuration, approval/unavailable and busy states retain actual-state behavior and four-language copy. Neutral pause remains neutral. General status scrolls with content to accommodate expanded messages without the old split-view minimum-height failure; protected-file guidance is shown once.

Final evidence: 23 selected functions pass, 728 native viewports, final Debug/strict signature and isolated live English Light/German Dark compact review. Temporary test-store isolation and unsupported accessibility Environment override attempts are documented with their limits. No actual login/input/permission/configuration/Sketch change or agent commit. Required runtime/accessibility/minimum-OS checks remain open; ownership released. Next independent slice: Settings → Permissions feedback/material adoption.
