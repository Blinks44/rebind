# Native app-icon integration — 2026-10-10

Routine capture files were moved to ignored local storage during repository cleanup on 2026-10-11. The dated observations, commands and acceptance limits below are preserved; these images are not automated test baselines.

Scope: SPEC §10 Application icon / PLAN Phase 8. User authorized delivery of the finished Sketch icon through Icon Composer and Xcode. No app logic, rules, configuration, permissions or engine behavior changed.

## Delivery

Created and saved `rebind/AppIcon.icon` through Icon Composer UI. User accepted the first-launch Apple license directly. macOS only; watchOS disabled. Existing synchronized source folder and `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` include it; no project edit required.

Sketch MCP refreshed Frosted SVG/PDF and Small SVG, plus clean Command and full-bleed Background SVGs from current geometry/materials. Temporary export frames removed; source artwork preserved. An initial temporary foreground export included an Artboard background; corrected to transparent before package delivery. Package SVGs byte-match final clean inputs; no bitmaps/fonts/filters.

Foreground centered at 123%, preserving its proportion relative to the inset static body; automatic specular, 30% neutral shadow, no blur/refraction/translucency. Background has no glass/specular/shadow/translucency. Background image opacity zero for Dark/Mono, with system backgrounds and System Light foregrounds. This fixes the initially observed blue-on-pale Dark combination. Native tint hue/strength remain system-controlled.

## Verification

- `scripts/dev.sh doctor`: Xcode 27.0 (27A266a), Swift 6.4, SDK 27.0; Apple Silicon macOS 27.0.1. Deployment 26.0 retained.
- Final `scripts/dev.sh build` / `release`: **BUILD SUCCEEDED**. Logs `/tmp/rebind-composer-integration/{build-final,release-final}.log`. Initial sandboxed asset build failed because icon renderer could not open the package; approved outside-sandbox builds passed. No final asset errors. Existing AppIntents metadata-skip warning remains.
- Debug/Release strict/deep codesign checks pass; Release `x86_64 arm64`. Stable bundle `blinks44.rebind`, icon name/file `AppIcon`, minimum OS 26.0, nonempty `AppIcon.icns`/`Assets.car` verified.
- Release ICNS extracted with `iconutil`; inspected 256-pixel representation, confirming new Composer artwork rather than old catalog PNGs.
- Bundled Apple `ictool` exported generation-26 Default/Dark/TintedLight/TintedDark/ClearLight/ClearDark at 256 px; Default/Dark/TintedDark at 16/32 px; TintedLight at 32 px; Default at 64 px. Dimensions/transparent corners pass. Default/Dark generation-27 exports also produced; Default inspected.
- Live Composer composition/appearance screenshots inspected. Finder Get Info for the actual Debug app shows new header and large preview. No app launch or engine activation.
- JSON parses; local image references, copied SVG identity, platform/scale/shadow/appearance overrides pass. `plutil -lint` does not accept this JSON as a property list; JSON validation used instead. No behavioral tests for asset-only integration.

Appearance exports were inspected during the dated checks above; the capture copy is now local.

Tint previews use renderer defaults and do not guarantee contrast for every user hue/strength. Very dark tints reduce small-size contrast; user's actual tint remains a manual check. Actual Dock after relaunch and macOS 26/Intel execution unverified. No global cache resets or Dock restarts.

Evidence: `/tmp/rebind-composer-integration/`, including pre-export brand backup, renderer outputs, source/package manifests and build logs. Next: rebuild the user's Xcode copy and inspect Dock after normal relaunch, then confirm minimum-OS appearance.

## Sole-source cleanup and fresh artifact verification — 2026-10-10

Baseline `6c1a5be` already includes the new native package and both configurations select `AppIcon`. The clean `assets/brand/composer` foreground/background SVGs byte-match the package copies. Read-only Sketch inspection resolved the current Rebind document and Frosted source `AA064C59-AD8E-40E1-A7DF-DF7F6949C136`; source screenshot and the brand preview confirm the existing white Command mark/blue background. No geometry, materials or Sketch content was edited.

At the user's request, deleted the superseded `docs/references/Rebind-AppIcon.appiconset` and the duplicate `rebind/Assets.xcassets/AppIcon.appiconset` (11 files each). The native package is the sole icon input. The separate Menu Bar template and other brand sources are preserved; no project-setting change was needed.

Fresh `scripts/dev.sh build` / `scripts/dev.sh release` both report **BUILD SUCCEEDED**. Asset compiler commands select `--app-icon AppIcon` with `rebind/AppIcon.icon`, with no icon warning or error. Only the existing unused AppIntents metadata extraction warning remains. Both bundles pass `codesign --verify --deep --strict`; Release is `x86_64 arm64`. Info.plist retains `blinks44.rebind`, icon name/file `AppIcon` and minimum OS `26.0`.

Extracted each built `AppIcon.icns` with `iconutil -c iconset`. The 256-pixel rendition is named `icon_128x128@2x.png`; its appearance was inspected and the Debug/Release copies are byte-identical (SHA-256 `88c961bd98fbb1a69489701773eafb96cf982d8220f6f241ed7ee5ab9c003f66`). This confirms actual artifact delivery without relying on an old asset preview. `git diff --check` passes. Asset-only cleanup did not rerun behavioral tests or start the input engine; the previously recorded 479 tests are historical evidence.

Dock/live Menu Bar after normal user relaunch, actual tint and macOS 26/Intel runtime remain open. No application launch, cache reset, Dock restart, rules/permissions changes or commits were performed for this cleanup. See [BRAND-001](../tasks/BRAND-001-icon-runtime.md).
## Stale-icon report and scoped refresh — 2026-10-10

The user reports an old icon despite sole-source delivery. Re-inspected actual artifacts rather than replacing artwork: clean brand/package SVGs still match, fresh repository/Xcode Debug copies have identical AppIcon.icns (SHA-256 `0642c4bbbde096b95b588c1f9880fdc161fcaf387df4fe20aef8233cf6d42d91`) and both bundle icon keys remain `AppIcon`. A separate older Xcode DerivedData bundle contains different icon resources; the previously tested running path was not supplied. Read-only process/app inventory found no active Rebind instance during this inspection.

Finder Get Info for the repository Debug bundle visibly shows the delivered Command-mark icon in both header and preview. Bundle directory modification time still predated fresh internal-resource builds. Applied a scoped registration refresh:

```sh
touch build/DerivedData/Build/Products/Debug/Rebind.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f build/DerivedData/Build/Products/Debug/Rebind.app
killall Dock
```

The same touch/force-registration operations were applied to the identified fresh Xcode Debug copy. Commands completed successfully. Dock was restarted once; no Dock preference/global icon-cache deletion, Xcode DerivedData removal, artwork change, app launch, input operation or permission mutation. Final Debug test build and Release build/signatures are recorded with [INPUT-001](../tasks/INPUT-001-four-finger-tap.md).

This verifies new bundle resources/Finder and completion of the scoped refresh, **not** Dock's icon after a fresh Rebind launch. User confirmation of the exact running bundle/location remains required before declaring the stale-icon symptom resolved. [BRAND-001](../tasks/BRAND-001-icon-runtime.md).
