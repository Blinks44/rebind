# Rebind app-icon review — 2026-10-09

Scope: SPEC §10 Application icon / PLAN Phase 8. Reviewed the live `Rebind.sketch`, page `05 · Brand`, both linked 1024-point sources on `04 · Symbols`, all ten application PNG slots, mirror exports, Composer inputs and Xcode icon selection. This is a review; artwork and application assets were not modified.

## Follow-up — Sketch refinement completed 2026-10-10

Subsequent authorized delivery: refined SVG/PDF exports are refreshed and integrated as native `rebind/AppIcon.icon`; Debug/Release builds and actual Finder preview pass. See [Composer verification](app-icon-composer.md). Historical PNGs retained; live Dock/minimum-OS/user-tint acceptance remains open.

The user authorized refinement in Sketch. Corrected the first two P2 findings in the live sources: reduced the upper white wash, strengthened the pale blue surface behind the white mark, and synchronized base, blue light, rim and face through four shared Brand styles. Small retains wider counters and a 20% optical contrast compensation coat instead of its former unrelated saturated background. Reduced Frosted's raised edge from 12 to 8 source units and softened the two vector ambient-depth layers to opacity 0.064 / 0.104.

Both source and symbol IDs remain stable; all ten linked placements update. Direct exports at 16/32/64/128 pixels, equal-size before/after diagnostics, and post-save live screenshots of the Brand board verify the result on pale and dark backdrops. Saved `Rebind.sketch`, final document ID `10246E46-59D2-4110-95FB-7576E75168A9`. Saved ZIP CRC, Symbol/shared-style references, local ID uniqueness, finite frames and finite opacity values pass. Sources remain editable vectors.

Evidence: `/tmp/rebind-icon-refinement/iteration.png`, eight size exports and `integrity.json`; pre-edit backup `/tmp/rebind-icon-refinement-before.sketch`. An additional 256-pixel/Brand export did not execute because automatic approval review hit a usage limit; the saved artwork and post-save MCP screenshots were verified independently. No bypass attempted.

This follow-up changes the Sketch artwork only. Repository SVG/PDF/PNG assets still contain the previous appearance and need an explicit export/integration pass from these refined sources. The native appearance/Dock/Finder acceptance finding remains open; the Command-based silhouette is retained. No app build/tests, configuration, permissions or rules changed. Original findings and export checks below describe the pre-refinement review.

## Findings

### P2 — Main symbol loses definition against the pale upper background

Source: `AA064C59-AD8E-40E1-A7DF-DF7F6949C136`, `Rebind/Brand/App Icon / Frosted`.

At 64 and 128 pixels, the upper white loops have much less separation from the background than the lower loops. On a pale desktop, the top edge of the icon also recedes. The image remains recognizable, but the visual weight concentrates in the blue lower-left corner; part of the mark depends on its cast depth for definition.

Suggested correction: keep the light, raised mark and blue palette, but lower the background luminance behind the upper loops, reduce the white wash locally and recheck at actual size. Preserve the light base required by the spec. Do not solve this by adding a heavy black outline.

### P2 — Optical variants change the material and palette too much

Source: `5E88F8C5-D3D4-40EB-AD5B-D459FFECFD54`, `Rebind/Brand/App Icon / Small 16–32`.

The wider counters and reduced depth help at 16 pixels. However, Small also replaces the pale frosted background with a considerably more saturated blue and makes the face uniformly white. Comparing both sources at the same 64-pixel size makes the difference clear. The 32 pt @2× slot actually contains this 64-pixel Small artwork, while the 128-pixel slots use Frosted. Appearance can therefore vary with the selected representation; exact Dock/Finder selection was not measured.

Suggested correction: preserve the shared background hue, lighting direction and material character; make the Small differences primarily optical geometry and reduced fine detail. Some contrast compensation is useful, but the variants should still read as the same icon.

### P2 — Native icon appearances have not been accepted

The target selects `AppIcon` in a conventional asset catalog. There is no integrated `.icon` package. Prepared Composer inputs already separate an opaque full-bleed background and an unlit foreground. The Brand page's “Same artwork on a dark desktop” is a backdrop preview, not an independently designed dark appearance.

This is a remaining verification/delivery step, not evidence that the current PNG icon fails to load. [Apple's current icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons/) recommends layered vector inputs, system-managed effects and appearance previews. Use the clean Composer inputs for that workflow; avoid layering system highlights and depth on top of the Frosted source's baked effects. Test on the macOS 26 minimum as well as the development host before switching the app's icon source.

### P3 — The mark communicates keyboard shortcuts more strongly than Rebind's identity

The centered Command shape is recognizable and appropriate for an input utility. As a branding judgment, the familiar ⌘ alone provides little distinctive expression of switching/remapping. This is not a geometry or export defect.

Suggested direction: retain the simple Command-based silhouette and consider one restrained, legible feature suggesting a changed connection. Avoid stacking arrows, mouse, keyboard and lettering into the same mark. Compare any refinement at 16/32/64 pixels before selecting it.

## What passes

- Both live sources are editable vector geometry, with no bitmap or text layers and no native shadows or blur filters. The Command mark uses filled outlined shapes; depth is constructed from additional vector shapes.
- Centered mark, consistent square canvas, 96-point body inset, clean rounded body and no text. The Small source has wider counters: 108.16 source units versus 88 in Frosted; at 16 pixels this is approximately 1.69 versus 1.38 pixels.
- All ten PNG files have the expected dimensions, transparent corner pixels and RGBA mode. Every PNG matches a fresh export from its corresponding live Sketch source pixel for pixel; all mirror files are byte-identical.
- Application Xcode configurations select `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`; deployment target remains macOS 26.0. Prior successful icon builds are recorded in PLAN; they were not rerun for this read-only artwork review.

## Evidence and limits

Visual checks: live MCP screenshots of the Brand board and both sources; fresh direct exports at 16/32/64/128 pixels, plus Frosted at 256/512/1024. Light and dark backdrop comparison and nearest-neighbour enlarged pixel samples are at `/tmp/rebind-app-icon-review/comparison.png`; equal-size source comparison is `source-comparison-64.png`; all ten asset checks are in `asset-verification.json` there. Enlarged samples are diagnostics, not new artwork.

No obvious clipped-shadow rectangle, JPG edge or asset/source drift was found. Real Dock/Finder rendering, selection of multi-resolution representations and native dark/clear/tinted behavior remain unverified. No artwork, Sketch document, app settings, user rules or permissions changed. No build/test run or commit.

Recommended order: improve Frosted's upper contrast, align Small's material with it, then preview native appearances with the clean layered inputs and verify Dock/Finder. Preserve the overall light-blue/white direction.
