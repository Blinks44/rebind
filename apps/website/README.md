# Rebind website

The public landing page: one route, rendered on the server with [TanStack Start](https://tanstack.com/start) on Rsbuild. English is served at `/`; Russian, German, French, Spanish and Simplified Chinese at `/ru`, `/de`, `/fr`, `/es` and `/zh`, the same six languages as the app.

```sh
pnpm install
pnpm dev      # http://localhost:3000
pnpm build    # production build and type check
pnpm preview  # build and run it locally in the Cloudflare Workers runtime (wrangler dev)
pnpm deploy   # build and publish to https://rebind.moduix.dev
```

**Hosting**: the site is a Cloudflare Worker (`wrangler.jsonc`): `dist/client` is served as static assets and `dist/server/index.js` renders the rest. `wrangler deploy` attaches the custom domain `rebind.moduix.dev` (the `moduix.dev` zone is on the same Cloudflare account) and creates its DNS record and certificate. The first run opens a browser to sign in to Cloudflare (`wrangler login`). TanStack Start's Cloudflare guide covers only Vite, so `rsbuild.config.ts` builds the server environment for a web worker in production (`pnpm dev` still runs in Node).

- **Copy** lives in `messages/<locale>.json` and uses the app's own terms (a binding is «правило», "Belegung", "règle"…; check `Localizable.xcstrings` before renaming one). Copy describes the implemented release pool and its Experimental touch/platform limits. Keep examples aligned with the app: there are six Magic Mouse tap/click/scroll presets, no swipes, and one activation rule per input. Publication follows the app release; see [the release guide](../../docs/RELEASING.md). [Paraglide](https://inlang.com/m/gerre34r/library-inlang-paraglideJs) compiles them into `src/paraglide/` (generated, not versioned) on every dev start and build; add a language in `project.inlang/settings.json` and the `urlPatterns` in `rsbuild.config.ts`.
- **Layout**: `src/components/` holds reusable pieces and `src/sections/` the page's blocks, each in its own folder (`components/binding/Binding.tsx` next to `Binding.module.css`) and exported from the top-level `index.ts`; `src/lib/` holds data and the release server function; `src/routes/` only composes sections and sets the head.
- **Styling**: components come from [moduix](https://moduix.dev) (`@moduix/react`), including its reset; animation is [Motion](https://motion.dev). `src/styles/theme.css` is the only global stylesheet: it defines Rebind's colors with `light-dark()`, mirroring `apps/rebind/rebind/UI/DesignSystem/Theme.swift` (change a token in both places), and maps them onto moduix tokens so components such as Kbd, Tag and Card take the app's look without per-component overrides.
- **Settings** are in `src/lib/site.ts`. `githubRepo` is `Blinks44/rebind`: the download button links to the latest stable release DMG (`src/lib/release.ts`, a server function). `url` is the production origin used for canonical, hreflang and Open Graph URLs. No release/DMG or a failed API request leaves Download disabled. Release metadata is cached for up to 10 minutes. This does not publish the app or site.
- Icons are Lucide, not SF Symbols: the SF Symbols license does not cover use on a website.
