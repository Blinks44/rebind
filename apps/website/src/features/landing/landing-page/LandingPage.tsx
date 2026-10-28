import { Badge } from '@moduix/react/badge'
import { Card } from '@moduix/react/card'
import { DownloadActions } from '@/components/download-actions'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import { ActionsSection } from '../actions-section'
import { DevicesSection } from '../devices-section'
import { FaqSection } from '../faq-section'
import { GesturesSection } from '../gestures-section'
import { HeroDemo } from '../hero-demo'
import { InstallNotice } from '../install-notice'
import { MenuBarSection } from '../menu-bar-section'
import { MouseSection } from '../mouse-section'
import { PrivacySection } from '../privacy-section'
import { ProfilesSection } from '../profiles-section'
import { SiteFooter } from '../site-footer'
import { TimingSection } from '../timing-section'
import styles from './LandingPage.module.css'

export function LandingPage() {
  const steps = [
    [m.installStep1(), m.installDetail1()],
    [m.installStep2(), m.installDetail2()],
    [m.installStep3(), m.installDetail3()],
    [m.installStep4(), m.installDetail4()],
  ]
  return (
    <>
      <section className={styles.hero} aria-labelledby="hero-title">
        <div className={styles.intro}>
          <Badge variant="outline" className={styles.badge}>
            <span aria-hidden="true" />
            {m.freeBadge()}
          </Badge>
          <h1 id="hero-title" className={styles.heroTitle}>
            {m.heroTitle()}
            <span>{m.heroAccent()}</span>
          </h1>
          <p className={styles.heroLead}>{m.heroLead()}</p>
          <DownloadActions mobileCopy />
          <p className={styles.meta}>{m.compatibility()}</p>
          {!site.downloadUrl && <p className={styles.release}>{m.releasePending()}</p>}
          <InstallNotice compact />
        </div>
        <HeroDemo />
      </section>
      <DevicesSection />
      <div className={styles.container}>
        <TimingSection />
        <MouseSection />
        <GesturesSection />
        <ActionsSection />
        <ProfilesSection />
        <MenuBarSection />
        <PrivacySection />
        <section id="install" className={styles.install} aria-labelledby="install-title">
          <div className={styles.center}>
            <p className={styles.eyebrow}>{m.install()}</p>
            <h2 id="install-title" className={styles.heading}>
              {m.installTitle()}
            </h2>
            <p className={styles.lead}>{m.installLead()}</p>
          </div>
          <ol className={styles.steps}>
            {steps.map(([title, detail]) => (
              <li key={title}>
                <strong>{title}</strong>
                <span>{detail}</span>
              </li>
            ))}
          </ol>
          <InstallNotice />
        </section>
        <FaqSection />
        <section className={styles.cta} aria-labelledby="cta-title">
          <Card className={styles.ctaCard}>
            <img src="/app-icon.png" width="104" height="104" alt="" loading="lazy" />
            <h2 id="cta-title" className={styles.ctaHeading}>
              {m.ctaTitle()}
            </h2>
            <p>{m.ctaLead()}</p>
            <DownloadActions />
          </Card>
        </section>
        <SiteFooter />
      </div>
    </>
  )
}
