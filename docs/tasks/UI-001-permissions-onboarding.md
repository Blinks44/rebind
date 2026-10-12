# UI-001 — coherent first-run and permission recovery

- Updated: 2026-10-12, after bounded Settings feedback adoption and final checks.
- Stage: `awaiting_verification`; first-run/recovery/Settings integrated and the reported rendering failure repaired. Actual grant/revocation and broader accessibility acceptance remain open.
- Owner: Unassigned; `/root` released bounded Settings → Permissions adoption on 2026-10-12. Earlier window repair is preserved; no Sketch edits.
- Owned surfaces: PermissionView, opt-in presentation in PermissionCard/PermissionStatusLabel/PermissionAccessControls, native permission layout checks and this task/evidence/status. Existing default setup/banner presentation, engine, catalog and production grants/configuration are outside the change.
- Ownership baseline: `main` / `59f5754` plus preserved uncommitted editor/Settings/design work, checked 2026-10-12.
- Reviewed surfaces: Frames 08–13/setup sources, three sidebar icon instances and About; six new size-specific shared styles. Original Brand masters/styles are preserved. Design review ownership was separate; native implementation scope is recorded above.
- Requirements: SPEC §§6–8/10–11, S2; PLAN Phases 7–9; DESIGN's modern macOS 26+ direction.
- Code baseline: prior inspection `6c1a5be`; current design session started at `365db64` and ends at `acce2f4`. Actual permission checks/guidance were refreshed; new design records are uncommitted.

## Outcome and scope

Provide a clear native first-run flow and recovery when grants are missing/revoked. Preserve real checks and user rules/intentional pause. Start by completing the missing-permission main-window and Settings → Permissions design, then implement a bounded onboarding slice; do not build all Settings, fake grants or alter capture behavior to match a mock.

## Design handoff

