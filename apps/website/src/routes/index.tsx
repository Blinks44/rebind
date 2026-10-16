import { createFileRoute } from '@tanstack/react-router'
import { faq } from '~/lib/faq'
import { getLatestRelease } from '~/lib/release'
import { site } from '~/lib/site'
import { getLocale, locales, localizeHref } from '~/paraglide/runtime.js'
import { m } from '~/paraglide/messages.js'
import { ActionCatalog, CallToAction, Devices, Faq, Hero, Scenarios, SiteFooter, SiteHeader, Stats, Steps, TrySection, Why } from '~/sections'

const ogLocales = { ru: 'ru_RU', en: 'en_US', de: 'de_DE', fr: 'fr_FR', es: 'es_ES', 'zh-Hans': 'zh_CN' }

export const Route = createFileRoute('/')({
  loader: async () => ({ release: await getLatestRelease() }),
  head: () => {
    const locale = getLocale()
    const title = m.meta_title()
    const description = m.meta_description()
    const pageUrl = (target: (typeof locales)[number]) => site.url + localizeHref('/', { locale: target })
    return {
      meta: [
        { title },
        { name: 'description', content: description },
        { property: 'og:type', content: 'website' },
        { property: 'og:site_name', content: 'Rebind' },
        { property: 'og:title', content: title },
        { property: 'og:description', content: description },
        { property: 'og:locale', content: ogLocales[locale] },
        { name: 'twitter:card', content: 'summary' },
        ...(site.url
          ? [
              { property: 'og:url', content: pageUrl(locale) },
              { property: 'og:image', content: `${site.url}/app-icon.png` },
            ]
          : []),
      ],
      links: site.url
        ? [
            { rel: 'canonical', href: pageUrl(locale) },
            ...locales.map((target) => ({ rel: 'alternate', hrefLang: target, href: pageUrl(target) })),
            { rel: 'alternate', hrefLang: 'x-default', href: pageUrl('en') },
          ]
        : [],
      scripts: [
        {
          type: 'application/ld+json',
          children: JSON.stringify({
            '@context': 'https://schema.org',
            '@graph': [
              {
                '@type': 'SoftwareApplication',
                name: 'Rebind',
                description,
                applicationCategory: 'UtilitiesApplication',
                operatingSystem: 'macOS 26',
                offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
              },
              {
                '@type': 'FAQPage',
                mainEntity: faq().map(({ question, answer }) => ({
                  '@type': 'Question',
                  name: question,
                  acceptedAnswer: { '@type': 'Answer', text: answer },
                })),
              },
            ],
          }),
        },
      ],
    }
  },
  component: Landing,
})

function Landing() {
  const { release } = Route.useLoaderData()
  return (
    <>
      <SiteHeader />
      <main id="top">
        <Hero release={release} />
        <Stats />
        <Scenarios />
        <Devices />
        <TrySection />
        <ActionCatalog />
        <Why />
        <Steps />
        <Faq />
        <CallToAction release={release} />
      </main>
      <SiteFooter />
    </>
  )
}
