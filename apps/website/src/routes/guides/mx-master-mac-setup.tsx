import { createFileRoute } from '@tanstack/react-router'
import { GuidePage } from '@/components/GuidePage'
import type { Locale } from '@/config/locales'
import { getGuideContent } from '@/content/seo'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { fallbackReleaseInfo, getLatestRelease } from '@/integrations/releases'
import { pageHead } from '@/integrations/seo'

export const Route = createFileRoute('/guides/mx-master-mac-setup')({
  head: () => {
    const locale = getLocale() as Locale
    const content = getGuideContent(locale, 'mx-master-mac-setup')
    return pageHead(locale, {
      path: '/guides/mx-master-mac-setup/',
      title: content.metaTitle,
      description: content.metaDescription,
      includeSoftwareApplication: false,
      breadcrumbs: [
        { name: m.seoBreadcrumbHome({}, { locale }), path: '/' },
        { name: content.breadcrumbLabel, path: '/guides/mx-master-mac-setup/' },
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
  component: MxMasterMacSetupGuidePage,
})

function MxMasterMacSetupGuidePage() {
  const release = Route.useLoaderData()
  return <GuidePage slug="mx-master-mac-setup" release={release} />
}
