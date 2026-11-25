import { createFileRoute } from '@tanstack/react-router'
import { AlternativePage } from '@/components/AlternativePage'
import type { Locale } from '@/config/locales'
import { getAlternativeContent } from '@/content/seo'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { fallbackReleaseInfo, getLatestRelease } from '@/integrations/releases'
import { pageHead } from '@/integrations/seo'

export const Route = createFileRoute('/alternatives/linearmouse-mos')({
  head: () => {
    const locale = getLocale() as Locale
    const content = getAlternativeContent(locale, 'linearmouse-mos')
    return pageHead(locale, {
      path: '/alternatives/linearmouse-mos/',
      title: content.metaTitle,
      description: content.metaDescription,
      includeSoftwareApplication: false,
      breadcrumbs: [
        { name: m.seoBreadcrumbHome({}, { locale }), path: '/' },
        { name: content.breadcrumbLabel, path: '/alternatives/linearmouse-mos/' },
      ],
    })
  },
  loader: async () => {
    try {
      return await getLatestRelease()
    } catch {
      return fallbackReleaseInfo()
    }
  },
  component: LinearMouseMosAlternativePage,
})

function LinearMouseMosAlternativePage() {
  const release = Route.useLoaderData()
  return <AlternativePage slug="linearmouse-mos" release={release} />
}
