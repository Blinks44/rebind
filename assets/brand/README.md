# Rebind brand assets

Updated 2026-10-13. The app icon is itself a full-bleed blue keycap with two opposing white arrows: the artwork reaches the edges of the macOS 26 icon shape, with no inner margin.

- **App icon:** `rebind/AppIcon.icon` is the only app-icon input. It is an Icon Composer package: a deep-blue automatic gradient fill (the key body) with two 1024-square SVG layers, `Key` (the lighter top face) and `Glyph` (the arrows). Xcode renders all sizes and appearances from it. Open the package in Icon Composer to tune Dark, tinted or glass settings.
- **Menu Bar:** `rebind/Assets.xcassets/RebindMenuBar.imageset/RebindMenuBar.svg` is an 18 pt monochrome template derived from the same mark; macOS supplies its color.
- **In-app logo:** the sidebar shows the running app's own icon, so there is no separate logo asset.
- **Editable source:** page `05 · Brand` in **Rebind - new.sketch**.

For revisions, edit the geometry in Sketch, update the SVG layers, then run `scripts/dev.sh build` and inspect `Rebind.app/Contents/Resources/AppIcon.icns`. Do not bake a corner mask, shadow or background into the layers; the system adds them.
