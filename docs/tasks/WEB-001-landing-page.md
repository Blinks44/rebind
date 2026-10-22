# WEB-001: Public website foundation and design transfer

- Updated: 2026-10-22
- Stage: ready_for_implementation (iteration one complete; next is design transfer)
- Owner: unassigned at handoff
- Ownership checked: main `2ca3b59`; website source and affected website documentation owned by this implementation turn, released at handoff
- Owned surfaces: `apps/website/`, website sections in shared documentation; Sketch inspected read-only
- Requirements: [SPEC §17](../SPEC.md#17-public-website), user request 2026-10-22 for the same reviewed foundation as Monny
- Code baseline: main `2ca3b59`; website and documentation uncommitted

## Outcome and scope

Iteration one initializes the cleared `apps/website/` with TanStack Start, React 19, Vite, strict TypeScript, moduix CSS Modules/Calm, Lucide, Paraglide and Oxlint/Oxfmt. It includes a minimal localized landing and real HTTP 404, request-isolated SSR, route-owned SEO, robots/sitemap, immutable hashed assets and Cloudflare Workers configuration for `rebind.moduix.dev`. The requested `src` structure and component folder contract are in the [website README](../../apps/website/README.md).

The technical setup matches the reviewed Monny foundation; product messages, icon and tokens belong to Rebind. Live Sketch specifies **light only**, blue primary, capsule controls, canvas gradient and raised-keycap tokens. No dark website theme or monitoring-related content was carried over. The Paraglide compiler is a build-time dependency, and Node types match the tested Node 24 runtime. No shared package, custom UI primitive, generator framework, database or deployment pipeline was added.

Iteration two transfers the full `Rebind.sketch → 05 · Website` design. The current page bodies are shells, not the final landing/404 layouts. No hero key listener, demo animation, full navigation, download integration, install notice or FAQ is claimed implemented. The shell is `noindex` until final content is ready. No deployment, DNS change, Sketch edit, native app change or Git commit was performed.

## Acceptance

- [x] Frozen-lockfile installation, formatter/linter/type checks and production client/Worker build pass.
- [x] Ten foundation tests cover catalog completeness, locale URL round trips, metadata/sitemap and concurrent SSR language isolation.
- [x] Seven HTTP smoke tests pass against local workerd: six locales and their 404 responses, real HTML metadata/JSON-LD, crawler files and immutable assets.
- [x] Rebuilding Wrangler dry-run packages the Worker without uploading.
- [x] Rebind light tokens, product copy and icon are configured; language Menu uses radio-item links with native names, `lang`/`hreflang` and a checked selection.
- [ ] Full landing, 404 and responsive state transfer from current Sketch frames.
- [ ] Final six-language proofreading, mobile widths, keyboard/VoiceOver and reduced-motion review.
- [ ] Real public release download and first-launch notice until notarization.
- [ ] First explicitly requested deployment, DNS/TLS and live indexing verification.

## Source and verification

Source inspected read-only through live Sketch MCP on 2026-10-22: **Rebind.sketch → 05 · Website**, including desktop/mobile 404 screenshot, `Website · Implementation notes`, canvas fills and Light/Background, Surface, Text, Accent, Border and Keycap color variables. The updated language contract requires moduix Menu with a RadioItemGroup of localized links. Header opens downward; footer and mobile Drawer uses must open upward when implemented. Sketch owns the complete design and states; [DESIGN](../DESIGN.md#website) is the short locator.

Agent-observed on macOS 27.0.1 / Node 24.22.0 / pnpm 12.14.0: `pnpm install --frozen-lockfile`, `pnpm format`, `pnpm check` (ten tests), `pnpm deploy:dry-run` (includes a fresh build), `pnpm preview --port 4176 --strictPort`, `WEBSITE_TEST_ORIGIN=http://127.0.0.1:4176 pnpm test:smoke` (seven tests). All locale URLs return 200, each localized missing page returns 404/noindex without canonical or JSON-LD, and home canonical/hreflang/JSON-LD match `rebind.moduix.dev`. The app icon and source contain no Monny branding. Safari confirmed the light shell, app icon, capsule controls and Menu with six language choices and checked English. Full keyboard/VoiceOver/mobile and final design navigation remain iteration-two acceptance; these checks do not certify the final design.

Known upstream warnings are identical to the verified foundation: moduix 3.0.1's `@theme` metadata is reported as unknown by Lightning CSS, and Vite reports a CSS sourcemap warning. No library patch, Tailwind addition or warning suppression. Compatibility date `2026-10-19` matches the installed workerd binary. DNS, HTTPS and the production account/zone remain unverified; the live domain was not changed.

The former Rsbuild MVP was removed at `2ca3b59`. Its historical SSR/copy checks remain in [REL-004](REL-004-release-copy-and-documentation-audit.md) and do not verify this new source. Its pending visual/download/publication checks are now owned here.

## Next handoff

Implement the website from **Rebind.sketch → 05 · Website** using this foundation. Read the live frames/notes again, build page sections with moduix, and keep the app's experimental gesture/hardware limits honest. Preserve URL-only Paraglide, index-route SEO, real 404 and the language Menu; verify client return from 404 updates metadata. Translate final copy in all six catalogs, finish responsive/accessibility checks and connect a real release download. Enable indexing only when the landing is finished. Publication remains a separate request; website work does not require rebuilding the macOS DMG.
