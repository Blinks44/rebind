# Menu Bar template and first-launch design

Historical Sketch PNG copies were removed on 2026-10-11. Use live Rebind.sketch via [DESIGN](../DESIGN.md); dated checks below remain historical evidence, not a new review.
Reviewed 2026-10-10. Scope: SPEC §§6–8, 10–11, S2, Phase 8. The Menu Bar asset is integrated; the onboarding screens are design artifacts, not implemented native onboarding.

## Live Sketch source

Saved `Rebind.sketch` through Sketch MCP 2026.3.1 / API 2.0.0. Latest post-save document ID: `A2DE362A-E026-47F5-8F3E-FBC3AF4353DD`; layer IDs remain stable. The layout repair below supersedes the initial visual review. Existing screens, brand sources, engine changes, rules, permissions and app settings were preserved.

- **04 · Symbols → Rebind/Brand/Menu Bar Template**, `0F0BD265-F8D6-4405-8425-247D8DA43C06`.
- **05 · Brand → 02 · Rebind / Menu Bar Template**, `EBAC2CD7-4F7F-4756-8BC4-AC1D43192933`.
- Reusable setup introduction / other-permissions components have Light/Dark sources on **04 · Symbols**. Shared SF Pro styles, semantic Color Variables and Apple macOS 26 button sources are retained. No library detachment or bitmap replacement.

New frames on **01 · Screens**, all 560 × 580 pt:

