import { createFileRoute } from '@tanstack/react-router'
import { AlternativePage } from '@/components/AlternativePage'
import type { Locale } from '@/config/locales'
import { getAlternativeContent } from '@/content/seo'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { fallbackReleaseInfo, getLatestRelease } from '@/integrations/releases'
import { pageHead } from '@/integrations/seo'

export const Route = createFileRoute('/alternatives/steermouse')({
  head: () => {
    const locale = getLocale() as Locale
    const content = getAlternativeContent(locale, 'steermouse')
    return pageHead(locale, {
      path: '/alternatives/steermouse/',
      title: content.metaTitle,
      description: content.metaDescription,
      includeSoftwareApplication: false,
      breadcrumbs: [
        { name: m.seoBreadcrumbHome({}, { locale }), path: '/' },
        { name: content.breadcrumbLabel, path: '/alternatives/steermouse/' },
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
  component: SteerMouseAlternativePage,
})

function SteerMouseAlternativePage() {
  const release = Route.useLoaderData()
  return <AlternativePage slug="steermouse" release={release} />
}
