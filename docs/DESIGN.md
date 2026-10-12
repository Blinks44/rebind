# Rebind — design direction and live source index

Updated 2026-10-12 (soft design system). [SPEC](SPEC.md) owns required behavior. **Sketch owns the visual design, components, states, product copy and interaction annotations.** This file is a short locator and readiness index; implementation agents inspect the live source directly through MCP.

Design the final planned release, including Trackpad and Magic Mouse. User clarification on 2026-10-11: temporary implementation gaps (such as four-finger-only or not-yet-implemented placeholders) are not target product states. Remove or replace those specimens under [UI-013](tasks/UI-013-design-coverage-completion.md). Keep genuine device compatibility, permissions, conflicts and recovery states. Target design does not claim current implementation or hardware verification; those facts remain in CAPABILITIES and verification.

## Direction: soft, opaque-first macOS 26+ (2026-10-12)

User decision 2026-10-12: the calm look of **Rebind - new.sketch** replaces the Liquid Glass direction. Surfaces are opaque-first with soft shadows and 1 pt hairlines; controls are 36 pt capsules (28 pt small); lists sit on one raised card with 72 pt rows; raised SF Pro Rounded keycaps are the brand motif; one blue accent, and other color only for state. Only the sidebar and menus may use a system material. Light and Dark share geometry, type and spacing. Preserve native SwiftUI/AppKit semantics, SF Pro/SF Symbols, system menus/focus and desktop density.

## Current source: Rebind - new.sketch

Open **Rebind - new.sketch** through Sketch MCP (load `mcp`, then `use`; resolve the open document by name). Last save/review **2026-10-12**, SHA-256 `fb80066eafaa777789c42011396c7d390192e644da13151d9817f285ca48bfb9`; IDs change after reopening, so resolve them live. [UI-022](tasks/UI-022-soft-design-system.md) records scope and limits.

| Page | Content |
| --- | --- |
| 01 · Screens | 18 screens, each Light and Dark, built only from components |
| 02 · Foundations | Color variables, typography, shape/spacing/elevation, component overviews, principles and native mapping |
| 03 · Components | Symbol sources named `Theme/Group/Variant`, plus theme-neutral `Icon/<SF Symbol name>` |
| 05 · Brand | App icon artwork as scale-safe paths (also used as the in-app logo), Menu Bar template |
| 99 · Archive | The two original hand-drawn Keyboard frames |

Screens are drawn **in English only** (user decision 2026-10-13): other languages are translated and checked in the app, not duplicated in Sketch. Icons are real SF Symbols outlines exported with `tools/sf-symbol-svg.swift`; each `Icon/<name>` component is named after the symbol used in code, so add a symbol by exporting it rather than drawing it.

Every color is a `Light/…` or `Dark/…` Color Variable; layer and text styles reference those variables. Sketch has no variable modes, so each component exists once per theme. Reuse these sources; do not draw raw layers or hex colors on screens.

Covered screens: Keyboard, Mouse and Trackpad lists; Magic Mouse empty state; permission-needed and paused states; Keyboard editor (recording, conflict, action picker); Trackpad editor with the curated gesture menu; all five Settings tabs; profile management; first-run setup; About. Not yet redrawn: Mouse and Magic Mouse editors, action parameters, the profile-name sheet, diagnostics and compact-width variants.

## Previous source: Rebind.sketch (behavior, states and copy reference)

The sections below describe the earlier 125-frame Liquid Glass source. Its **visual** treatment is superseded. Until the new source covers a surface, use the earlier frames only for required states, reviewed EN/RU/DE/FR copy and interaction annotations, restyled with the new components.

The saved [semantic-feedback system](tasks/UI-012-semantic-feedback.md) makes failures red, prerequisites/conflicts amber, completed operations green and information/progress blue. Use a calm opaque state surface, native icon and explicit title; preserve readable body copy and accent-colored recovery controls. Deliberate pause, empty and disabled states remain neutral. Foundations 15 applies to all subsequent design, including remaining profile/action/gesture states.

Trackpad and Magic Mouse use one selector of complete, curated gesture presets followed by the shared action editor. No touch trigger recording or separate type/finger/direction selectors. Keyboard/conventional Mouse keep their trigger recorders; output-shortcut recording is available to every category. This 2026-10-11 product decision supersedes the initial UI-013 touch recording compositions; SPEC and the project-local design skill carry the behavioral rule.

