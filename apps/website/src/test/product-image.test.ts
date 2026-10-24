import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import { ProductImage } from '../components/product-image'

describe('product image SSR with moduix and imagetools', () => {
  it.each(['keyboard', 'mouse', 'trackpad', 'magic-trackpad', 'magic-mouse'] as const)(
    'renders real responsive sources for %s without losing accessible image attributes',
    (view) => {
      const html = renderToStaticMarkup(
        createElement(ProductImage, { view, alt: `Rebind ${view}` }),
      )
      expect(html).toContain('data-slot="image-root"')
      expect(html).toMatch(/<source[^>]+srcSet="[^"]+ 520w, [^"]+ 1040w, [^"]+ 2080w"/)
      expect(html).toContain('type="image/webp"')
      expect(html).toContain(`alt="Rebind ${view}"`)
      expect(html).toContain('width="1080" height="720"')
      expect(html).toContain('loading="lazy"')
      expect(html).not.toMatch(/(?:layout|priority|unstyled)=/)
    },
  )
})
