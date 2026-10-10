# Rebind app icon

**2026-10-10:** the live Sketch Frosted/Small sources were refined for upper contrast and consistent materials. The SVG/PDF/PNG files in this repository still contain the prior appearance; refresh them directly from Sketch during the next export/integration pass. See `docs/verification/app-icon-review.md` for completed design changes and verification.

The editable design lives in `Rebind.sketch`: page **05 · Brand**, with the two linked sources on **04 · Symbols**. Paths, gradients and elevation are vector geometry; there are no embedded images, live fonts or SVG filters.

- `Rebind-AppIcon.svg` / `.pdf`: 1024 × 1024 canvas, frosted blue background and raised white Command mark.
- `Rebind-AppIcon-Small.svg`: optical variant with wider counters and stronger contrast for the 16 and 32 pt AppIcon slots, at both 1× and 2×.
- `composer/Background.svg`: opaque full-bleed background without a baked corner mask.
- `composer/Command.svg`: outlined white foreground without baked lighting, for native effects in Icon Composer.

The application's currently selected asset is `rebind/Assets.xcassets/AppIcon.appiconset`, containing all ten macOS PNG slots of the pre-refinement artwork. `docs/references/Rebind-AppIcon.appiconset` mirrors those exports. The files under `assets/brand` are design/export resources; Xcode does not select them directly.

## Export paths for Xcode

For the existing static PNG workflow, export directly from the appropriate 1024-point Sketch source at `target pixels / 1024`; do not resize an earlier PNG. Keep the canvas untrimmed to preserve this artwork's 96-point body inset. That inset belongs to this static design and must not be copied into a full-bleed Icon Composer background.

For a layered icon with controlled Liquid Glass effects and appearances, follow [Apple's Icon Composer workflow](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer):

1. Prepare square 1024 × 1024 SVG layers with clear vector edges and no baked corner mask. Keep foreground geometry, background and system-rendered effects separate.
2. `composer/Command.svg` already supplies a clean, unlit outlined foreground; its geometry still matches the refined main mark. `composer/Background.svg` has a full-bleed opaque base, but its palette and white wash are from the old artwork. Refresh the palette and recreate lighting/opacity in Composer. Prefer Composer's background color/gradient controls where sufficient; an imported custom background must stay full-bleed and opaque.
3. Import the clean foreground, set background/material/lighting in Composer and inspect default, dark, mono/clear/tinted and actual small-size previews. Align the mark using the current Apple template; do not import the fully decorated `Rebind-AppIcon.svg` as a single foreground layer.
4. Save a file such as `AppIcon.icon`, add it to the Xcode target and select its filename without extension in the target's App Icon setting. A selected Composer file replaces the existing icon asset catalog for icon generation; Xcode renders the representations at build time.

Apple supports both an [icon asset catalog and an Icon Composer file](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution). The current PNG catalog is a valid static delivery path, but no `.icon` package has been created or integrated, and native appearance/Dock/Finder acceptance remains open. These preparation checks are not an Icon Composer import/build verification.
