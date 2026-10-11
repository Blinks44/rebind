# macOS materials and consistency review

[UI-006](../tasks/UI-006-material-design-review.md), design-only, saved/reviewed 2026-10-11. **Current visual values, source IDs and states live in Rebind.sketch**; resolve from [DESIGN](../DESIGN.md). Routine PNG copies and the duplicated style inventory were removed on 2026-10-11. Native evidence and this compile-only probe remain.

## Findings and saved repairs

- Light/Dark Language popups now share 208×24, 6 pt smooth corners, 0.75 pt inside edges and 13 pt medium SF Pro. The 36 pt profile/action capsule is a different native control size. Capture surfaces share 12 pt corners and 1 pt edges; menu geometry is paired.
- Restored imported Apple Regular Small Liquid Glass on both profile controls. Elevated opaque Settings cards use shared appearance-aware surfaces. Sidebar edges/elevation and Dark Settings sections were repaired; compact General/Language offsets aligned.
- Audited 38 named Light/Dark source pairs with matching outer dimensions. Final Activation polish hides both decorative divider overrides in the shared Light and Dark native segmented instances; dependent Press/Hold/error references were reviewed. Foundations now explain macOS fixed/capsule/concentric families rather than one radius for all controls.

Apple's [macOS 26 design-system guidance](https://developer.apple.com/videos/play/wwdc2025/356/) retains rounded rectangles for Mini/Small/Medium and capsules for Large/XL. [Liquid Glass principles](https://developer.apple.com/videos/play/wwdc2025/219/) guide purposeful navigation/control materials. Native SwiftUI/AppKit owns system menus, focus and material adaptations; Sketch optics express design intent.

## Checks and limits

Earlier 2026-10-11 review: live recent Settings/main/editor/permission screenshots, compact translated layouts, 38 source pairs and scoped style/geometry audit. Three initial resize roundtrips restored 92 rectangles; subsequent Dark Language restored 30. These dated checks were not rerun as native tests. Static contrast calculations were representative, not certification of dynamic glass or inactive/accessibility rendering.

Earlier isolated [SwiftUI feasibility probe](material-design-review/SwiftUIFeasibility.swift) passed with Xcode 27 / Swift 6.4 / SDK 27, target `arm64-apple-macos26.0`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --sdk macosx swiftc -typecheck -swift-version 6 -target arm64-apple-macos26.0 -module-cache-path /tmp/rebind-material-module-cache docs/verification/material-design-review/SwiftUIFeasibility.swift
```

Exit 0, no diagnostics. It checks public native controls, gradients/strokes/shadows, glassEffect, glass buttons, GlassEffectContainer and accessibility environment APIs. The unavailable `glassEffect(isEnabled:)` overload is excluded. This is compile-only evidence with constant bindings, not integrated UI/runtime or minimum-OS execution.

Final control-shape/Advanced save: all **2,323** pre-polish local nodes and all **47** previous screen rectangles preserved, Brand page identical, saved ZIP CRC passes. Advanced adds 22 screen/state compositions and self-contained behavior/localization boards. Affected compositions were reviewed through live MCP screenshots, including Hold/save failure and localized diagnostics; German footer clipping and blocked-state guidance were fixed.

## Receiving implementation and remaining checks

Read live Sketch and preserve the existing full-main Settings sizing repair. Use native NavigationSplitView, Buttons/Picker/Table, semantic fonts/colors and macOS glass; clip decorative backgrounds without cutting focus rings/popovers. Verify active/inactive themes, native resizing/navigation, translated feedback, keyboard/VoiceOver, Reduce Transparency/Motion and Increase Contrast. No app source, runtime/hardware/configuration/grant change, new build or Git commit by this design follow-up. Next design package: Mouse rules and editor.
