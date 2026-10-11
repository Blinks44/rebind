# Permission recovery — design delivery

Reviewed and saved 2026-10-10. Scope: UI-001, SPEC §§6–8/10–11 and S2; design only. Started at Git `365db64`; completion checkout is `acce2f4` after an external workflow commit during this design slice. Permission-recovery records/exports remain uncommitted; prior work is preserved. Existing actual permission checks were read in `InputPermissions`, `PermissionView` and `AppModel`; no engine, app source, grants or rules changed.

## Saved source and visual checks

Initial delivery: `Rebind.sketch`, Sketch 2026.3.1 / API 2.0.0, document ID `DE0BB366-21B8-47EC-B84B-49C9A12EF758`, SHA-256 `24fa31ba5ded19315842ea7950670f54097c1ba7ad35f8c3bbd08678b030ad2d`, ZIP CRC pass. Nine new Frames live below the existing Screens on **01 · Screens**. The current saved source and all nine exported images now include the subsequent [alignment repair](alignment-review.md): document ID `0D40E26C-3A14-42D3-9DBA-D9DC6DFAB6D4`, SHA-256 `50859f5bfbe9d4bc031431e526ca03f65a3af3fd29e6e554cd867484c28a6f58`. Resolve again before dependent work.

| Frame | Stable ID | Size | Final evidence |
| --- | --- | --- | --- |
| 14 · Keyboard / Accessibility missing · Light | `C7666697-D667-433D-87E7-2ED3AEE66AB0` | 1040 × 640 | [Light main](permission-recovery/main-light.png) |
| 15 · Keyboard / Accessibility missing · Dark | `ED7548FC-E890-4446-9B9A-49EAD9FF3013` | 1040 × 640 | [Dark main](permission-recovery/main-dark.png) |
| 16 · Keyboard / Event sending missing · Light | `4BE17A75-C9D5-4DA0-BADD-252CA3D63ABF` | 1040 × 640 | [Event sending main](permission-recovery/main-event-sending.png) |
| 17 · Settings / Permissions missing · Light | `9E3ECBEB-6D9B-4A8A-AA74-7F088874B71C` | 1040 × 640 | [Missing access](permission-recovery/settings-missing.png) |
| 18 · Settings / Event sending missing · Light | `FDAE5B1D-7817-4E57-B2DE-4F6A4A78F544` | 1040 × 640 | [Event sending](permission-recovery/settings-event-sending.png) |
| 19 · Settings / Required access enabled · Light | `1019A6B3-431F-43F7-A828-8A137FAD66B2` | 1040 × 640 | [Enabled grants](permission-recovery/settings-enabled.png) |
| 20 · Settings / Permissions missing · Dark | `74084012-59AC-4A15-A060-CF5800B0EDD0` | 1040 × 640 | [Dark Settings](permission-recovery/settings-dark.png) |
| 21 · Keyboard / Permission recovery · Compact | `33F9EC25-8B4E-4620-99C7-C2FD1F22BD73` | 880 × 600 | [Compact main](permission-recovery/main-compact.png) |
| 22 · Settings / Permissions · German | `46BD4DAA-B7FB-41B6-B6FC-BFD2A1E18AC2` | 880 × 640 | [German Settings](permission-recovery/settings-german.png) |

All nine were inspected through explicit-ID MCP screenshots after the final relevant edits, then exported at 1×. PNG dimensions were checked from their headers. Stale first captures were recaptured before accepting layout. Compact tests found negative origins and oversized card instances; explicit content anchors and compact row sources repaired them. German checks found clipped primary text and insufficient wrapped-text padding; Fit sizing now expands controls and cards. The German action card is 159 pt tall; event/additional-status rows are 86/87 pt. Default English action/status heights are 145/73 pt. Partial final rows in the compact main are intentional scroll-viewport content, not compressed rows.

Initial-delivery saved-model comparison retains all **1,143 pre-existing local nodes**, with **327 added** and none removed. One original onboarding action group materialized a default `flexItem` record (`alignSelf: 5`, no ignored layout, no preserved hidden space) during duplication; its geometry/content/style are unchanged. Original frame 08 was recaptured after saving. Brand artwork, original screens/components and delivery assets retain their existing scope. No prior user acceptance was extended to native behavior.

## Reusable composition

Six new live sources on **04 · Symbols** reuse existing typography, semantic Color Variables and native Apple controls. No symbols were detached and no new shared styles were needed.

| Source | Layer ID |
| --- | --- |
| Rebind/Light/Permissions/Recovery banner | `BBC2604B-0857-43A0-82D6-8C62CDA14B3C` |
| Rebind/Dark/Permissions/Recovery banner | `EE10BF9F-CD39-48E7-8CFF-E9039B5D3C0A` |
| Rebind/Light/Permissions/Action card | `983F73C0-FC6E-49A7-BEE6-56F362F47C7B` |
| Rebind/Dark/Permissions/Action card | `9E9E9B35-FF0E-44B5-AF37-63AE8769C8EB` |
| Rebind/Light/Permissions/Status row | `5E2E9251-F8EC-48F8-9042-27A57F0A8343` |
| Rebind/Dark/Permissions/Status row | `2B63B584-8DB9-4456-8BF9-FFBA7DB5963D` |

