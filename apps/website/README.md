# Rebind website

The public landing page: one route, rendered on the server with [TanStack Start](https://tanstack.com/start) on Rsbuild. English is served at `/`; Russian, German, French, Spanish and Simplified Chinese at `/ru`, `/de`, `/fr`, `/es` and `/zh`, the same six languages as the app.

```sh
pnpm install
pnpm dev      # http://localhost:3000
pnpm build    # production build and type check
pnpm start    # serve the production build
```

- **Copy** lives in `messages/<locale>.json` and uses the app's own terms (a binding is «правило», "Belegung", "règle"…; check `Localizable.xcstrings` before renaming one). The page describes the finished product, Magic Mouse and Magic Trackpad included, so it must not be deployed before those ship. [Paraglide](https://inlang.com/m/gerre34r/library-inlang-paraglideJs) compiles them into `src/paraglide/` (generated, not versioned) on every dev start and build; add a language in `project.inlang/settings.json` and the `urlPatterns` in `rsbuild.config.ts`.
- **Layout**: `src/components/` holds reusable pieces and `src/sections/` the page's blocks, each in its own folder (`components/binding/Binding.tsx` next to `Binding.module.css`) and exported from the top-level `index.ts`; `src/lib/` holds data and the release server function; `src/routes/` only composes sections and sets the head.
- **Styling**: components come from [moduix](https://moduix.dev) (`@moduix/react`), including its reset; animation is [Motion](https://motion.dev). `src/styles/theme.css` is the only global stylesheet: it defines Rebind's colors with `light-dark()`, mirroring `apps/rebind/rebind/UI/DesignSystem/Theme.swift` (change a token in both places), and maps them onto moduix tokens so components such as Kbd, Tag and Card take the app's look without per-component overrides.
- **Settings** are in `src/lib/site.ts`. Set `githubRepo` once the repository is public: the download button then links to the latest release DMG (`src/lib/release.ts`, a server function). Set `url` once the domain is known to emit canonical, hreflang and Open Graph URLs.
- Icons are Lucide, not SF Symbols: the SF Symbols license does not cover use on a website.
