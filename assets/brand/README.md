# Rebind app icon

## Menu Bar template

`Rebind-MenuBar.svg` is the monochrome optical mark from the live Sketch Small source, on an 18 × 18 pt transparent canvas with a 16 pt silhouette. The production vector PDF is in `rebind/Assets.xcassets/RebindMenuBar.imageset`, with template rendering and vector preservation enabled. `MenuBarExtra` now uses this named asset; macOS supplies its color. `Rebind-MenuBar-preview.png` shows actual-size light/dark contexts and enlarged geometry. This asset is independent of Icon Composer/Dock delivery.

Editable source: **04 · Symbols → Rebind/Brand/Menu Bar Template**, ID `0F0BD265-F8D6-4405-8425-247D8DA43C06`; review board: **05 · Brand → 02 · Rebind / Menu Bar Template**. Debug/Release builds and native AppKit resource checks pass (18 pt, `isTemplate == true`). Live menu after relaunch and macOS 26 remain manual checks. See [verification](../../docs/verification/menu-bar-onboarding.md).

## Dock / Finder

The app uses `rebind/AppIcon.icon`, created and saved in Apple's Icon Composer on 2026-10-10. The synchronized `rebind` folder includes it in the app target; both configurations already select `AppIcon`. Final Debug/Release builds pass, and the extracted ICNS contains the new artwork. The obsolete PNG catalog and reference copy were removed on 2026-10-10; the native package is the only app-icon input.

Sketch remains the editable geometry/visual reference: page **05 · Brand**, Frosted/Small sources on **04 · Symbols**. Composer owns delivery materials, system mask and appearance settings. See [integration verification](../../docs/verification/app-icon-composer.md).

- `Rebind-AppIcon.svg` / `.pdf`: refreshed static Frosted visual reference.
- `Rebind-AppIcon-Small.svg`: refreshed optical reference; not a separately selected Composer rendition.
- `composer/Command.svg`: transparent 1024-square canvas, clean white vector mark from current Sketch geometry; no lighting.
- `composer/Background.svg`: opaque full-bleed current color gradients, no corner mask, white glaze, rim or shadow.
- `preview.png`: native Default, generation 26, 256 pixels.

The native package contains local copies of both SVG inputs; no external or temporary-file dependency. Foreground group is centered at 123%, preserving the mark's proportion when replacing the static 96-point inset body with a full-bleed system background. Automatic specular, 30% neutral shadow; blur/refraction/translucency off. Background glass effects off, with zero image opacity in Dark/Mono; those variants use system backgrounds and System Light foregrounds.

For revisions, edit geometry in Sketch, export clean vectors, replace Composer layers, inspect appearances/small sizes, save `rebind/AppIcon.icon`, and run `scripts/dev.sh build` / `release`. Do not import the decorated static SVG as a foreground or bake a corner mask. [Apple's workflow](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer).

The pre-refinement PNG sets formerly in the app asset catalog and `docs/references` were removed. Xcode generates representations from `.icon`; the clean inputs in `assets/brand/composer` byte-match the package’s local SVG copies. Finder was inspected on the development host; live Dock after relaunch, minimum-OS runtime and user's tint settings remain manual checks.
