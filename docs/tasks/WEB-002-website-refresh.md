# WEB-002: Website refresh: show what Rebind can do

- Updated: 2026-10-28
- Stage: done
- Owner: current design chat (Claude Code)
- Ownership checked: main `a5992e2`, clean at startup 2026-10-28; active
- Owned surfaces: `Rebind.sketch → 05 · Website` (new desktop landing frame beside the current one); SPEC §17 website family paragraph; this record. `apps/website/` landing sections, navigation and messages.
- Requirements: [SPEC §17](../SPEC.md#17-public-website); user request 2026-10-28
- Code baseline: `apps/website/` as recorded in [WEB-001](WEB-001-landing-page.md)

## Outcome and scope

The site predates much of the current app. Refresh it so it shows the real capabilities with product-specific, explanatory visuals and less template feel, while staying recognizably from the same team as Monny. Design first in Sketch; implement after the user approves the design.

Audit 2026-10-28 (both live Sketch sources and website code): beyond header and footer, the sites also share the hero formula (identical "Free · Open source · macOS 26+" badge), installation with the notarization card, FAQ, the final download card, device/dashboard tabs over app screenshots and a centered eyebrow/heading/lead + card rhythm in almost every section. Rebind's middle is the most generic part (six icon-tile feature cards). The site omits or barely mentions current capabilities: 93 actions in 8 groups, tap/hold dual-role keys, button-hold pointer directions, Logitech gesture button, battery levels in the menu bar, keyboard lighting (G915, experimental compatible Logitech RGB) and the emergency pause ⌃⌥⇧⌘Esc.

User decisions 2026-10-28:
- Shared shell versus product sections is the [website family contract](../SPEC.md#17-public-website), recorded in both repositories.
- Keep the device tabs with app screenshots (proof of the real app), more compact, right after the hero.
- Proposed direction approved: hero keycaps stay with mixed examples (key, mouse, gesture); then sections for press / double press / hold and tap-hold; mouse (hold-button directions, modifier wheel, Logitech); trackpad and Magic Mouse (experimental); the action catalog with a live example per group (window placement on a mini desktop); profiles and per-app rules; menu bar battery and lighting; privacy and safety as one compact block; then the shared installation, FAQ, final card and footer.
- Order of work: desktop design for approval, then mobile and states, then implementation.

Exclusions: no invented numbers, ratings or testimonials; no claims beyond CAPABILITIES (gestures stay experimental, Logitech features on supported models). Motion only where it explains a mechanism, disabled under Reduce Motion. No native app change.

## Acceptance

- [x] Desktop landing frame saved in Rebind.sketch with the approved section set, existing Light website tokens and keycap styles, English copy, and annotations for motion and interaction.
- [x] User approval of the desktop direction (2026-10-28).
- [x] Mobile landing and needed states; implementation notes updated (save pending at handoff, 2026-10-28).
- [x] Website implementation and six-language copy (2026-10-28); automated checks below. Deployment remains the maintainer's.
- [x] Device images and `og-image.jpg` re-exported 2x from the current Sketch sources (2026-10-28): Export · Web Keyboard/Mouse/Trackpad layers in screens 02/06/10 Dark, screens 11 and 54 Dark, Social · Open Graph. Same 2160×1440 size and transparent corners; Sketch matches build 28 names.
- [x] 2026-10-29: the five device images re-exported 2x from the same Sketch layers after Devices moved into the sidebar ([UI-025](UI-025-devices-in-main-window.md)); size and transparent corners unchanged. The Keyboard image in the Sketch landing mockups was replaced too (Rebind.sketch saved, SHA-256 `52b3841a9e9fb2fdfee1e6139cbb942912998e82721836ed4f3117c71ade56bd`). `pnpm build`, `pnpm check` and `pnpm test:smoke` pass; not deployed.
- [x] Manual checks (user, 2026-10-28): deployed site on desktop and phone, keyboard and VoiceOver on the chip groups, Reduce Motion, translations. Follow-up fixes the same day: device-tab indicator height (36 px, equal 4 px inset) and mobile menu anchored under its menu-bar icon.

## Sketch source

User approved the desktop direction and saved it on 2026-10-28, then asked to keep only one current design. The approved frame is now `Web · Landing · Desktop` (x 0 on `05 · Website`, 1440 × 8740); the previous desktop and mobile landings moved to `99 · Archive` as `Archived · Web · Landing · Desktop/Mobile (before WEB-002, 2026-10-28)`. No prototype links pointed at the old desktop frame.

Desktop reuses the existing card, tile, keycap-chip, badge and text layers with Light swatches; screen 51's battery menu is copied in as a specimen. All action, category and gesture names were checked against `Localizable.xcstrings` (93 actions, 8 groups; 500 ms is the default hold time). Order:
- Header links Devices · Actions · Profiles · Install · FAQ; hero example chips F13 → Mission Control, Button 4 → Back, 3-finger tap → Show Desktop; main example ⌃⌥J → Next Space.
- Devices tabs compacted (880 px screenshot). Tab images re-exported on 2026-10-28 and again on 2026-10-29 (see the checklist above).
- Timing, Mouse (Hold Button 4 with Space actions, Logitech card), Trackpad and Magic Mouse (surface, Experimental note, preset chips).
- Actions: mini desktop with Left/Right Half windows, ⌃⌥← example, layout chips; the 8 groups with one real action each.
- Profiles and apps: profile chips, three rules with All apps / In Safari scopes, excluded-apps note, F8/F7 Next/Previous Profile.
- Menu bar and devices: battery menu specimen; G915 TKL lighting card with the experimental RGB note.
- Privacy and safety (compact): local-only/no-analytics text and the ⌃⌥⇧⌘ Esc emergency pause.
- Shared Install, FAQ, final card and footer unchanged, moved below.

`Web · Landing · Mobile` (390 × 10936) carries the same sections; layout decisions are in `Website · Refresh notes (WEB-002)` (x 6340) with motion and interaction notes. The mobile hero, 404 header and links, both drawers, language-menu states, footers and the Open Graph image now use the new navigation and Next Space naming. Screenshot-reviewed per section and as full desktop/mobile pages; the last edits await the user's Sketch save.

Sketch scripting lessons: do not assign one layer's `style.fills` to another or set fills with a `swatch` object (crashed Sketch once); duplicate a layer that already has the variable-bound fill instead. Resizing a frame scales its children; snapshot child frames before the resize and restore them after.

## Implementation · 2026-10-28

`features/landing/feature-section` holds the shared layout, card, action row and `ChoiceChips` (moduix ToggleGroup, `deselectable={false}`, SSR renders `role="radiogroup"` with `aria-checked`). Seven sections follow the Sketch order: `timing`, `mouse`, `gestures`, `actions`, `profiles`, `menu-bar`, `privacy`. Gesture chips switch the touch diagram and caption; layout chips move the window and change the example shortcut; profile chips switch the rule list. Timing bars use `animation-timeline: view()` inside `@supports` and `prefers-reduced-motion: no-preference`; other motion is guarded the same way. Header, Drawer, footer and 404 links, hero examples (Next Space, Back, 3-finger tap → Show Desktop) and the smoke test follow the new sections; obsolete messages were removed. Catalog names come from `Localizable.xcstrings`; new section copy was translated in this session.

Verification: `pnpm check` (format, lint, types, 15 tests), production build, 7 Worker smoke tests on all six locales and `deploy:dry-run` pass. Headless Chrome captures of the production preview at 1440 px (EN, RU) and 390 px through an iframe (EN, DE) were reviewed; long Russian/German labels in the compass, tap/hold card and DPI row were fixed after review. Not checked: real devices/Safari, keyboard/VoiceOver, live Reduce Motion, native-speaker review.

## Next handoff

None. The Monny site can follow the same approach under its own task (SPEC §10 in that repository).
