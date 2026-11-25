import { createFileRoute } from '@tanstack/react-router'
import { AlternativePage } from '@/components/AlternativePage'
import type { Locale } from '@/config/locales'
import { getAlternativeContent } from '@/content/seo'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { fallbackReleaseInfo, getLatestRelease } from '@/integrations/releases'
import { pageHead } from '@/integrations/seo'

export const Route = createFileRoute('/alternatives/logi-options-ghub')({
  head: () => {
    const locale = getLocale() as Locale
    const content = getAlternativeContent(locale, 'logi-options-ghub')
    return pageHead(locale, {
      path: '/alternatives/logi-options-ghub/',
      title: content.metaTitle,
      description: content.metaDescription,
      includeSoftwareApplication: false,
      breadcrumbs: [
        { name: m.seoBreadcrumbHome({}, { locale }), path: '/' },
        { name: content.breadcrumbLabel, path: '/alternatives/logi-options-ghub/' },
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
  component: LogiOptionsGhubAlternativePage,
})

function LogiOptionsGhubAlternativePage() {
  const release = Route.useLoaderData()
  return <AlternativePage slug="logi-options-ghub" release={release} />
}