Use semantic colors and adaptive materials. Reduce Transparency preserves layout with opaque surfaces; Increase Contrast strengthens text/edges; Reduce Motion removes decorative transitions. Keyboard/focus/VoiceOver, resizing and EN/RU/DE/FR expansion require native acceptance. Do not impose upstream iOS/widget metrics or custom shaders on this macOS utility.

## Resolve the previous document

Open **Rebind.sketch** through Sketch MCP. Load `mcp`, then `use`, resolve the open document by name, inspect relevant trees/styles and screenshots. Last successful save/review: **2026-10-12**, document ID `C7326969-08D8-4B1C-8899-AA9277A9763D`, SHA-256 `350bfd7cfdeb2ef9b1a2be55c748c8c224bb465c72698c15eb88fd663b565902`. IDs are lookup hints: refresh after saving/reopening. The source has **125 screen/state frames**. UI-013 completes final coverage and corrects the canvas/keycaps. The subsequent [production design review](tasks/UI-015-production-design-review.md) preserves all 125 screen IDs/names/positions and Brand, fixes reusable chips/alignment and Dark appearance, and compacts both gesture menus without redundant category headings. [Language selector contrast](tasks/UI-019-language-selector-contrast.md) subsequently refines its reusable Light/Dark materials and Foundations 14 annotation; [native adoption is integrated](verification/language-selector-refinement.md), with remaining Dark/menu/focus/adaptive acceptance open.

