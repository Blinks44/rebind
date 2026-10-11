# UI-003 — General settings and background behavior

- Updated: 2026-10-11.
- Stage: `implementing`; native General/background implementation in progress, login/runtime acceptance open.
- Owner: `/root` implementation, claimed 2026-10-11.
- Ownership checked: 2026-10-11, `main` / `acce2f4`; delivered General owner released, actual source/diff inspected. No active conflicting ownership identified in project records. Live General Light and approval frames/styles refreshed through MCP; document ID `E50CA3D9-82B1-44C0-AC97-39F1A9663700`.
- Owned surfaces: new General/login/settings Swift files and tests; bounded integration in ContentView, MainDestination, AppModel, PermissionView, rebindApp and Localizable.xcstrings; this task and affected evidence/STATE/index/history sections. Existing uncommitted permission/trackpad work is preserved. Sketch is read-only.
- Requirements: SPEC §§6, 8, 10–11, S1; PLAN Phases 7–9.
- Code baseline: `acce2f4`; earlier permission/alignment records remain uncommitted.

## Outcome and scope

Complete Settings → General with global enabled state, actual Launch at Login state and clear window/Menu Bar/quit behavior. Reuse the saved Settings shell and Apple controls. General is a new bounded design handoff; native Settings and SMAppService integration are pending.

## Acceptance

- [x] Saved Light/Dark, active/paused, login off/on/approval/error and compact/localization layouts.
- [x] Reusable live sources, four-language copy and honest permission/engine/login state contract.
- [x] Final MCP screenshots, resizing/restoration checks and saved-document integrity evidence.
- [x] Task/evidence, DESIGN/STATE/index/history updated and ownership released.

## Saved design and verification

`Rebind.sketch`, 2026-10-11, document ID `56ED9B64-CF2D-4FE8-AB0E-4EA4E3501214` (resolve again). SHA-256 `7ba3c8b345ae4b38eb1f8a7114d7cd8c9f7bdecdbe6491bb711f011f33868063`.

[Delivery evidence](../verification/general-settings.md) owns ten frame IDs (23–32), four Light/Dark sources, ten curated PNG exports, sizing and native state contracts. [Copy](../verification/general-settings-copy.json) has 25 new keys × EN/RU/DE/FR, not integrated into the app catalog. Busy/not-found states reuse the recovery composition through the documented behavior/copy contract.

All ten frames screenshot-checked. Expanded Light/Dark and minimum Russian checks performed; final three-frame resize restoration matches all 96 local node frames. Saved ZIP/digest/node comparison retains 1,494 original nodes unchanged and adds 344; 21 prototype routes valid. Native build/runtime/login/accessibility and recovery-copy localization remain unverified. No Git commit or app source change in this design slice.

## Current implementation

`rebindApp.swift` already retains one delegate model with MenuBarExtra, explicit quit and no termination after closing the last window. `AppModel` exposes global enabled state; no SMAppService or native General page exists. Do not add fake controls to the app from this design slice.

## Next handoff

- **Code — ready bounded handoff:** implement the prepared General settings and background behavior. Refresh live frames/evidence; reuse existing enabled-state/persistence/Menu Bar lifecycle and actual SMAppService/runtime status. Keep login, pause, permission and engine-error states independent. Run the delivery record's native transition/locale/accessibility checks on an identified bundle.
- **Design:** Input/hold timing is now delivered in [UI-004](UI-004-input-settings.md). Continue Settings → Language, then Advanced. General and first-run/permissions remain independently ready for implementation.
- User-facing handoff name: **General settings and background behavior**. A short request to implement that prepared design resolves here without a task ID.
