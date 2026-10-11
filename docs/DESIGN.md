# Rebind — design direction and live source index

Updated 2026-10-11. [SPEC](SPEC.md) owns required behavior. **Sketch owns the visual design, components, states, product copy and interaction annotations.** This file is a short locator and readiness index; implementation agents inspect the live source directly through MCP.

Design the final planned release, including Trackpad and Magic Mouse. User clarification on 2026-10-11: temporary implementation gaps (such as four-finger-only or not-yet-implemented placeholders) are not target product states. Remove or replace those specimens under [UI-013](tasks/UI-013-design-coverage-completion.md). Keep genuine device compatibility, permissions, conflicts and recovery states. Target design does not claim current implementation or hardware verification; those facts remain in CAPABILITIES and verification.

## Direction: modern macOS 26+

Use purposeful Liquid Glass for navigation/profile controls and overlays; raised opaque content surfaces, subtle lighting and gradients provide depth without obscuring dense rules. Preserve native SwiftUI/AppKit semantics, SF Pro/SF Symbols, system menus/focus and desktop density. Avoid indiscriminate blur, stacked glass and decorative animation. Do not flatten the agreed material direction into generic Settings merely because default styling is easier.

Consistency is defined by control role and size. The saved [glass-control refinement](tasks/UI-011-control-unification.md) uses 36 pt capsule form/profile/action selectors, a compact 24 pt glass capsule for Settings Language, one glass Activation track and one inset glass Settings-tab track. Secondary actions share subtle glass lighting and semantic accent wash. Raised Settings/capture surfaces retain 12 pt corners, window/sidebar 16 pt and navigation selection 8 pt. Light/Dark share geometry, type and spacing; avoid stacking appearance materials. The refinement supersedes the earlier flat Medium-popup direction. Native control semantics and sizing remain required; see [Apple's design-system guidance](https://developer.apple.com/videos/play/wwdc2025/356/).

The saved [semantic-feedback system](tasks/UI-012-semantic-feedback.md) makes failures red, prerequisites/conflicts amber, completed operations green and information/progress blue. Use a calm opaque state surface, native icon and explicit title; preserve readable body copy and accent-colored recovery controls. Deliberate pause, empty and disabled states remain neutral. Foundations 15 applies to all subsequent design, including remaining profile/action/gesture states.

Trackpad and Magic Mouse use one glass selector of complete, curated gesture presets followed by the shared action editor. No touch trigger recording or separate type/finger/direction selectors. Keyboard/conventional Mouse keep their trigger recorders; output-shortcut recording is available to every category. This 2026-10-11 product decision supersedes the initial UI-013 touch recording compositions; SPEC and the project-local design skill carry the behavioral rule.

Use semantic colors and adaptive materials. Reduce Transparency preserves layout with opaque surfaces; Increase Contrast strengthens text/edges; Reduce Motion removes decorative transitions. Keyboard/focus/VoiceOver, resizing and EN/RU/DE/FR expansion require native acceptance. Do not impose upstream iOS/widget metrics or custom shaders on this macOS utility.

## Resolve the current document

Open **Rebind.sketch** through Sketch MCP. Load `mcp`, then `use`, resolve the open document by name, inspect relevant trees/styles and screenshots. Last successful save/review: **2026-10-11**, document ID `A610E1D4-B7CF-4D5D-9357-1292E3177726`, SHA-256 `fa4897163d679b783e139ef2ffc5c98a749e6c53a2f0efb7c9ceeb85c4349a46`. IDs are lookup hints: refresh after saving/reopening. The source has **89 screen/state frames**. The current feedback revision preserves all existing IDs/text, screen names/bounds and Brand; the preceding control revision refined Mouse editor heights/canvas spacing.

Sketch is saved separately from Git. If access is unavailable, request the missing connection/document and continue independent engineering; do not substitute an old PNG. Routine PNG exports and duplicate visual manuals are unnecessary. Native test results and shipped icon assets remain in Git; verification screenshots stay local by default under [WORKFLOW](WORKFLOW.md#repository-content-and-language).

## Live structure and reuse

| Page | Content |
| --- | --- |
| 01 · Screens | Named/numbered screen and state compositions; discover current IDs live |
| 02 · Foundations | Semantic colors/type; spacing/shape/material/accessibility; Advanced and Mouse behavior/localization |
| 03 · Components | Apple macOS 26 controls and Rebind patterns |
| 04 · Symbols | Live reusable Light/Dark sources |
| 05 · Brand | Editable icon/Menu Bar artwork and review boards |

Reuse existing sources, shared styles, Color Variables and **Apple macOS 26 UI Kit**. Keep imported components linked. Foundations **04 · Layout / Materials / Accessibility** owns the shape/material guidance; **05 · Advanced / Behavior & native implementation** and **06–10 · Advanced / Localization** own Advanced annotations/copy. **11 · Mouse / Behavior & accessibility** and **12–13 · Mouse / Localization** own Mouse interaction and EN/RU/DE/FR copy. **14 · Controls / Glass family & native states** owns the latest shared materials and spacing, including the superseding popup/tab treatment. **15 · Feedback / Semantic states & accessibility** owns current severity, paired reusable samples and native accessibility/persistence guidance. Native panels/alerts own exact macOS appearance, focus and adaptive sizing.

## Screen index and implementation status

| Frames | Ready design scope | Native status / evidence |
| --- | --- | --- |
| 01–07 | Keyboard main Light/Dark/compact, empty/populated editor, profiles, About | Functional baseline exists; [About integrated and scoped native checks pass](verification/about-native.md). Full main material implementation/states and About accessibility variants remain |
| 08–22 | First-run, permission recovery/main banners, Settings Permissions | Integrated; actual grants/accessibility remain in [UI-001](tasks/UI-001-permissions-onboarding.md) |
| 23–32 | General/background and actual-state login/runtime errors | Integrated; login/relaunch/accessibility remain in [UI-003](tasks/UI-003-general-settings.md) |
| 33–39 | Input explanation and per-binding Hold/save failure | Integrated; physical timing/editor/accessibility remain in [UI-004](tasks/UI-004-input-settings.md) |
| 40–47 | Language System/EN/RU/DE/FR, draft/apply/menu/failure/reopen | Integrated; production relaunch/accessibility remain in [UI-005](tasks/UI-005-language-settings.md) |
| 48–69 | Advanced overview Light/Dark; RU/DE/FR compact; native import/reset confirmations; protected original/import/write/export failures; completed import/reset; validation progress; stopped/recording/unavailable/localized diagnostics | Design ready and native integration implemented in [UI-007](tasks/UI-007-advanced-settings.md), using UI-008's codec. [Software/native cancellation checks pass](verification/advanced-settings-native.md); restored-binding/runtime/accessibility acceptance remains |
| 70–89 | Mouse list Light/Dark/compact DE, empty/search states; numeric button, discrete wheel, cardinal pointer and Hold editors; input/output recording, unavailable/conflict/save failure; Dark and RU/DE/FR editors | Integrated in [UI-009](tasks/UI-009-mouse-design.md); [software/native sizing and scoped live editor checks](verification/mouse-native.md) pass. Physical capture/cancellation, accessibility and adaptive materials remain open; the released UI-011 shared-material refinement needs native adoption |

The earlier Keyboard Work example contains unsupported action/input examples. Mouse examples follow the current numeric-button/discrete-wheel/cardinal-gesture scope but do not verify hardware. Use source and CAPABILITIES to determine actual selectable functionality. Keep a compact profile control above categories, Settings/About below. No physical-device inventory or automatic profile activation.

The current [shared glass-control refinement](tasks/UI-011-control-unification.md) is ready for native adoption, revises the earlier [materials/consistency review](tasks/UI-006-material-design-review.md) and affects existing native Settings/navigation/editor surfaces. The subsequent [semantic-feedback revision](tasks/UI-012-semantic-feedback.md) also needs native adoption; prior native screenshots predate it. Inspect current Sketch before adopting either and preserve the completed full-main sizing repair. [Compile-only feasibility evidence](verification/material-design-review.md) is separate from native appearance/accessibility. Historical design records retain behavioral/resize evidence; their old PNG copies were removed. Integrated Input/Language evidence remains [here](verification/input-language-native.md).

## Remaining design coverage

Advanced and Mouse are released within their bounded design scopes. Roughly **three substantial packages** remain; frame count is not a completion percentage:

| Package | Remaining outcome |
| --- | --- |
| **Trackpad / Magic Mouse — in progress** | Final planned gesture lists, one curated preset selector, shared actions and real compatibility/conflict/recovery states; no touch trigger recording or temporary implementation placeholders |
| Editor/action validation | Action-specific app/URL/file/Shortcuts choices/failures and remaining unsupported/disabled states; Mouse trigger recording/conflict is released |
| Empty/profile states and cross-screen review | Other categories' empty/search states, profile CRUD/limits/errors, remaining Dark/localized feedback, About and accessibility material variants |

Reuse existing sources and inspect implementation before declaring behavior missing. Sketch review does not close native layout, actual permissions/input, localization/accessibility or distribution acceptance.

## Brand: existing source and delivered assets

Editable Brand sources remain on Symbols/Brand: Frosted app-icon `AA064C59-AD8E-40E1-A7DF-DF7F6949C136`, Small optical version `5E88F8C5-D3D4-40EB-AD5B-D459FFECFD54`, Menu Bar `0F0BD265-F8D6-4405-8425-247D8DA43C06`. Keep size-specific UI border styles when using existing icons at 32/48/80 pt.

[AppIcon.icon](../rebind/AppIcon.icon/) is the sole native app-icon input; [RebindMenuBar.imageset](../rebind/Assets.xcassets/RebindMenuBar.imageset/) is the separate monochrome template. Sketch owns geometry; Icon Composer owns delivery materials/masking/appearances. Assets are delivered; remaining Dock/tint/minimum-OS checks in [BRAND-001](tasks/BRAND-001-icon-runtime.md) do not mean the icons need recreating. Details: [brand README](../assets/brand/README.md).

## Updating this design contract

Save and review changes in Sketch; keep states, copy and annotations there. Update only this short locator/readiness index and a concise task/status note. The receiving agent reads Sketch directly. Record changed behavioral requirements in SPEC and native test results in verification; do not duplicate the visual source in Git.
