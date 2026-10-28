# WEB-001: Public website foundation and design transfer

- Updated: 2026-10-28
- Stage: done (2026-10-28; foundation carried into the WEB-002 refresh)
- Owner: unassigned
- Owned surfaces: `apps/website/`, website sections in shared documentation; `Rebind.sketch → 05 · Website`
- Requirements: [SPEC §17](../SPEC.md#17-public-website), user request 2026-10-22 for the same reviewed foundation as Monny
- Code baseline: current `main`; the content refresh continues in [WEB-002](WEB-002-website-refresh.md)

## Outcome

`apps/website/` is a TanStack Start / React 19 Worker with moduix CSS Modules (Calm, light only), Lucide, Paraglide (EN/RU/DE/FR/ES/zh-Hans) and Oxlint/Oxfmt, structured as in the [website README](../../apps/website/README.md). It renders the `05 · Website` landing and real HTTP 404: header/Drawer navigation, keycap hero demo (desktop key preview, mobile four-example moduix Carousel with loop, four-second autoplay and localized play/pause), five device panels, triggers/actions, features, privacy, installation with the first-launch notice and Clipboard copy, FAQ and footer with the Monny card. SSR metadata, canonical/hreflang, JSON-LD, robots/sitemap and per-request locale isolation follow SPEC §17.

Live at **rebind.moduix.dev** with indexing. The live HTML checked on 2026-10-28 contains the Monny footer link (monny.moduix.dev), the permanent `releases/latest/download/Rebind.dmg` download and the mobile carousel controls, so the 2026-10-25/26 source changes are deployed. Deployments are manual by the maintainer; website-only work does not rebuild the native DMG.

## Decisions to preserve

- Same technical foundation as Monny; product copy, icon and tokens are Rebind's. No shared package, custom UI primitive, generator framework or deployment pipeline.
- Images: five 2160×1440 source PNGs in `src/assets/product/` (prepared Keyboard/Mouse/Trackpad exports and native Magic Trackpad/Magic Mouse frames, smooth 26 px corners, transparent margins). vite-imagetools 12.0.1 (MIT, Sharp) emits 520/1040/2080 px WebP at quality 90 for the 1040 px panel, so 2x shows source pixels 1:1. Variants stay in ignored cache/dist.
- Hero keydown only updates the illustration: it ignores editable/interactive targets and browser modifier shortcuts, never prevents default, executes an action or stores text. Key preview is limited to the desktop width.
- Mobile carousel uses the library's autoplay/pause/loop; a mobile + Reduce Motion media query disables autoplay; manual navigation pauses per library behavior.
- Language switcher: moduix Menu with a RadioItemGroup of localized links; header opens downward, footer and Drawer upward.
- Social preview: `public/og-image.jpg` exported 2x from `Social · Open Graph · 1200×630`.
- Copy keeps experimental gesture and supported-model Logitech limits honest and keeps the first-launch notice until notarization.
- Known upstream advisories, not suppressed: moduix 3.0.1 `@theme` metadata unknown to Lightning CSS, a Vite CSS sourcemap warning and the raw 500 kB client chunk advisory (about 171 kB gzip).

## Acceptance

- [x] Frozen install, format, lint, TypeScript and production client/Worker build; 15 tests (foundation plus moduix/imagetools SSR for all five images).
- [x] Seven HTTP smoke tests (`pnpm test:smoke`) against local workerd and against `https://rebind.moduix.dev` (2026-10-25): six locales and 404s, metadata/JSON-LD, robots/sitemap, immutable assets. Sitemap parsed: six URLs with reciprocal alternates and `x-default`.
- [x] Landing, 404 and responsive states implemented from the live source; bounded desktop and mobile-hero browser review.
- [x] Real download through the permanent latest link (v1.0.0 build 15); `release.sh` writes the fixed `Rebind.dmg` name, so releases need no website edit ([history](../history/2026-10.md#2026-10-25-permanent-download-link)).
- [x] Fluent six-language proofreading on the rendered page ([COPY-001](COPY-001-app-and-website-language.md) owns the copy audit).
- [x] Narrow widths (320 px, all languages), physical swipe, timed carousel cycle/pause/loop, inactive-dot contrast.
- [x] Full keyboard/VoiceOver and runtime Reduce Motion.
- [ ] Not separately checked: client-side 404 → home restores canonical/robots/JSON-LD (URL and title confirmed by the user); only the hidden head tags remain unchecked, with no user-visible effect.
- [ ] Optional: Search Console ingestion of `/sitemap.xml`; actual indexing is unverified.

User acceptance 2026-10-28: after the WEB-002 refresh the user deployed the site and reviewed it on desktop and phone, including keyboard, VoiceOver, Reduce Motion and translations, and reported it good. That review covers the shared shell this task owns. The user then explicitly checked 320 px widths in all languages, hero carousel swipe and timing on a phone, keyboard and VoiceOver, Reduce Motion, translations and the page title after client navigation from 404 to home, with no bugs found.

## Evidence summary

- 2026-10-22 foundation: macOS 27.0.1, Node 24.22.0, pnpm 12.14.0; Safari checked shell, language Menu and 404 → home.
- 2026-10-23 iteration two and parity review: Chrome/Safari desktop, Safari Russian install/FAQ/Drawer/language popup, Chrome 390×844 hero. Rebind.sketch and Monny.sketch saved after export/corner/caption corrections.
- 2026-10-26 hero icons and mobile carousel: Chrome 390×844 Russian render and accessible slide change; native capture was unstable, so the timed autoplay/pause/loop cases above remain open.
- 2026-10-28: Sketch mobile hero synchronized with the carousel ([DESIGN](../DESIGN.md#website)); a browser pixel comparison of that section was not made.

Native screen capture/input was intermittent in every session (window-change guards, ScreenCaptureKit errors, thumbnails); no whole-page pixel-perfect claim is made. Detailed per-session notes are in Git history of this file.

## Next handoff

None. Further website changes start a new task; the shared shell contract is SPEC §17.
