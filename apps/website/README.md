# Rebind website

The public landing page: one route, rendered on the server with [TanStack Start](https://tanstack.com/start) on Rsbuild. Russian is served at `/`, English at `/en`.

```sh
pnpm install
pnpm dev      # http://localhost:3000
pnpm build    # production build and type check
pnpm start    # serve the production build
```

- **Copy** lives in `messages/ru.json` and `messages/en.json`. [Paraglide](https://inlang.com/m/gerre34r/library-inlang-paraglideJs) compiles them into `src/paraglide/` (generated, not versioned) on every dev start and build; add a language in `project.inlang/settings.json` and the `urlPatterns` in `rsbuild.config.ts`.
- **Components** come from [moduix](https://moduix.dev) (`@moduix/react`); animation is [Motion](https://motion.dev). `src/styles/app.css` maps the moduix tokens onto the color tokens of `apps/rebind/rebind/UI/DesignSystem/Theme.swift`. Change a token in both places.
- **Settings** are in `src/site.ts`. Set `githubRepo` once the repository is public: the download button then links to the latest release DMG (`src/release.ts`, a server function). Set `url` once the domain is known to emit canonical, hreflang and Open Graph URLs.
- Icons are Lucide, not SF Symbols: the SF Symbols license does not cover use on a website.
