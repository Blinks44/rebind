import { paraglideRspackPlugin } from '@inlang/paraglide-js'
import { defineConfig } from '@rsbuild/core'
import { pluginReact } from '@rsbuild/plugin-react'
import { tanstackStart } from '@tanstack/react-start/plugin/rsbuild'

// URL prefix of every language except English, which lives at `/`.
const prefixes: [locale: string, prefix: string][] = [
  ['ru', '/ru'],
  ['de', '/de'],
  ['fr', '/fr'],
  ['es', '/es'],
  ['zh-Hans', '/zh'],
]
const rest = '/:path(.*)?'

export default defineConfig({
  server: { port: 3000 },
  plugins: [pluginReact(), tanstackStart({ srcDirectory: 'src' })],
  tools: {
    rspack: {
      plugins: [
        paraglideRspackPlugin({
          project: './project.inlang',
          outdir: './src/paraglide',
          outputStructure: 'message-modules',
          // The URL alone decides the language.
          strategy: ['url', 'baseLocale'],
          urlPatterns: [
            { pattern: '/', localized: [...prefixes, ['en', '/']] },
            { pattern: rest, localized: [...prefixes.map(([locale, prefix]): [string, string] => [locale, prefix + rest]), ['en', rest]] },
          ],
        }),
      ],
    },
  },
})
