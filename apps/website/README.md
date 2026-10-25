# Rebind website

TanStack Start, React 19 and TypeScript, built with Vite for Cloudflare Workers at **https://rebind.moduix.dev**. Iteration two transfers **Rebind.sketch → 05 · Website**, inspected live on 2026-10-23: the landing, 404, shared navigation/Drawer, interactive keycap illustration, five device panels, triggers/actions, features, permissions, installation, FAQ and footer. The previous MVP was removed in commit `2ca3b59`.

## Local development

Requires Node.js 24+ and pnpm 12.14.0. Run from this directory:

```sh
pnpm install --frozen-lockfile
pnpm dev
```

Open the URL printed by Vite (normally http://127.0.0.1:3000). No environment variables, accounts or secrets are required locally. `pnpm check` runs the standard Paraglide `prepare` command before checking types/tests; the Vite plugin compiles messages during dev/build and recompiles on changes. The official inlang message-format plugin is downloaded on first compilation, so the first install/build needs network access. No custom scaffold or generator is maintained.

```sh
pnpm format         # Oxfmt writes formatting
pnpm check          # Paraglide, Oxfmt check, Oxlint, TypeScript, Vitest
pnpm build          # Production browser assets and Worker
pnpm preview        # Production build in local workerd
pnpm deploy:dry-run # Rebuild and package without uploading
```

After `pnpm build`, run `pnpm preview --port 4173 --strictPort` in one terminal and `pnpm test:smoke` in another. The seven HTTP smoke tests check all locale/404 responses, rendered sections, actual metadata/JSON-LD, crawler files and asset caching. Fifteen unit/integration tests cover the foundation and real moduix/imagetools image SSR. To check a different local preview port, run `WEBSITE_TEST_ORIGIN=http://127.0.0.1:4175 pnpm test:smoke`. Rebuild before previewing changed source. Tests cover message completeness, localized URL round trips, SEO, sitemap and concurrent SSR locale isolation.

## Source structure

- `src/assets/`: imported product assets; `public/` contains assets with stable URLs.
- `src/components/`: reusable site components.
- `src/config/`: public site settings, language names and locale mappings.
- `src/features/`: page/section components grouped by feature.
- `src/integrations/`: Paraglide and SEO integration.
- `src/routes/`: thin file routes and the document shell.
- `src/styles/`: shared design tokens; `src/app.css` imports moduix reset/foundation and global base rules.
- `src/test/`, `src/types/`, `src/utils/`: tests, shared types and small utilities when needed. Empty directories reserve the requested structure; do not add abstractions just to fill them.
- `src/env.ts`, `src/router.tsx`, `src/server.ts`, `src/start.ts`: Vite types, router, Worker entry and Start configuration.
- `src/routeTree.gen.ts`: TanStack's generated route tree, versioned for clean-checkout type checking. Never edit manually.

Every product component uses `component-name/ComponentName.tsx`, `ComponentName.module.css`, `index.ts`. Import from that folder, without an application-wide barrel. Route entry files and framework integrations follow their framework conventions.

## Components and design tokens

Use direct package imports such as `@moduix/react/button`, rather than copying library source or wrapping every control. The CSS Modules distribution includes component styles. Calm is the default in `@moduix/react/style.css`; no separate Calm stylesheet or runtime theme provider is needed. Lucide React supplies icons with named imports. Hide decorative icons from accessibility APIs.

The website is light only, as specified in Sketch. `styles/tokens.css` maps the reviewed Sketch colors to moduix semantic tokens and canvas and `--rebind-keycap-*` variables. Buttons and the language Menu use capsule radii from the moduix token contract. Use supported moduix tokens for control geometry; product CSS owns layout and app-specific illustrations. Section headings opt into explicit classes so they cannot enlarge nested footer captions. Raised keycaps use moduix Kbd with the Sketch gradient, ledge and shadow. Keep library focus styling on controls; the global focus rule applies only to plain links. System fonts avoid external font requests. Inspect the live Sketch design again before implementing final sections, responsive states or assets.

## Localization and SEO

Paraglide owns locale definitions in `project.inlang/settings.json` and compiles six JSON message catalogs under `src/integrations/i18n/messages/`. Use generated `m.message()` functions. Generated files stay ignored. URL-only locale resolution (`url`, then `baseLocale`) is deterministic for visitors and crawlers, with no locale cookie or automatic language redirect.

English is `/`; the others are `/ru/`, `/de/`, `/fr/`, `/es/`, `/zh-Hans/`. Canonical URLs use trailing slashes consistently. TanStack rewrites via Paraglide's `deLocalizeUrl`/`localizeUrl`; the Worker wraps the original request in `paraglideMiddleware`, preserving per-request locale isolation. The language switcher uses moduix Menu/RadioItemGroup, a localized group label, native-language links (`lang`/`hreflang`), language codes and a trailing checked indicator. Header/footer/Drawer triggers are 36/32/44 px; rows are 36 px or 44 px in the Drawer, with MenuViewport scrolling for short heights. Its button names the language and current selection for assistive technology; choosing a link loads that localized home document. Internal links use TanStack `Link`.

The document includes localized titles/descriptions, `lang`, canonical, six `hreflang` links plus `x-default`, Open Graph, Twitter summary and SoftwareApplication JSON-LD without invented price, ratings or release URL. `/robots.txt` and `/sitemap.xml` come from the same site/locale configuration. Unknown paths return HTTP 404 with localized copy and `noindex`, without home canonical/structured data.

**Before release:** set `site.downloadUrl` to a verified public DMG and enable `site.indexingEnabled` after release/content acceptance. Until a public DMG is configured, download links lead to GitHub Releases with a visible pending-release message. Until then, HTML meta and response headers use `noindex, follow`. The current square social image/favicon is the shipped app icon; a finished share image can replace it during design transfer. Add the real release download only when a public DMG exists. Preserve the first-launch notice from Sketch until notarization.

## Design transfer and images

The source is **Rebind.sketch → 05 · Website** and its Implementation notes. The light canvas, blue primary, capsule controls, keycaps and soft raised cards follow that source. Moduix supplies Button, Menu, Drawer, Badge, Card, Kbd, Tabs, Clipboard/Tooltip, Accordion, Alert, Image and Empty. Installation steps are a semantic ordered list. Every closed FAQ answer remains in the server HTML. The download buttons drawn at 48 px use the library's `xl` size. Both first-launch notices share one component. The mobile Drawer enters from the top; footer/Drawer language menus open upward.

The hero illustration previews examples only: desktop keydown changes the displayed key/action without suppressing input, executing a shortcut or persisting typed text. Touch devices cycle three examples, with manual selection/pause and reduced-motion support. It never performs OS actions. The permission badge is explicitly a preview, not a detected browser/system grant. Trackpad/Magic Mouse experimental limits and hardware-dependent Logitech support remain visible.

Five shipped PNG illustrations were exported at 2x from the live Sketch source: Keyboard, Mouse and Trackpad use the prepared clipped Export · Web Frames; Magic Trackpad/Magic Mouse use their dark native frames. All are 2160×1440 with matching smooth 26 px corners (0.6 smoothing) and identical sampled alpha contours. The three prepared Frames were corrected from 16 px, re-exported and refreshed in the website placements; both Sketch sources and their self-contained handoff notes were saved. Website captions use Light/Text/Secondary for readable contrast. The Monny companion icon comes from its existing shipped app icon; its card links to https://monny.moduix.dev.

`vite-imagetools` uses Sharp to prepare 540/1080/2160 px WebP variants at quality 90 and effort 6 from the original PNGs. Import directives return ready srcset strings. Results are cached under ignored node_modules and emitted into dist; there is no custom generator, separate optimization command, image CDN or runtime processing. Keep PNG sources intact and replace them after a fresh Sketch export. Native picture/source selects WebP and falls back to PNG; moduix Image preserves alt text, intrinsic dimensions and lazy loading. Inactive device panels mount on demand. Build outputs are about 13–17 kB / 36–44 kB / 83–101 kB per screenshot, depending on width.

Review performed: live desktop/mobile/404/menu/Drawer source and saved notes; corrected device-window corners and active Magic Trackpad indicator, Russian FAQ/footer, narrow Drawer controls and upward popup with short-height scrolling/all six languages, Russian language selection and final 404 without an unintended panel. Both sites restored localized home titles after client 404 navigation. Format/lint/types, 15 tests, seven final Worker HTTP smoke tests, image geometry/alpha and dry-run packaging pass. Full physical-phone/all-section, keyboard/VoiceOver, runtime reduced-motion and native-speaker translation acceptance remain open in [WEB-001](../../docs/tasks/WEB-001-landing-page.md). Native capture/input remains intermittent; these bounded checks do not certify every device or the published domain. Captures stay outside Git.

## Cloudflare deployment

`wrangler.jsonc` declares a Worker Custom Domain for `rebind.moduix.dev`, with `workers.dev` and preview URLs disabled. It uses the official Cloudflare Vite plugin, `nodejs_compat`, and compatibility date `2026-10-19`, the latest date supported by the installed workerd binary when verified. No database or other bindings are needed. Hashed browser assets receive immutable caching through `public/_headers`.

When publication is requested, authenticate Wrangler to the Cloudflare account that owns the active `moduix.dev` zone, then run `pnpm deploy`. Custom Domains let Cloudflare manage DNS and TLS for this subdomain; no additional domain purchase is required. This configuration has only been tested locally and with `--dry-run`; DNS/TLS and the live domain remain unverified. Do not use the DNS apex or change `moduix.dev`'s existing application. In Workers Builds, set the root directory to `apps/website`, build command to `pnpm build` and deploy command to `pnpm exec wrangler deploy` after configuring dependency installation.

Known upstream build warnings: the landing bundle also crosses Vite’s 500 kB uncompressed advisory (about 171 kB gzip); no manual chunk framework or warning suppression is added. Other warnings: moduix 3.0.1's shared CSS includes Tailwind's `@theme` metadata even in its CSS Modules foundation; Lightning CSS reports it as unknown. Vite also reports a CSS sourcemap warning. Production builds and the verified styles work; no Tailwind dependency or library patch is introduced to hide these warnings.

References: [Cloudflare's TanStack Start setup](https://developers.cloudflare.com/workers/framework-guides/web-apps/tanstack-start/), [Paraglide's official TanStack integration](https://paraglidejs.com/tanstack-start), [moduix setup](https://moduix.dev/docs/quick-start), [moduix themes](https://moduix.dev/docs/themes), [Oxlint configuration](https://oxc.rs/docs/guide/usage/linter/config).
