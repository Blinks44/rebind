import { createFileRoute } from '@tanstack/react-router'
import { BentoGrid } from '@/components/BentoGrid'
import { DevicesStrip } from '@/components/DevicesStrip'
import { FaqSection, getLandingFaqItems } from '@/components/FaqSection'
import { FeatureShowcase } from '@/components/FeatureShowcase'
import { FinalCta } from '@/components/FinalCta'
import { Footer } from '@/components/Footer'
import { Hero } from '@/components/Hero'
import { InstallSection } from '@/components/InstallSection'
import { Navbar } from '@/components/Navbar'
import { PrivacyMenuBarSection } from '@/components/PrivacyMenuBarSection'
import { ReplacesSection } from '@/components/ReplacesSection'
import { WhoItIsForSection } from '@/components/WhoItIsForSection'
import type { Locale } from '@/config/locales'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { fallbackReleaseInfo, getLatestRelease } from '@/integrations/releases'
import { pageHead } from '@/integrations/seo'
import { useRevealObserver } from '@/lib/reveal'
import { useTheme } from '@/lib/theme'

export const Route = createFileRoute('/')({
  head: () => {
    const locale = getLocale() as Locale
    return pageHead(locale, {
      path: '/',
      faq: getLandingFaqItems(locale),
    })
  },
  loader: async () => {
    try {
      return await getLatestRelease()
    } catch {
      return fallbackReleaseInfo()
    }
  },
  component: LandingPage,
})

function LandingPage() {
  const release = Route.useLoaderData()
  const { theme, toggleTheme } = useTheme()
  useRevealObserver()

  return (
    <>
      <Navbar theme={theme} onToggleTheme={toggleTheme} />
      <main>
        <Hero theme={theme} release={release} />
        <DevicesStrip />
        <WhoItIsForSection />
        <FeatureShowcase theme={theme} />
        <BentoGrid theme={theme} />
        <ReplacesSection />
        <PrivacyMenuBarSection release={release} />
        <InstallSection release={release} />
        <FaqSection />
        <FinalCta release={release} />
      </main>
      <Footer />
    </>
  )
}
