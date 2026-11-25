import { describe, expect, it } from 'vitest'
import { getLandingFaqItems } from '@/components/FaqSection'
import { localePath, locales, siteRoutes } from '@/config/locales'
import { site } from '@/config/site'
import {
  type AlternativeSlug,
  type GuideSlug,
  getAlternativeContent,
  getGuideContent,
} from '@/content/seo'
import { pageHead, sitemap } from '@/integrations/seo'

const alternativeSlugs: AlternativeSlug[] = ['logi-options-ghub', 'steermouse', 'linearmouse-mos']
const guideSlugs: GuideSlug[] = ['mx-master-mac-setup']

describe('SEO subpages & structured data', () => {
  it('provides complete alternative content for every locale and slug', () => {
    for (const locale of locales) {
      for (const slug of alternativeSlugs) {
        const content = getAlternativeContent(locale, slug)
        expect(content.metaTitle.trim().length).toBeGreaterThan(15)
        expect(content.metaDescription.trim().length).toBeGreaterThan(40)
        expect(content.headline.trim().length).toBeGreaterThan(10)
        expect(content.highlights).toHaveLength(3)
        expect(content.rows.length).toBeGreaterThanOrEqual(6)
        expect(content.chooseRebind.points).toHaveLength(3)
        expect(content.stickWithOther.points).toHaveLength(3)
        expect(content.steps).toHaveLength(3)
      }
    }
  })

  it('provides complete guide content for every locale and slug', () => {
    for (const locale of locales) {
      for (const slug of guideSlugs) {
        const content = getGuideContent(locale, slug)
        expect(content.metaTitle.trim().length).toBeGreaterThan(15)
        expect(content.metaDescription.trim().length).toBeGreaterThan(40)
        expect(content.headline.trim().length).toBeGreaterThan(10)
        expect(content.cards).toHaveLength(3)
        expect(content.steps).toHaveLength(4)
        expect(content.pitfalls).toHaveLength(3)
      }
    }
  })

  it('builds SoftwareApplication + FAQPage schemas on landing pages', () => {
    const faq = getLandingFaqItems('en')
    expect(faq).toHaveLength(8)
    const head = pageHead('en', { path: '/', faq })
    expect(head.scripts).toHaveLength(2)
    const types = head.scripts.map((s) => JSON.parse(s.children)['@type'])
    expect(types).toEqual(['SoftwareApplication', 'FAQPage'])
    expect(JSON.parse(head.scripts[1]?.children ?? '{}').mainEntity).toHaveLength(8)
  })

  it('builds canonical, hreflangs, and BreadcrumbList on localized subpages', () => {
    const content = getAlternativeContent('ru', 'logi-options-ghub')
    const head = pageHead('ru', {
      path: '/alternatives/logi-options-ghub/',
      title: content.metaTitle,
      description: content.metaDescription,
      includeSoftwareApplication: false,
      breadcrumbs: [
        { name: 'Rebind', path: '/' },
        { name: content.breadcrumbLabel, path: '/alternatives/logi-options-ghub/' },
      ],
    })
    expect(head.links).toContainEqual({
      rel: 'canonical',
      href: `${site.origin}/ru/alternatives/logi-options-ghub/`,
    })
    expect(head.links.filter((l) => l.rel === 'alternate')).toHaveLength(7)
    expect(head.scripts).toHaveLength(1)
    expect(JSON.parse(head.scripts[0]?.children ?? '{}')).toMatchObject({
      '@type': 'BreadcrumbList',
    })
  })

  it('builds a 30-URL sitemap with trailing slashes', () => {
    const xml = sitemap()
    expect(xml.match(/<loc>/g)).toHaveLength(30)
    for (const route of siteRoutes) {
      for (const locale of locales) {
        const expected = `${site.origin}${localePath(locale, route)}`
        expect(expected.endsWith('/')).toBe(true)
        expect(xml).toContain(`<loc>${expected}</loc>`)
      }
    }
  })
})
