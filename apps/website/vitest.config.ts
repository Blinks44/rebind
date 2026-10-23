import { fileURLToPath } from 'node:url'
import { imagetools } from 'vite-imagetools'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  plugins: [imagetools()],
  resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
  test: {
    include: ['src/test/**/*.test.ts'],
    environment: 'node',
    server: { deps: { inline: ['@moduix/react'] } },
  },
})
