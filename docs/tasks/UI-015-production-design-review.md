# UI-015 — Production design review and refinement

- Updated: 2026-10-12.
- Stage: `ready_for_implementation`.
- Owner: Unassigned; `/root` design review saved/released.
- Ownership: `main` / `afb7411`; preserve concurrent native UI-014/input work.
- Scope: full live Rebind Sketch screen/component review; shared action chips, capture alignment, spacing, materials, appearance/localization and final-state consistency. No native app changes.
- Requirements: SPEC §10; DESIGN, released UI-011/UI-012/UI-013 and curated touch contracts.

## Acceptance

- [x] Review all 125 screen/state compositions and affected shared sources.
- [x] Fix duplicate shortcut glyphs, chip fill/width and trailing editor-control alignment at their reusable sources.
- [x] Resolve actionable spacing, clipping, hierarchy, appearance and consistency findings across the source.
- [x] Review final live screenshots, save Sketch and verify preservation; record remaining native acceptance separately.
- [x] Update concise source/readiness records and run `git diff --check`.

## Saved result and verification

Rebind.sketch saved/reviewed **2026-10-12**, document ID `3D0EE4BC-3EE5-45C9-97A0-E4DCAF4414AE`, SHA-256 `b1334400d35c7ebb0218766afb118c68d72e1627b60fa9f054ba817c273cf1ed`. Refresh the ID through MCP before adoption. All 125 screen/state compositions and 28 Foundations/Components boards were reviewed live, followed by screenshots of the corrected surfaces, including saved Light/Dark examples. Sketch contains the reusable corrections and concise native interaction/accessibility annotations.

Corrected shared shortcut-chip sizing/fill and removed redundant shortcut icons from 14 rows; named-action icons remain. Aligned output/input clear glyphs and recording buttons. Removed redundant category headings from both gesture menus and compacted their edge insets. Matched Dark gesture/action selector materials, improved Dark accent foregrounds and About secondary-button readability. Standardized native destructive confirmations, selected a recognizable native indeterminate-progress specimen, aligned localized tab/editor labels and supplied Dark backdrops for state specimens.

Rendered geometry audit of all 125 screens found no actionable clipping after review: three compact list overflows are intentional scrolling, and one native chevron's text bounds exceed its visible ink. Save succeeded; archive CRC passes. All screen IDs/names and positions are preserved; only the two gesture-menu heights changed. Only their redundant heading layers were removed. Brand is structurally unchanged; all 46 imported symbols retain library links. Documentation links/status and `git diff --check` pass. Temporary screenshots/contact sheets stayed outside Git. External `59f5754` captured earlier in-progress records; no agent Git commit or native app source/build/runtime/hardware changes.

No open correction remains in this design review. Native keyboard/VoiceOver, actual language reflow, adaptive materials, resizing, runtime/input coexistence and release gates remain separate; Sketch review does not certify them.

## Next step

Adopt the reviewed final interface directly from live Sketch, including UI-011/UI-012/UI-013 and these shared corrections. Preserve the integrated tap editor/engine work and verify native appearance and behavior on identified builds.

2026-10-12 native follow-up: [UI-016](UI-016-editor-design-adoption.md) adopts the bounded Mouse/Trackpad editor portion and shared action/feedback. [Software/native evidence](../verification/editor-design-adoption.md) records its checks and native activation-artwork difference. Other screens and full accessibility/preferences acceptance remain open; the design-wide handoff is not complete.