Glass remains on the established navigation/profile controls. Permission content uses calm semantic surfaces; status text conveys the distinction independently of color. Main mock rules now use F14, Control+Space, Command+Comma and Option+W, with the existing supported shortcut/system/window patterns. “Spotlight” denotes configured Command+Space shortcut output, not a newly added catalog action. Mock rules must never be inserted into real configuration. Profile name Work is user content and is not translated.

## Native behavior and sizing handoff

- **Setup later:** close setup and open the main category with its missing-access notice. Profiles, saved rules, menus and manual editing remain available. Add Binding may open an editor, but trigger/output recording and remapping require confirmed access. Do not disable the whole rules pane or change saved enabled flags to represent stopped remapping.
- **Accessibility missing:** Open System Settings opens Privacy & Security → Accessibility. Review Permissions selects Settings → Permissions. Missing grants stop capture/output; normal input passes through.
- **Accessibility granted, posting missing:** show Event sending required. Allow Event Sending invokes the existing explicit request route; checking/focus return reads the actual preflights. If access remains missing, use the Accessibility fallback and reopen guidance when macOS asks. The buttons never imply success by themselves.
- **Required access enabled:** each required grant reads Enabled. The headline deliberately says Required access enabled, not engine running. Actual engine failure, Secure Input and intentional pause remain separate states. Preserve the user's enabled/paused choice through setup, grant changes and recovery.
- **Revoked access:** stop remapping/cancel recording safely, preserve rules/selection/pause and show the applicable main notice/Menu Bar hint. Existing frame 12 remains the explicit recovery surface; closing it returns to the main notice. Avoid repeatedly reopening a modal while the person edits rules.
- **Other permissions:** Input Monitoring is Not required for the current active tap. Keep Automation action-specific. Do not request unrelated access.
- **Navigation:** six checked prototype edges connect Review Permissions and the sidebar Settings control in frames 14/15/16 to 17/20/18 respectively. These are static navigation examples; Check Again has no fake grant-transition link. Existing onboarding frames were not rewired. Full Settings tabs show the intended information architecture; other section contents are outside this slice. An implementation must provide working destinations or omit unavailable tabs rather than shipping inert controls.
- **Layout:** fixed 232 pt sidebar, 28 pt detail margins, 16 pt card padding/gaps, content-hugging native buttons. Main preferred 1040 × 640, compact reference 880 × 600; permission Settings preferred 1040 × 640 and DE reference 880 × 640. Main rows retain 68 pt height in a scroll viewport. Use independent scrolling for Settings content on smaller heights/longer translations; do not shrink fonts or clip controls. The existing code minimum 850 × 560 is still a native implementation discrepancy to reconcile.
- **Copy:** [handoff JSON](permissions-onboarding-copy.json) now has **53 keys × EN/RU/DE/FR**, preserving the previous 28 and adding 25 for recovery/Settings. It is not integrated into the app catalog. Use normal wrapping and Fit control/card sizing; never embed manual line breaks in localized catalog values to match the screenshot.
- **Accessibility:** native status labels, buttons and tab selection must expose meaningful VoiceOver semantics; order heading/status → explanation → primary action → Check Again → instructions. Main recovery actions precede search/list in keyboard reading order. Show visible focus, allow keyboard switching/return and use opaque semantic navigation with Reduce Transparency. Increase Contrast/Reduce Motion/native keyboard/VoiceOver acceptance is still required.

## Checks and limits

Observed: nine final MCP screenshots, saved-document identity/CRC/digest/model retention, six valid prototype edges, nine exported PNG sizes, 53 complete four-locale string entries and `git diff --check`. Public Sketch API/Stack/override documentation was consulted; API serialization of a nested library style failed, so the identity probe used public primitive fields instead. No private/native bridge was used.

Not run or claimed: native build/launch, permission grant/revocation, real remapping, hardware, macOS 26, RU/FR rendered layouts, native VoiceOver/keyboard or accessibility preference tests. The initial delivery did not check expanded windows or resize roundtrips of the nine new frames. The subsequent alignment review adds representative Dark main, compact recovery and German Settings expansion/restoration evidence; arbitrary sizes remain unverified. Existing onboarding's earlier three-size evidence keeps its original scope.

Latest alignment revision also centers sidebar/footer rows, repairs search/profile/compact columns, anchors intrinsic control sizes and uses vertical Settings body Stacks with 24 pt before the privacy note (German y = 608). Existing content, source IDs and prototype routes remain unchanged; twelve curated exports, including these nine, were refreshed and size-checked. Full checks and limits belong to [alignment verification](alignment-review.md).

**Next:** implement the prepared first-run and permissions slice using the real permission model and these live frames; retain the native verification gates in UI-001. Design can independently continue the remaining Settings sections under a separate scoped task.

## Subsequent native integration — 2026-10-11

UI-001 now integrates first-run/recovery, the main notice and Settings → Permissions; all 53 four-language keys are in the app catalog. [Native evidence](permissions-native.md) separates passing software/fixture checks from actual-grant/full-window/accessibility acceptance, which remains open. The design checks above retain their original scope/date.