Saved `Rebind.sketch`, 2026-10-10; current document ID `0D40E26C-3A14-42D3-9DBA-D9DC6DFAB6D4`, resolve live again. Saved revision SHA-256: `50859f5bfbe9d4bc031431e526ca03f65a3af3fd29e6e554cd867484c28a6f58`. Six permission frame IDs remain stable in [DESIGN](../DESIGN.md#screen-index-and-implementation-status). Repaired Light/Dark setup components and Apple macOS 26 controls remain live and reusable.

Saved/reviewed states: Accessibility missing Light/Dark, AX granted/event-posting missing, ready, revoked and German expansion. The latest review fixes negative text origins, a vertically compressed icon, unanchored symbol contents and inconsistent button spacing. All six states were screenshot-checked at 560 × 580, 520 × 560 and 720 × 680; resizing back restores the original geometry after applying Stacks. See [layout review](../verification/menu-bar-onboarding.md#onboarding-layout-repair--2026-10-10).

Implementation sizing contract: preferred 560 × 580; tested minimum 520 × 560, 32 pt outer margins, square 48 pt introduction icon, fixed-size native buttons, 16 pt permission-action gap and footer pinned 32 pt above the bottom. Keep text wrapping and use scrolling for content that exceeds the native available height rather than shrinking typography or controls. Setup-later's main-window destination and Settings → Permissions are now composed in frames 14–22; see the recovery delivery below. Ready means actual grants, not a successful tap/engine. RU/FR/runtime layouts and accessibility settings remain open; no blanket user acceptance is claimed.

Repaired live sources on **04 · Symbols**:

| Source | Stable layer ID |
| --- | --- |
| Rebind/Light/Setup/Introduction | `BBBC8810-6979-4192-BE0A-A1E845943656` |
| Rebind/Dark/Setup/Introduction | `86843F55-7D06-478D-B2EF-1CF0B440722D` |
| Rebind/Light/Setup/Other permissions | `24A3BC50-657A-44EE-A371-D22ADD95F36F` |
| Rebind/Dark/Setup/Other permissions | `3FB04F76-BE49-44DE-9DB0-A6A2A0F4419C` |

[Copy handoff](../verification/permissions-onboarding-copy.json): 53 keys × EN/RU/DE/FR, now integrated into the app catalog by the native implementation. Use Writing for Interfaces when revising user-visible text; preserve terminology and all languages.

Screen-icon consistency repair: Setup/About retain the Frosted master; sidebar retains Small optical geometry. Size-specific layer-style overrides scale only the white-face and rim borders by target size / 1024, preserving Brand geometry, materials and live Symbol connections. See [icon review](../verification/menu-bar-onboarding.md#screen-icon-consistency-repair--2026-10-10). App/Dock/Menu Bar delivery assets are unchanged.

## Permission-recovery delivery — 2026-10-10

Frames 14–22 add missing AX Light/Dark, posting-missing main, Settings missing/posting-missing/granted, Dark Settings, compact main and German Settings. [Delivery evidence and frame/component IDs](../verification/permission-recovery.md) own exact checks, copy, sizing, prototype navigation and native transition/accessibility requirements. The previous onboarding visual direction was accepted before this slice; that does not establish runtime acceptance of the new frames.

The bounded design is ready for native first-run/setup-later/revocation and Settings → Permissions implementation. Required-grants success is distinct from engine activity and deliberate pause. All other Settings sections and general main-window redesign remain outside this implementation slice. The new frames have final screenshot evidence at their listed sizes; arbitrary resizing and RU/FR/native checks remain open.

Subsequent [UI-002 alignment review](../verification/alignment-review.md) repairs desktop centers/columns/spacing and intrinsic-size/edge anchors, refreshes the nine recovery exports and checks expanded Light/Dark/compact/DE views. The final three-frame roundtrip restores all 553 screen-node frames exactly. Preserve fixed native controls, 68 pt main rows, 16 pt card gaps and 24 pt before the privacy note; retain scrolling for insufficient native space. The current revision supersedes initial desktop geometry; behavior/copy scope and native acceptance remain unchanged.

## Acceptance

- [x] Scoped repair: existing frames 08–13 saved, visually checked at three sizes, and resize roundtrip geometry verified; unaffected Sketch artwork preserved.
- [x] Scoped screen-icon repair: sidebar 32 pt, Setup 48 pt and About 80 pt saved/screenshot-reviewed; original Brand masters/styles and layout preserved.
- [x] Missing-permission main-window and Settings → Permissions states saved and visually checked in current Sketch; nine new frames, six shared sources, scoped compact/DE checks and state behavior recorded.
- [x] Native onboarding uses existing AX/posting preflights; grants are never inferred from button taps or requested by polling.
- [ ] Setup-later, ready and revocation routes are real; recording/remapping remain unavailable without required access, engine errors stay visible, deliberate pause/rules preserved.
- [x] Current tap does not ask for unrelated Input Monitoring/Full Disk Access/Screen Recording. Automation remains action-specific.
- [x] Native implementation builds; isolated transition/software tests and native window geometry pass. Actual-grant behavior remains a separate open check.
- [ ] Light/Dark, window sizing, EN/RU/DE/FR, keyboard/VoiceOver and transparency/contrast/motion settings verified for the delivered slice; handoff retains open checks.

## Implementation and verification

Native first-run, one-time idle revocation recovery, main notice, sidebar permission destination and standard Settings/Menu Bar routes use the existing model/public AX/posting checks. Schema 23 atomically persists setup acknowledgement; schemas 1–22 migrate without rewriting and preserve rules/pause. Missing grants cancel recording while retaining the worker cancellation result; engine callbacks/output guards are unchanged. No About, other Settings content or full main/sidebar visual redesign was added.

Final software evidence: **508 tests / 68 suites / zero failures**, Debug and universal Release builds, both signatures, 53 exact four-language keys and `git diff --check`. Thirty-two native permission/setup/banner fixture captures reviewed, including compact/expanded and Light/Dark layouts. Full NavigationSplitView offscreen capture was blank and excluded; real permission changes, full-window/keyboard/VoiceOver/accessibility preference and minimum-OS/Intel checks remain open. [Native evidence, identified artifacts, bounded differences and walkthrough](../verification/permissions-native.md).

Live permission frames/styles were read from document `56ED9B64-CF2D-4FE8-AB0E-4EA4E3501214` before coding; independent Input design subsequently changed the document identity. No implementation Sketch edit/save or Git commit. Earlier design evidence remains in [menu-bar/onboarding](../verification/menu-bar-onboarding.md) and [permission recovery](../verification/permission-recovery.md).

## Main-window repair — 2026-10-11

Removed forced vertical sizing from the recovery description: minimum-size probing had made the 640 pt window host a 1309 pt split view. Final split bounds fit at three sizes across 72 language/grant/rule combinations. Native screenshots confirm visible sidebar/header/notice/footer; Settings/category navigation, editor cancellation, standard Settings/scrolling and isolated first-run deferral were checked. Final checks: 508 Swift Testing cases in 68 suites plus one XCTest geometry test, zero failures; universal Release and both signatures pass. Temporary capture/manual helpers removed before final tests. [Repair evidence, artifacts and limits](../verification/permissions-native.md#main-window-repair-and-verification--2026-10-11).

Actual grants/revocation, VoiceOver/preferences and complete main Sketch styling remain open. This bounded repair does not finish the product or remaining input capabilities.

## Settings feedback adoption — 2026-10-12

Permissions adopts current shared amber warning/green verified status, compact recovery controls and opt-in raised opaque Light/Dark cards. Shared defaults keep setup/banner/other Settings presentation intact. Actual grant requests/checks, rules/pause, engine, four-language catalog and schema are unchanged. Status/recheck placement follows live Sketch; existing Finder/signing help remains reachable by scrolling.

[Final evidence](../verification/permissions-feedback-adoption.md): **18 selected functions, 656 native viewports, zero failures**, final Debug/signature and scoped English/German Light/Dark live review pass. Grant/revocation, complete spoken VoiceOver/keyboard/preferences and macOS 26/Intel remain open. Intermittent approval-service rate limits prevented additional live state selection; native/software coverage and observed-state limits are explicit. This bounded adoption is implemented; the whole UI-001 acceptance remains `awaiting_verification`.

Next implementation: adopt the separately released [Language selector refinement](UI-019-language-selector-contrast.md) from fresh Sketch or continue remaining Settings/main/profile materials. Reconcile [UI-018](UI-018-human-interface-copy.md) copy when that independent design work is released. No agent commit or Sketch save.

## Next handoff

- **Code — verification handoff:** verify actual grant/revocation and accessibility for integrated first-run/permission recovery and current Settings feedback on the named bundle, following [current evidence](../verification/permissions-feedback-adoption.md) and the earlier [onboarding walkthrough](../verification/permissions-native.md). The user controls actual grants and configured input; keep unavailable gates open. General/Input/Language/Advanced already have native implementations in their owning records.
- **Design — independent next slice:** continue released-source review/copy under its own task, then hand off affected native reconciliation. Do not expand UI-001 into all Settings; native integration checks remain with implementation.
- User-facing handoff name: **first-run and permissions**. “Implement the prepared first-run and permissions design” resolves here without a task ID. No automatic agent messaging or extra design-approval gate is implied.
