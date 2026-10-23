import { Badge } from '@moduix/react/badge'
import { Card } from '@moduix/react/card'
import {
  Accessibility,
  AppWindow,
  ArrowUpDown,
  Check,
  Command,
  History,
  Layers,
  LayoutGrid,
  Moon,
  Mouse,
  PanelTop,
  PanelsTopLeft,
  PauseCircle,
  Sun,
  Type,
  Volume2,
  Workflow,
  X,
} from 'lucide-react'
import { DownloadActions } from '@/components/download-actions'
import { Keycap } from '@/components/keycap'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import { HeroDemo } from '../hero-demo'
import { DevicesSection } from '../devices-section'
import { FaqSection } from '../faq-section'
import { InstallNotice } from '../install-notice'
import { SiteFooter } from '../site-footer'
import styles from './LandingPage.module.css'

export function LandingPage() {
  const actions = [
    [Command, m.keyboardShortcut()],
    [Type, m.insertText()],
    [PanelsTopLeft, m.arrangeWindows()],
    [AppWindow, m.openApp()],
    [Workflow, m.appleShortcuts()],
    [LayoutGrid, m.missionControl()],
    [Volume2, m.volumeMedia()],
    [Sun, m.brightness()],
    [Moon, m.sleepLock()],
    [PauseCircle, m.pauseProfile()],
  ] as const
  const features = [
    [Layers, m.profiles(), m.profilesDescription()],
    [AppWindow, m.perApp(), m.perAppDescription()],
    [ArrowUpDown, m.scrolling(), m.scrollingDescription()],
    [Mouse, m.logitech(), m.logitechDescription()],
    [History, m.backups(), m.backupsDescription()],
    [PanelTop, m.menuBar(), m.menuBarDescription()],
  ] as const
  const triggers = [
    [m.keyboard(), ['F13', '⌃⌥J', m.holdSpace(), m.doubleF5()]],
    [m.mouse(), [m.button4(), m.holdButton5(), m.buttonGesture(), m.scrollUp()]],
    [m.touchDevices(), [m.threeTap(), m.fourClick(), m.cornerTap(), m.twoTap()]],
  ] as const
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
        <section id="actions" className={styles.section} aria-labelledby="actions-title">
          <div className={styles.center}>
            <p className={styles.eyebrow}>{m.bindings()}</p>
            <h2 id="actions-title" className={styles.heading}>
              {m.actionsTitle()}
            </h2>
            <p className={styles.lead}>{m.actionsLead()}</p>
          </div>
          <div className={styles.bindingCards}>
            <Card className={styles.bindingCard}>
              <h3>{m.triggers()}</h3>
              <p>{m.triggersDescription()}</p>
              {triggers.map(([label, values]) => (
                <div className={styles.triggerGroup} key={label}>
                  <h4>{label}</h4>
                  <div>
                    {values.map((value) => (
                      <Keycap key={value}>{value}</Keycap>
                    ))}
                  </div>
                </div>
              ))}
            </Card>
            <Card className={styles.bindingCard}>
              <h3>{m.actions()}</h3>
              <p>{m.actionsDescription()}</p>
              <ul className={styles.actionList}>
                {actions.map(([Icon, label]) => (
                  <li key={label}>
                    <span className={styles.tile}>
                      <Icon size={20} aria-hidden="true" />
                    </span>
                    {label}
                  </li>
                ))}
              </ul>
            </Card>
          </div>
        </section>
        <section id="features" className={styles.section} aria-labelledby="features-title">
          <div className={styles.center}>
            <p className={styles.eyebrow}>{m.everythingElse()}</p>
            <h2 id="features-title" className={styles.heading}>
              {m.featuresTitle()}
            </h2>
          </div>
          <div className={styles.featureGrid}>
            {features.map(([Icon, title, description]) => (
              <Card key={title} className={styles.featureCard}>
                <span className={styles.tile}>
                  <Icon size={22} aria-hidden="true" />
                </span>
                <h3>{title}</h3>
                <p>{description}</p>
              </Card>
            ))}
          </div>
        </section>
        <section className={styles.privacy} aria-labelledby="privacy-title">
          <div>
            <p className={styles.eyebrow}>{m.privacy()}</p>
            <h2 id="privacy-title" className={`${styles.heading} ${styles.privacyHeading}`}>
              {m.privacyTitle()}
            </h2>
            <p className={styles.lead}>{m.privacyLead()}</p>
            <Card className={styles.permission}>
              <span className={styles.tile}>
                <Accessibility size={20} aria-hidden="true" />
              </span>
              <div>
                <strong>{m.accessibility()}</strong>
                <p>{m.privacySettings()}</p>
              </div>
              <Badge variant="outline">{m.allowedPreview()}</Badge>
            </Card>
          </div>
          <Card className={styles.privacyCard}>
            <h3>{m.rebindDoes()}</h3>
            <ul>
              {[m.does1(), m.does2(), m.does3()].map((text) => (
                <li key={text}>
                  <Check size={18} aria-hidden="true" />
                  {text}
                </li>
              ))}
            </ul>
            <h3>{m.rebindDoesNot()}</h3>
            <ul>
              {[m.doesNot1(), m.doesNot2(), m.doesNot3()].map((text) => (
                <li key={text}>
                  <X size={18} aria-hidden="true" />
                  {text}
                </li>
              ))}
            </ul>
          </Card>
        </section>
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
