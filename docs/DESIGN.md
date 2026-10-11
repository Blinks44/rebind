# Rebind — design direction and live source index

Updated 2026-10-11. [SPEC](SPEC.md) owns required behavior. **Sketch owns the visual design, components, states, product copy and interaction annotations.** This file is a short locator and readiness index; implementation agents inspect the live source directly through MCP.

## Direction: modern macOS 26+

Use purposeful Liquid Glass for navigation/profile controls and overlays; raised opaque content surfaces, subtle lighting and gradients provide depth without obscuring dense rules. Preserve native SwiftUI/AppKit semantics, SF Pro/SF Symbols, system menus/focus and desktop density. Avoid indiscriminate blur, stacked glass and decorative animation. Do not flatten the agreed material direction into generic Settings merely because default styling is easier.

Consistency is defined by control family and size, not one radius everywhere. Apple's macOS 26 Mini/Small/Medium controls retain rounded rectangles; Large/XL use capsules. Current Sketch references use a 24 pt Medium popup with 6 pt corners, 36 pt capsule profile/action controls, 12 pt Settings/capture surfaces, 16 pt window/sidebar corners and 8 pt navigation selection. Light/Dark share each family's geometry, type and spacing. Activation uses one selected capsule without decorative separators. See [Apple's design-system guidance](https://developer.apple.com/videos/play/wwdc2025/356/).

Use semantic colors and adaptive materials. Reduce Transparency preserves layout with opaque surfaces; Increase Contrast strengthens text/edges; Reduce Motion removes decorative transitions. Keyboard/focus/VoiceOver, resizing and EN/RU/DE/FR expansion require native acceptance. Do not impose upstream iOS/widget metrics or custom shaders on this macOS utility.

## Resolve the current document

Open **Rebind.sketch** through Sketch MCP. Load `mcp`, then `use`, resolve the open document by name, inspect relevant trees/styles and screenshots. Last successful save/review: **2026-10-11**, document ID `F0E1F058-46EC-4EA3-A36F-5F5B2346B039`, SHA-256 `c945a334a43de30c12251555cb60ffcc2566f7bb85f9fe39d556b572f307515e`. IDs are lookup hints: refresh after saving/reopening. The source has **69 screen/state frames**; all 47 previous screens and their IDs remain, Brand is unchanged.

Sketch is saved separately from Git. If access is unavailable, request the missing connection/document and continue independent engineering; do not substitute an old PNG. Routine PNG exports and duplicate visual manuals are unnecessary. Native test results and shipped icon assets remain in Git; verification screenshots stay local by default under [WORKFLOW](WORKFLOW.md#repository-content-and-language).

## Live structure and reuse

| Page | Content |
| --- | --- |
| 01 · Screens | Named/numbered screen and state compositions; discover current IDs live |
| 02 · Foundations | Semantic colors/type; spacing/shape/material/accessibility; Advanced behavior and localization |
| 03 · Components | Apple macOS 26 controls and Rebind patterns |
| 04 · Symbols | Live reusable Light/Dark sources |
| 05 · Brand | Editable icon/Menu Bar artwork and review boards |

Reuse existing sources, shared styles, Color Variables and **Apple macOS 26 UI Kit**. Keep imported components linked. Foundations **04 · Layout / Materials / Accessibility** owns the shape/material guidance; **05 · Advanced / Behavior & native implementation** owns the new flow/state annotations; **06–10 · Advanced / Localization** own its EN/RU/DE/FR copy. Native panels/alerts own exact macOS appearance, focus and adaptive sizing.

## Screen index and implementation status

| Frames | Ready design scope | Native status / evidence |
| --- | --- | --- |
| 01–07 | Keyboard main Light/Dark/compact, empty/populated editor, profiles, About | Functional baseline exists; full main/About material implementation and states remain |
| 08–22 | First-run, permission recovery/main banners, Settings Permissions | Integrated; actual grants/accessibility remain in [UI-001](tasks/UI-001-permissions-onboarding.md) |
| 23–32 | General/background and actual-state login/runtime errors | Integrated; login/relaunch/accessibility remain in [UI-003](tasks/UI-003-general-settings.md) |
| 33–39 | Input explanation and per-binding Hold/save failure | Integrated; physical timing/editor/accessibility remain in [UI-004](tasks/UI-004-input-settings.md) |
| 40–47 | Language System/EN/RU/DE/FR, draft/apply/menu/failure/reopen | Integrated; production relaunch/accessibility remain in [UI-005](tasks/UI-005-language-settings.md) |
| 48–69 | Advanced overview Light/Dark; RU/DE/FR compact; native import/reset confirmations; protected original/import/write/export failures; completed import/reset; validation progress; stopped/recording/unavailable/localized diagnostics | Design ready in [UI-007](tasks/UI-007-advanced-settings.md). [UI-008](tasks/UI-008-advanced-storage.md) supplies the backup codec; native transactions/panels and acceptance remain |

The Work example contains unsupported action/input examples. Use it for hierarchy/materials; source and CAPABILITIES determine actual selectable functionality. Keep a compact profile control above categories, Settings/About below. No physical-device inventory or automatic profile activation.

The saved [materials/consistency review](tasks/UI-006-material-design-review.md) affects existing native Settings/navigation/editor surfaces. Inspect current Sketch before adopting it and preserve the completed full-main sizing repair. [Compile-only feasibility evidence](verification/material-design-review.md) is separate from native appearance/accessibility. Historical design records retain behavioral/resize evidence; their old PNG copies were removed. Integrated Input/Language evidence remains [here](verification/input-language-native.md).

## Remaining design coverage

Advanced is complete within UI-007's bounded design scope. Roughly **four substantial packages** remain; frame count is not a completion percentage:

| Package | Remaining outcome |
| --- | --- |
| **Mouse rules and editor — next** | Category list/empty states, wheel, numeric extra buttons, button-held cardinal gestures and conditional capture/activation |
| Trackpad / Magic Mouse | Available/experimental/unavailable presets and conflict/capture guidance based on actual acquisition/support; broader scope depends on research/hardware |
| Editor/action validation | Recording/cancel/conflict/unsupported states and action-specific app/URL/file/Shortcuts choices/failures |
| Empty/profile states and cross-screen review | No rules/search results, profile CRUD/limits/errors, remaining Dark/localized feedback, About and accessibility material variants |

Reuse existing sources and inspect implementation before declaring behavior missing. Sketch review does not close native layout, actual permissions/input, localization/accessibility or distribution acceptance.

## Brand: existing source and delivered assets

Editable Brand sources remain on Symbols/Brand: Frosted app-icon `AA064C59-AD8E-40E1-A7DF-DF7F6949C136`, Small optical version `5E88F8C5-D3D4-40EB-AD5B-D459FFECFD54`, Menu Bar `0F0BD265-F8D6-4405-8425-247D8DA43C06`. Keep size-specific UI border styles when using existing icons at 32/48/80 pt.

[AppIcon.icon](../rebind/AppIcon.icon/) is the sole native app-icon input; [RebindMenuBar.imageset](../rebind/Assets.xcassets/RebindMenuBar.imageset/) is the separate monochrome template. Sketch owns geometry; Icon Composer owns delivery materials/masking/appearances. Assets are delivered; remaining Dock/tint/minimum-OS checks in [BRAND-001](tasks/BRAND-001-icon-runtime.md) do not mean the icons need recreating. Details: [brand README](../assets/brand/README.md).

## Updating this design contract

Save and review changes in Sketch; keep states, copy and annotations there. Update only this short locator/readiness index and a concise task/status note. The receiving agent reads Sketch directly. Record changed behavioral requirements in SPEC and native test results in verification; do not duplicate the visual source in Git.
