import { createFileRoute } from '@tanstack/react-router'
import { BentoGrid } from '@/components/BentoGrid'
import { DevicesStrip } from '@/components/DevicesStrip'
import { FaqSection } from '@/components/FaqSection'
import { FeatureShowcase } from '@/components/FeatureShowcase'
import { FinalCta } from '@/components/FinalCta'
import { Footer } from '@/components/Footer'
import { Hero } from '@/components/Hero'
import { InstallSection } from '@/components/InstallSection'
import { Navbar } from '@/components/Navbar'
import { PrivacyMenuBarSection } from '@/components/PrivacyMenuBarSection'
import type { Locale } from '@/config/locales'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { fallbackReleaseInfo, getLatestRelease } from '@/integrations/releases'
import { pageHead } from '@/integrations/seo'
import { useRevealObserver } from '@/lib/reveal'
import { useTheme } from '@/lib/theme'

export const Route = createFileRoute('/')({
  head: () => pageHead(getLocale() as Locale, false),
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
        <FeatureShowcase theme={theme} />
        <BentoGrid theme={theme} />
        <PrivacyMenuBarSection release={release} />
        <InstallSection release={release} />
        <FaqSection />
        <FinalCta release={release} />
      </main>
      <Footer />
    </>
  )
}
