# Sketch alignment review — 2026-10-10

Scope: UI-002, SPEC §10, design only. Reviewed all 22 current frames through live Sketch MCP; repaired desktop frames 01–03 and 14–22 plus their affected local sources. Frames 04–13 retain their authored layout. Git baseline `acce2f4`; prior permission-recovery records preserved, no app changes or Git commit.

## Saved source

`Rebind.sketch`, Sketch 2026.3.1 / API 2.0.0. Post-save document ID `0D40E26C-3A14-42D3-9DBA-D9DC6DFAB6D4`; resolve again before work. SHA-256 `50859f5bfbe9d4bc031431e526ca03f65a3af3fd29e6e554cd867484c28a6f58`. Saved ZIP CRC passes. All existing frame/source IDs remain valid in [DESIGN](../DESIGN.md).

## Findings and repairs

| Finding | Final composition |
| --- | --- |
| Rebind label center 2.5 pt above the sidebar icon | Twelve transparent horizontal Stacks center the existing 32 pt icon and label with a 14 pt gap. Brand artwork and icon overrides unchanged. |
| Footer dot center 2 pt below the label; compact recovery dot distorted | Seven transparent horizontal Stacks center a fixed 6 × 6 pt dot and the existing text with a 6 pt gap, pinned to the bottom. Counts stay independently right-aligned. |
| Light search magnifier oversized and touching the placeholder | Shared Light glyph reduced from 24 to 16 pt, matching the Dark control slot; fixed intrinsic dimensions and left anchor. Placeholder vertically centered in the 36 pt control. |
| Profile label 1 pt above the control center | Shared profile label y = 10 with 16 pt height in the 36 pt capsule. |
| Compact connector hidden; Action heading offset from the row column | Restore the source connector and apply its horizontal Stack: arrow x = 254, Action x = 286 within the row. Action headings align at detail x = 314. Trigger uses remaining width; controls retain their sizes. |
| Settings subtitle 1 pt above the main-window subtitle | All five Settings subtitles use y = 72. |
| Expanded windows scaled or displaced sidebar/control/footer content; nested row surfaces retained their old width | Fix intrinsic control sizes and edge pins in all twelve desktop frames. Sidebar stays 232 pt; detail margins stay 28 pt. Seven binding viewports use vertical Stacks with 68 pt rows and filling widths. Local row surfaces/dividers and Dark wrappers follow their instance width. Reading order preserved. |
| Settings cards/privacy text relied on independent fixed positions | Five transparent vertical body Stacks preserve 16 pt card gaps and use a 24 pt gap before the privacy note. Wrapped German cards remain 159/86/87 pt at 880 × 640; privacy note moves from y = 600 to 608. |

No text, overrides, Symbol links or prototype flows changed. Zero original local nodes removed: **1,470 retained, 24 transparent layout groups added, 1,494 total**. Brand, Foundations and Components pages compare exactly to the pre-review saved model. Source changes are alignment/sizing/visibility plus default Stack metadata. Resize processing changed the corner-style flag on 49 instances whose corner radius remains zero; fills, borders, shadows, typography and other style fields compare unchanged. No Symbol detached or Apple library source edited.

## Verification

- All 22 authored-size frames inspected; twelve changed desktop frames recaptured after final layout processing. Final [Light main](alignment-review/main-light.png), [Dark main](alignment-review/main-dark.png), [compact main](alignment-review/main-compact.png), and all nine [permission-recovery exports](permission-recovery.md#saved-source-and-visual-checks) refreshed at 1×; all twelve PNG header dimensions match their indexed frames.
- Light main checked at 1200 × 740 and restored to 1040 × 640 after anchor repair. Dark main, compact recovery and German Settings checked at 1200 × 740, then restored to 1040 × 640, 880 × 600 and 880 × 640 respectively. Controls, columns, sidebar/footer anchors and wrapped card content remain aligned in the expanded views.
- After the final three-frame roundtrip settled, all **553 screen-node frames** matched the pre-roundtrip geometry exactly. Partial rows at the compact viewport edge remain intentional scrolling content.
- Explicit save succeeds; saved ZIP integrity, node retention, copy/overrides/flows, source scope and PNG dimensions checked. Public [Sketch API](https://developer.sketch.com/reference/api/) used for sizing, pins and Stacks. Process pending layout and inspect again in a separate call before accepting nested geometry; avoid full serialization of library-rich trees.
- Repository evidence/link review and `git diff --check` pass. Curated exports remain versionable under the existing ignore policy.

Native build/launch, grants, remapping, hardware, VoiceOver/keyboard/accessibility preferences and RU/FR rendered layouts were not checked in this design task. These remain implementation gates in UI-001. The representative size checks do not certify every possible window size.

**Next:** implement the prepared first-run and permissions design using this saved revision and its intrinsic-size/edge-anchor contracts. Independent design can continue Settings → General under a new scoped task.