| Frame | ID | Review export |
| --- | --- | --- |
| 08 · First Launch / Accessibility required · Light | `EDA6F1D6-D17F-4ABB-8A72-1DECF5EDE4F4` | [Light](../DESIGN.md#screen-index-and-implementation-status) |
| 09 · First Launch / Accessibility required · Dark | `F0F88FE5-F6A1-4402-965E-96B83A27B732` | [Dark](../DESIGN.md#screen-index-and-implementation-status) |
| 10 · First Launch / Event sending required · Light | `18E3BEB1-9333-4C8E-97F1-F8233CAB8A95` | [Event sending](../DESIGN.md#screen-index-and-implementation-status) |
| 11 · First Launch / Ready · Light | `B01D939A-7E79-4E5A-9385-3F494EF9CF80` | [Ready](../DESIGN.md#screen-index-and-implementation-status) |
| 12 · Permissions / Access revoked · Light | `A2F08C1D-327C-4108-8C14-6AD6E320918F` | [Recovery](../DESIGN.md#screen-index-and-implementation-status) |
| 13 · First Launch / German text expansion | `E207327E-5664-496C-999A-2B7A69B61335` | [German](../DESIGN.md#screen-index-and-implementation-status) |

The current Sketch document remains authoritative; exports are review aids. Screens are not an interactive simulation of macOS permission prompts. No prototype links fabricate a successful grant or modify System Settings.

## Menu Bar asset

Derived the Small optical source's compound face, including enlarged counters, into an 18 × 18 pt transparent canvas with a 16 pt black silhouette and 1 pt inset. Removed shared material fills, borders, shadows and lighting. The black source is reused with white tint in the Dark preview; the app uses one template asset, with system coloring for appearance/selection.

- Editable SVG: `assets/brand/Rebind-MenuBar.svg`.
- Delivery PDF: `rebind/Assets.xcassets/RebindMenuBar.imageset/RebindMenuBar.pdf`.
- Image Set: mac idiom, `template-rendering-intent: template`, `preserves-vector-representation: true`.
- `rebindApp.swift`: `MenuBarExtra("Rebind", image: "RebindMenuBar")`; app-name semantics and existing menu behavior preserved.
- Preview: [actual-size Light/Dark and enlarged geometry](../../assets/brand/Rebind-MenuBar-preview.png).

Native implementation uses [Apple MenuBarExtra's named-image initializer](https://developer.apple.com/documentation/swiftui/menubarextra/init(_:image:content:)) and [template-image behavior](https://developer.apple.com/documentation/appkit/nsimage/istemplate). The 18 pt canvas is the selected optical design size, not a claimed mandatory HIG dimension. No dependencies or custom status-item implementation added.

## Permission behavior for implementation

Inspected `InputPermissions`, `InputPermissionRequirement`, `PermissionView`, and `AppModel` before composing these states. Keep their actual preflight checks and request/open-settings routes:

1. Missing Accessibility (`AXIsProcessTrusted == false`): explain purpose, open Privacy & Security → Accessibility, offer refresh and setup-later. Continue stays disabled.
2. Accessibility granted but posting unavailable (`CGPreflightPostEventAccess == false`): show that distinction, offer the explicit event-posting request and refresh. Do not request from polling or treat a click as a grant.
3. Permissions ready: both checks succeed. Continue becomes available. This state does not prove tap creation or running-engine success; tap errors must remain visible in the native app.
4. Input Monitoring is not separately required by the current active tap. Automation remains action-specific; never request unrelated Full Disk Access or Screen Recording. Re-evaluate this explanation if capture changes.
5. Revoked access: stop safely, preserve rules, retain normal input, offer settings/refresh/close. Keep global pause unchanged; recovery must never override an intentional pause.
6. Setup-later should enter the ordinary app with a missing-permission status and disabled recording/remapping. Designing that main-window empty/permission state is a next slice; the existing Work list is not used as a fake successful destination.

Copy is concise and uses existing localized permission terminology. [Copy handoff](permissions-onboarding-copy.json) contains **28 keys × EN/RU/DE/FR**, all nonempty. It is not integrated into `Localizable.xcstrings`. German expansion is visually checked, including native button widths and the full “Nicht erforderlich” status; RU/FR layout and all runtime localization remain open.

## Verification

- `scripts/dev.sh build` in the restricted environment failed because Xcode's macro plugin sandbox/asset renderer could not run. The approved ordinary build outside that sandbox succeeds; no project/security settings changed.
- `scripts/dev.sh build` and `scripts/dev.sh release`: **BUILD SUCCEEDED** in the original asset integration session. Only the expected AppIntents metadata-skipped warning. These builds were not rerun for the Sketch-only repair below.
- Native AppKit resource assertion: Debug and Release each load `RebindMenuBar` at **18 × 18 pt**, **isTemplate = true**, six representations. Used a temporary module cache. No app launch or remapping run.
- `codesign --verify --deep --strict`: Debug/Release pass.
- Initial exported-frame screenshots did not expose negative text origins clipped on the live canvas or unanchored contents when resizing. The claim of a sufficient visual review is superseded by the scoped repair below; the PNG links above now show that repaired revision.
- Original saved Sketch ZIP CRC passed; all eight required new asset/board/screen IDs existed. **1,137 local layers, zero duplicate layer IDs, zero nonfinite frames, zero missing Symbol references** in that initial revision. Six original PNG exports each measured 560 × 580. These structural checks did not prove correct canvas layout.
- `git diff --check` passes. No behavioral engine/persistence code changed by this task, so no additional matcher tests were added or claimed. Other uncommitted engine work is outside this task's verification scope.

Live Menu Bar rendering after user relaunch, macOS 26 runtime, selection/high-contrast/accessibility settings, keyboard/VoiceOver, native permission transitions and RU/FR layouts remain manual or implementation checks. The design is not evidence of a hardware/permission acceptance pass.

Next: design the first empty bindings window with permission guidance and the permission section in Settings, then implement the approved onboarding using actual state checks. Menu contents/remaining Dark states can be composed from the existing native components without changing the engine.

## Onboarding layout repair — 2026-10-10

Scope: [UI-001](../tasks/UI-001-permissions-onboarding.md), existing frames 08–13 and four Light/Dark setup sources. Baseline Git `f549764` plus concurrent changes preserved; no app source or product copy changed. Reviewed live Sketch and actual canvas rendering after rereading the updated AGENTS, WORKFLOW, STATE, PLAN, DESIGN and affected SPEC sections.

Confirmed findings and fixes:

- Introduction titles had `y = -12.3` inside clipping Symbol Sources. Permission headings had `y = -5`; additional-permission headings had `y = -2`. Reset them inside the container and pin them to the top/leading edge.
- The introduction icon was 48 × 42.24. Restore 48 × 48 and fix both dimensions so resizing preserves its proportions.
- Unpinned additional-permission text shifted left when its instance narrowed. Pin leading text left, statuses right, and let descriptions fill the available width with natural text height. Reuse existing shared SF Pro styles and Color Variables.
- Pin the content to top/left/right and footer to bottom/left/right. Keep native buttons at their intrinsic size; place permission actions in transparent horizontal Stacks with a 16 pt gap. Match the existing Dark frame's 16 pt window corners in Light.

Observed checks: all six original frames screenshot-reviewed at 560 × 580; temporary duplicates reviewed at 520 × 560 and 720 × 680, then returned to 560 × 580. All six roundtrip geometry comparisons pass after `stackLayout.apply()`; zero ordinary child-frame overflow at the restored size. Introduction/other-permissions expanded symbol geometry was also inspected, including square icon, complete headings and German wrapping. API frame assignment needs Stack application before synchronous geometry reads; the first un-applied roundtrip probe returned stale child widths and was replaced by the explicit apply check.

The actual Sketch canvas was inspected in addition to MCP frame captures, because the initial export missed clipping. Compact evidence: [Dark 520 × 560](../DESIGN.md#screen-index-and-implementation-status), [German 520 × 560](../DESIGN.md#screen-index-and-implementation-status). Preferred size remains 560 × 580; the tested minimum is 520 × 560. Native implementation must preserve wrapping/fixed controls and use content scrolling if available height is insufficient, rather than scaling the whole screen.

Saved revision: document `A2DE362A-E026-47F5-8F3E-FBC3AF4353DD`, SHA-256 `1fd30ff5ef06830fdb4ce6b8927133943e267b17a671218743a39f65b9915f4d`. ZIP CRC passes; **1,143 local layers**, six action-row containers added, no removed original nodes. Saved-node comparison against the pre-review backup found no content/style/geometry changes outside the ten owned frame/source subtrees; two unrelated layer-list disclosure flags changed, which are UI state. Shared text/layer styles are unchanged. All temporary probes were removed. Six refreshed exports are 560 × 580; two compact exports are 520 × 560. Post-save capture confirms the repaired Light frame. Layout work used the [public Sketch sizing/pinning/Stack API](https://developer.sketch.com/reference/api/).

Affected document file links resolve and `git diff --check` passes. No native app build, launch, permission grant, remapping or behavioral test was performed for this design-only repair. Native sizing, RU/FR layout, keyboard/VoiceOver and accessibility-settings checks remain open. Next design slice remains the missing-permission main window and Settings → Permissions; the scoped layout repair is complete, the whole first-run feature is not.

## Screen-icon consistency repair — 2026-10-10

Scope: [UI-001](../tasks/UI-001-permissions-onboarding.md), three sidebar icon instances, Light/Dark Setup introduction icons and About. Git baseline `365db64`; Sketch 2026.3.1 / API 2.0. Live Brand inspection confirmed the same linked geometry, with Small deliberately opening the counters. The defect was fixed-width appearance: original rim 2.9711538 pt and white-face border 2 pt remained unchanged in 32/48/80 pt instances, making their silhouettes look heavier than Brand. Earlier layout checks covered the square icon frame, not its stroke scaling.

Added six shared layer styles derived from the existing rim/white-face styles and scaled borders by target size / 1024. Two `layerStyle` overrides per icon preserve the original Symbol connection, paths, fills and material colors; no detach, raster replacement or Brand master modification.

| Instance size | White-face border | Rim border |
| --- | --- | --- |
| Sidebar 32 pt | 0.0625 pt | 0.09284855625 pt |
| Setup 48 pt | 0.09375 pt | 0.139272834375 pt |
| About 80 pt | 0.15625 pt | 0.232121390625 pt |

Observed MCP checks: all six permission frames, main Light/Dark/Compact and About reviewed after edits; the complete Dark main frame recaptured after its first capture showed stale rendering. Expanded icon trees confirm final border values; direct 32 pt captures agree in both appearances. Setup retains 48 × 48 proportions and the prior repaired text/footer layout. Evidence: [sidebar Light](../DESIGN.md#screen-index-and-implementation-status), [sidebar Dark](../DESIGN.md#screen-index-and-implementation-status), [About](../DESIGN.md#screen-index-and-implementation-status); six onboarding exports refreshed at 560 × 580. Compact 520 × 560 exports above remain evidence of the earlier layout revision, not this icon-style revision.

Saved document `F370A2F1-FBA6-4BF9-A056-A1500D5C8688`, SHA-256 `2fecf2bbaa7a6673ea789826ef59bcd6d4c3162cfed77e72c3b756bc6aff22f0`. ZIP CRC passes; all 1,143 original local nodes retained, no additions/removals, only the six owned icon nodes changed (`overrideValues` only). Original 36 shared layer styles are unchanged; six size-specific styles added. Original Brand artwork/review board, native `.icon` package and Menu Bar template remain unchanged. No geometry, text, engine or localization changes; no app build/runtime/permission tests needed or claimed for this Sketch-only correction. `git diff --check` and affected local file links pass.

Scoped icon/layout reviews are complete. At this review the whole first-run flow remained `in_design`. The later [permission-recovery delivery](permission-recovery.md) adds main/Settings states and makes the bounded first-run/permissions design ready for native implementation.
