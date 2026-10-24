# WEB-001: Public website foundation and design transfer

- Updated: 2026-10-24
- Stage: awaiting_verification (iteration-two implementation ready; final interaction/accessibility/release checks open)
- Owner: Codex website implementation
- Ownership checked: main `e3540f3` with the existing uncommitted website transfer preserved. Codex owns scoped website/Sketch parity corrections; no native app changes.
- Owned surfaces: `apps/website/`, website sections in shared documentation; scoped website/export preparation in Rebind.sketch and Monny.sketch
- Requirements: [SPEC §17](../SPEC.md#17-public-website), user request 2026-10-22 for the same reviewed foundation as Monny
- Code baseline: initialized after `2ca3b59`; foundation is tracked in current `main` (`11cef13` at the 2026-10-23 documentation review). Original checks below remain dated 2026-10-22.

## Outcome and scope

The verified foundation initialized the cleared `apps/website/` with TanStack Start, React 19, Vite, strict TypeScript, moduix CSS Modules/Calm, Lucide, Paraglide and Oxlint/Oxfmt. It includes a minimal localized landing and real HTTP 404, request-isolated SSR, route-owned SEO, robots/sitemap, immutable hashed assets and Cloudflare Workers configuration for `rebind.moduix.dev`. The requested `src` structure and component folder contract are in the [website README](../../apps/website/README.md).

The technical setup matches the reviewed Monny foundation; product messages, icon and tokens belong to Rebind. Live Sketch specifies **light only**, blue primary, capsule controls, canvas gradient and raised-keycap tokens. No dark website theme or monitoring-related content was carried over. The Paraglide compiler is a build-time dependency, and Node types match the tested Node 24 runtime. No shared package, custom UI primitive, generator framework, database or deployment pipeline was added.

Iteration two implements the live `Rebind.sketch → 05 · Website` landing/404, responsive navigation/Drawer, keycap illustration, five device panels, triggers/actions, features, permissions, installation/Clipboard, FAQ and footer. All final text and accessible names use six-language Paraglide catalogs. Image handling matches Monny: moduix Image within native picture, PNG sources and vite-imagetools/Sharp transforms at dev/build time. No custom generator or generated src copies. Download links use the real GitHub Releases page with a pending-release note until a verified public DMG is configured. Noindex remains until release/content acceptance. No deployment, DNS change, native app change or Git commit. The subsequent authorized Sketch corrections/save are recorded below.

## Acceptance

- [x] Frozen-lockfile installation, formatter/linter/type checks and production client/Worker build pass.
- [x] Fifteen tests cover foundation behavior plus real moduix/imagetools SSR for all five responsive images.
- [x] Seven HTTP smoke tests pass against local workerd: six locales and their 404 responses, real HTML metadata/JSON-LD, crawler files and immutable assets.
- [x] Rebuilding Wrangler dry-run packages the Worker without uploading.
- [x] Rebind light tokens, product copy and icon are configured; language Menu uses radio-item links with native names, `lang`/`hreflang` and a checked selection.
- [x] Landing, 404 and responsive states implemented from the live source; bounded desktop/mobile hero and interaction review performed. Full interaction/device acceptance remains below.
- [ ] Final six-language proofreading, mobile widths, keyboard/VoiceOver and reduced-motion review.
- [ ] Real public release download and first-launch notice until notarization.
- [ ] First explicitly requested deployment, DNS/TLS and live indexing verification.

## Source and verification

Source inspected read-only through live Sketch MCP on 2026-10-22: **Rebind.sketch → 05 · Website**, including desktop/mobile 404 screenshot, `Website · Implementation notes`, canvas fills and Light/Background, Surface, Text, Accent, Border and Keycap color variables. The updated language contract requires moduix Menu with a RadioItemGroup of localized links. Header opens downward; footer and mobile Drawer uses must open upward when implemented. Sketch owns the complete design and states; [DESIGN](../DESIGN.md#website) is the short locator.

Agent-observed on macOS 27.0.1 / Node 24.22.0 / pnpm 12.14.0: `pnpm install --frozen-lockfile`, `pnpm format`, `pnpm check` (ten tests), `pnpm deploy:dry-run` (includes a fresh build), `pnpm preview --port 4176 --strictPort`, `WEBSITE_TEST_ORIGIN=http://127.0.0.1:4176 pnpm test:smoke` (seven tests). All locale URLs return 200, each localized missing page returns 404/noindex without canonical or JSON-LD, and home canonical/hreflang/JSON-LD match `rebind.moduix.dev`. The app icon and source contain no Monny branding. Safari confirmed the light shell, app icon, capsule controls and Menu with six language choices and checked English. Full keyboard/VoiceOver/mobile and final design navigation remain iteration-two acceptance; these checks do not certify the final design.

Known upstream warnings are identical to the verified foundation: moduix 3.0.1's `@theme` metadata is reported as unknown by Lightning CSS, and Vite reports a CSS sourcemap warning. No library patch, Tailwind addition or warning suppression. Compatibility date `2026-10-19` matches the installed workerd binary. DNS, HTTPS and the production account/zone remain unverified; the live domain was not changed.

The former Rsbuild MVP was removed at `2ca3b59`. Its historical SSR/copy checks remain in [REL-004](REL-004-release-copy-and-documentation-audit.md) and do not verify this new source. Its pending visual/download/publication checks are now owned here.

## Iteration-two implementation and review — 2026-10-23

Source: live Rebind.sketch desktop/mobile landing, 404, Drawer and implementation notes, plus prepared image export Frames and dark native device states. Source was read/exported without edits or saves. Scoped website code on `e3540f3` uses direct moduix imports/CSS Modules with system fonts and Lucide, preserving existing routing, SEO, locale isolation and Cloudflare configuration. Section title classes do not leak into footer captions. Removed the foundation's global button font shorthand and control focus outline; the library retains keyboard focus. Gallery/install tabs use the library indicators and source capsule/line geometry. Drawer enters from the top, with upward footer/Drawer language menus. Copy feedback uses Clipboard and Tooltip; no bespoke primitive or dependency patch.

Desktop hero keydown only updates the illustration, ignores editable/interactive targets and browser modifier shortcuts, and never prevents default, executes native actions or stores text. Touch examples cycle with pause/manual selection and honor reduced-motion changes. Permission status is explicitly labeled as a preview; experimental gestures and supported-model Logitech scope stay honest. Kept a valid Double press F5 trigger rather than modifier-only keys. No unsupported gesture expansion, app changes or DMG build.

Five 2160×1440 source PNGs are intentional shipped illustrations: prepared clipped Keyboard/Mouse/Trackpad exports plus native Magic Trackpad/Magic Mouse frames. All five PNGs and 15 emitted WebP variants have expected dimensions/aspect ratios and fully transparent corners. The ready vite-imagetools 12.0.1 plugin (MIT, Sharp-backed) produces 540/1080/2160 px WebP at quality 90/effort 6 from import directives. Source PNGs remain unchanged by compression; variants stay in ignored cache/dist. No custom script, separate optimization step or image service. Outputs range from 13–17 kB on the smallest width to 83–101 kB at 2x (rounded decimal). The Monny cross-link uses its real GitHub repository while publication is pending.

Checks: `pnpm format`, `pnpm check` (Oxfmt/Oxlint/TypeScript, 15 tests), rebuilding `pnpm deploy:dry-run`, seven `pnpm test:smoke` cases against workerd on port 4176, and `git diff --check` pass. The smoke suite now checks localized sections, anchors, one H1, responsive/lazy image markup, closed FAQ answers and the Rebind-specific command in addition to metadata/404/caching. No deployment. Existing upstream @theme/sourcemap warnings remain, plus Vite's raw 500 kB client advisory (about 171 kB gzip); no warning hiding or custom chunk framework. Screenshot/WebP review captures and probes remain temporary, outside Git.

Browser observations: Chrome rendered the desktop hero/keycaps/buttons cleanly. Safari displayed the Russian installation layout; Magic Mouse selection updated the tab/panel, System Settings changed the installation content, and the second FAQ opened while the first closed. Chrome DevTools exposed a 390×844 responsive viewport and a captured hero with mobile navigation, stacked buttons/copy link and inline notice. These bounded observations do not certify all sections, motion, focus or physical devices. Native automation intermittently returned window-change guards, ScreenCaptureKit -3811/-3812 errors, reduced thumbnail captures and a timeout. Full mobile Drawer/copy/tab/overflow interactions, keyboard/VoiceOver, runtime reduced-motion acceptance, fluent translation review and client 404 → home metadata remain open. No acceptance is inferred from successful HTTP/build checks.

## Final source and website parity review — 2026-10-23

Saved Monny.sketch and Rebind.sketch after scoped review. Live screenshots confirmed readable notes, corrected Rebind exports and caption contrast. Neither website page contains invalid dimensions or TODO/TBD/lorem placeholders. Rebind’s prepared export Frames used 16 px corners while its Magic-device frames used smooth 26 px / 0.6 corners; corrected the three prepared Frames, re-exported the PNGs and refreshed Sketch placements. All five 2160×1440 PNGs now have identical sampled alpha contours and transparent corners. Notes identify all five sources, each with 2x PNG/WebP export presets. Vite still generates responsive WebP automatically.

Both sites now use the source language-menu label, EN/DE/ES/FR/RU/ZH order, codes, trailing check, surface/shadow and highlight. Standard moduix groups, indicator="end", MenuViewport and tokens provide 36/32/44 px header/footer/Drawer triggers, 36/44 px rows and scrolling for short viewports. Aligned Drawer icons/type, 60 px navigation rows, 16 px gaps, 48 px download and the first-launch link in six catalogs. Rebind captions reuse Light/Text/Secondary. Both 404s remove the unintended default Empty panel using tokens; Monny’s grid no longer stretches its rhythm. Rebind’s 404 uses the source heading/link colors. Removed Monny’s negative hero-caption margin under the fade. No custom primitive, generator or dependency patch.

Checks: pnpm check (format/lint/types; Monny 12 tests, Rebind 15), rebuilding pnpm deploy:dry-run, seven HTTP smoke cases per final Worker (Monny 4177, Rebind 4176), image alpha/geometry and git diff --check. Existing upstream @theme/sourcemap/raw-size advisories remain. No upload, commit or native app/DMG build.

Browser evidence: desktop menus; Chrome 390×844 Monny Drawer/upward popup and keyboard selection to German; Safari Rebind device corners/active Magic Trackpad indicator, Russian FAQ/footer, narrow Drawer and upward popup with short-height scrolling to all six languages and Russian selection. Safari confirmed the final Rebind 404 without the stray panel. Both localized 404 → home links restored their home URL/title. A height-capped German mobile capture covered Monny battery/AI/install/FAQ wrapping, but not the bottom or offscreen lazy gallery loading. Native capture/input remains intermittent (background thumbnails/window changes and a Dock-access timeout). Physical-device/all-section, full keyboard/VoiceOver, runtime reduced motion and fluent translation acceptance remain open; no whole-page pixel-perfect claim. Captures/probes stay outside Git. The saved sources are ready for the bounded design/export handoff; public DMG, indexing and authorized deployment remain separate gates.

## Next handoff

Use the newly saved Sketch Implementation notes for exports and the current local Worker previews (Monny 4177, Rebind 4176) for acceptance. Finish physical-phone/all-section, keyboard/VoiceOver, runtime reduced-motion and fluent translation review, plus client-side 404 → home canonical/robots/JSON-LD restoration (URL/title already passed). The v1.0.0 DMG link and indexing were set on 2026-10-24 (`pnpm check`, build and seven smoke tests pass; preview serves `index, follow`). The maintainer deploys manually; then verify DNS/TLS/redirects. Website-only work does not rebuild the native DMG.
