# Sketch design-system review — 2026-10-09

Live source: `/Users/sergejvrenev/Documents/Rebind.sketch`, Sketch 2026.3.1. Final saved document ID: `4BAD1286-1909-460E-BAC4-4FDCBEBF41AC`. Scope: SPEC §10, capture/status contracts in §§4–5, PLAN Phase 8. User authorized review and correction of the current design system. No app source, rules, permissions or engine behavior changed.

## Findings corrected

| Finding | Cause and correction |
| --- | --- |
| Squashed Light binding-menu icons | Square 24 × 24 sources were swapped into Apple's 12 × 16 glyph slots. Rebind menus now use linked square 18 × 18 instances, aligned with 13-point labels. Both themes retain editable sources. |
| Rectangular, clipped menu shadow | The menu itself was editable glass, not a JPG. A shared Regular Small material's 40-point shadow exceeded the source frame. Dedicated `Rebind/Light/menuGlass` and Dark styles preserve the rounded material without that clipped shadow; other Apple materials remain unchanged. |
| Bitmap SF Symbol sources | All 34 local sources contained PNG previews and tint masks. Replaced their contents with editable vector paths from official Apple SF Pro glyphs, preserving existing source/symbol IDs. Updated the iconography contract. |
| Distorted search magnifier and wrong Dark tint | Default search used a 21 × 15 native slot; focused/disabled examples used a 21 × 36 slot. Square glyph placement and a reusable native-slot adapter preserve aspect ratio. Dark search now has an explicit semantic Dark icon. |
| Eight missing Dark components | Added linked Dark sources for sheet header/footer, idle/editable capture, activation, action picker and default/selected profile rows. The `05 · Forms & profiles / Dark` board displays them. All 29 Light component sources now have Dark counterparts. |
| Dark native control inheritance | Added local secondary-button, popup and chevron adaptations. Kept native geometry and editable labels; corrected dark surfaces, blending and text. Migrated Light secondary-button labels, including Record Output, when adapting the Light source. Apple library masters were not edited. |
| Semantic contrast inconsistencies | Selected activation segments now use `accentFill`. Light `textTertiary` changed from `#697182` to `#586172`, including its foundation caption, to support the darker Light sidebar as well as content surfaces. |

## Verification

- Visually inspected all **18 boards on five pages**: seven Screens, five Foundations, five Components and the Brand board. Reviewed master structure, styles and rendered instances through official Sketch MCP; rechecked affected screens after source changes.
- Saved the original document through Sketch's public API. Read-only ZIP CRC and JSON checks pass: **101 local / 30 imported sources**, **34 vector SF sources**, **29 theme pairs**, **68 semantic Color Variables**, **49 local text styles**. Zero missing Symbol/shared-style references, duplicate local layer IDs, invalid rectangles, bitmap layers or embedded image resources.
- **52 semantic foreground/background pairs** pass 4.5:1; minimum **4.58:1**. Includes primary/secondary/tertiary text on seven opaque surfaces per theme, status text on content surfaces, accent text on composited accent wash, and white on accent fill. This is token verification, not a contrast claim for every Apple library example, disabled state or dynamic glass backdrop.
- Corrected Light/Dark menu exports are 520 × 160 RGBA PNGs at `/tmp/rebind-design-audit-final/`; integrity results are in `integrity.json` there. Pre-edit saved backup: `/tmp/rebind-design-audit-before.sketch`. Temporary files are supplementary; live Sketch remains authoritative.

## Asset provenance and implementation contract

Paths were extracted with CoreText from [Apple's official SF Pro resource](https://developer.apple.com/fonts/) and imported as SVG through the [public Sketch API](https://developer.sketch.com/reference/api/). Unicode/name lookup metadata was cross-checked against [UsePreside/sf-symbols](https://github.com/UsePreside/sf-symbols) and [MoOx/sf-symbols-svg](https://github.com/MoOx/sf-symbols-svg); no third-party glyph artwork or executable code was adopted. Apple resource terms apply to these design mockups. The font was extracted temporarily, not installed; its disk image was ejected after use. App implementation must continue to use `Image(systemName:)`, native Menu/Picker/Button controls and system materials rather than shipping Sketch font outlines or raster controls. No runtime dependency added.

Square icon sources must keep equal width/height. A rectangular native slot needs an adapter with centered, proportionally sized content. Menu material and shadow extent must be evaluated at the source boundary. Semantic theme roles must be explicit when adapting a native Light component.

## Remaining product acceptance

This closes the identified defects in the existing design system. It does not finish all Phase 8 product screens. Full Dark sheet compositions, conditional/action-chooser states, Settings/menu-bar flows, and profile create/edit/delete flows remain separate design work. Existing unavailable/experimental states retain their explanatory text and do not imply new engine support.

Four-language expansion, VoiceOver, keyboard operation, Increase Contrast, Reduce Transparency/Motion and dynamic glass compositing still require verification in the native application. English Sketch samples alone cannot prove those requirements. No app build or test suite was run because this session changed Sketch and documentation only. Next: use the corrected paired sources for the remaining product compositions, then verify the implemented native UI.