Sketch is saved separately from Git. If access is unavailable, request the missing connection/document and continue independent engineering; do not substitute an old PNG. Routine PNG exports and duplicate visual manuals are unnecessary. Native test results and shipped icon assets remain in Git; verification screenshots stay local by default under [WORKFLOW](WORKFLOW.md#repository-content-and-language).

## Live structure and reuse

| Page | Content |
| --- | --- |
| 01 · Screens | Named/numbered screen and state compositions; discover current IDs live |
| 02 · Foundations | Semantic colors/type; spacing/shape/material/accessibility; Advanced and Mouse behavior/localization |
| 03 · Components | Apple macOS 26 controls and Rebind patterns |
| 04 · Symbols | Live reusable Light/Dark sources |
| 05 · Brand | Editable icon/Menu Bar artwork and review boards |

Reuse existing sources, shared styles, Color Variables and **Apple macOS 26 UI Kit**. Keep imported components linked. Foundations **04 · Layout / Materials / Accessibility** owns the shape/material guidance; **05 · Advanced / Behavior & native implementation** and **06–10 · Advanced / Localization** own Advanced annotations/copy. **11 · Mouse / Behavior & accessibility** and **12–13 · Mouse / Localization** own Mouse interaction and EN/RU/DE/FR copy. **14 · Controls / Glass family & native states** owns the latest shared materials and spacing, including the superseding popup/tab treatment. **15 · Feedback / Semantic states & accessibility** owns current severity, paired reusable samples and native accessibility/persistence guidance. **16–22** own curated touch presets, action/profile recovery, new four-language copy and final runtime/menu/accessibility variants. Native panels/alerts own exact macOS appearance, focus and adaptive sizing.

## Screen index and implementation status

| Frames | Ready design scope | Native status / evidence |
| --- | --- | --- |
| 01–07 | Keyboard main Light/Dark/compact, empty/populated editor, profiles, About | Functional baseline exists; [About integrated and scoped native checks pass](verification/about-native.md). Full main material implementation/states and About accessibility variants remain |
| 08–22 | First-run, permission recovery/main banners, Settings Permissions | Integrated; [Settings feedback adoption](verification/permissions-feedback-adoption.md) checked. Actual grants/accessibility remain in [UI-001](tasks/UI-001-permissions-onboarding.md) |
| 23–32 | General/background and actual-state login/runtime errors | Integrated; [General feedback adoption](verification/general-feedback-adoption.md) reuses shared states/recovery. Login/relaunch/accessibility remain in [UI-003](tasks/UI-003-general-settings.md) |
| 33–39 | Input explanation and per-binding Hold/save failure | Integrated; [shared cards/copy adoption checked](verification/input-feedback-adoption.md). Current tap scope differs from final touch pool; physical timing/editor/accessibility remain in [UI-004](tasks/UI-004-input-settings.md) |
| 40–47 | Language System/EN/RU/DE/FR, draft/apply/menu/failure/reopen | Integrated; production relaunch/accessibility remain in [UI-005](tasks/UI-005-language-settings.md) |
| 48–69 | Advanced overview Light/Dark; RU/DE/FR compact; native import/reset confirmations; protected original/import/write/export failures; completed import/reset; validation progress; stopped/recording/unavailable/localized diagnostics | Design ready and native integration implemented in [UI-007](tasks/UI-007-advanced-settings.md), using UI-008's codec. [Software/native cancellation checks pass](verification/advanced-settings-native.md); restored-binding/runtime/accessibility acceptance remains |
| 70–89 | Mouse list Light/Dark/compact DE, empty/search states; numeric button, discrete wheel, cardinal pointer and Hold editors; input/output recording, unavailable/conflict/save failure; Dark and RU/DE/FR editors | Integrated in [UI-009](tasks/UI-009-mouse-design.md); [software/native sizing and scoped live editor checks](verification/mouse-native.md) pass. Physical capture/cancellation, accessibility and adaptive materials remain open; editor controls/capture/feedback are adopted in [UI-016](tasks/UI-016-editor-design-adoption.md); remaining list materials and broader acceptance stay open |
| 90–126 (98 removed) | Final Trackpad/Magic Mouse lists and preset editors/menus, shared action parameters/catalog/recovery, profile management, category empty/search states, Dark and localized variants | [UI-013](tasks/UI-013-design-coverage-completion.md) saved/reviewed and ready for native implementation; capability/runtime/accessibility acceptance remains separate |

Keyboard and touch compositions depict the final planned interface, without claiming current engine support. Mouse examples follow the numeric-button/discrete-wheel/cardinal-gesture scope but do not verify hardware. Use SPEC for target behavior and CAPABILITIES for actual implementation/evidence. Keep a compact profile control above categories, Settings/About below. No physical-device inventory or automatic profile activation.

The current [shared glass-control refinement](tasks/UI-011-control-unification.md) is ready for native adoption, revises the earlier [materials/consistency review](tasks/UI-006-material-design-review.md) and affects existing native Settings/navigation/editor surfaces. The subsequent [semantic-feedback revision](tasks/UI-012-semantic-feedback.md) also needs broader native adoption. [UI-017](tasks/UI-017-settings-control-adoption.md) integrates Settings navigation and Language controls/feedback; remaining Settings/main materials and accessibility acceptance stay open. Inspect current Sketch before adopting either and preserve the completed full-main sizing repair. [Compile-only feasibility evidence](verification/material-design-review.md) is separate from native appearance/accessibility. Historical design records retain behavioral/resize evidence; their old PNG copies were removed. Integrated Input/Language evidence remains [here](verification/input-language-native.md).

## Design readiness

[UI-013](tasks/UI-013-design-coverage-completion.md) closes the three remaining design packages: final touch preset editing, shared action parameters/recovery and profile/category states. The saved target interface is ready for native adoption together with UI-011/UI-012. Native integration may reveal justified platform adjustments; review them against the live source. Sketch review does not close native layout, actual permissions/input, localization/accessibility or distribution acceptance.

[UI-015](tasks/UI-015-production-design-review.md) completes the production design review of all 125 screens and 28 Foundations/Components boards, with shared corrections saved and reviewed. No design-review correction remains open; native adoption and acceptance are next.

[Plain-language copy](tasks/UI-018-human-interface-copy.md) is saved/reviewed across all 125 screens and the reusable EN/RU/DE/FR specimens. Use the current rule terminology, recording instructions, backup/recovery messages and localized diagnostics help. Existing native copy requires reconciliation with this revision; native localization/layout/accessibility acceptance remains open.

## Brand

The app icon is itself a full-bleed blue keycap with two opposing white arrows, following the macOS 26 icon grid (no inner margin). Editable geometry lives on page `05 · Brand`. [AppIcon.icon](../rebind/AppIcon.icon/) is the sole app-icon input (deep-blue fill plus `Key` and `Glyph` SVG layers composed by Icon Composer); [RebindMenuBar.imageset](../rebind/Assets.xcassets/RebindMenuBar.imageset/) is the monochrome template; the sidebar shows the running app's own icon. Details: [brand README](../assets/brand/README.md). Earlier Dock/tint checks in [BRAND-001](tasks/BRAND-001-icon-runtime.md) apply to the previous artwork and must be repeated.

## Updating this design contract

Save and review changes in Sketch; keep states, copy and annotations there. Update only this short locator/readiness index and a concise task/status note. The receiving agent reads Sketch directly. Record changed behavioral requirements in SPEC and native test results in verification; do not duplicate the visual source in Git.
