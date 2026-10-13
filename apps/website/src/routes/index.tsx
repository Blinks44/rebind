import {
  Accordion,
  AccordionItem,
  AccordionItemBody,
  AccordionItemContent,
  AccordionItemIndicator,
  AccordionItemTrigger,
} from '@moduix/react/accordion'
import { Badge, BadgeDot } from '@moduix/react/badge'
import { Button } from '@moduix/react/button'
import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@moduix/react/card'
import { Marquee, MarqueeContent, MarqueeItem, MarqueeViewport } from '@moduix/react/marquee'
import { createFileRoute } from '@tanstack/react-router'
import { BadgeCheck, Download, Keyboard, Languages, Layers, LockKeyhole, type LucideIcon, Mouse, Pause, ShieldCheck, Sparkles, Tag } from 'lucide-react'
import { motion } from 'motion/react'
import type { ReactNode } from 'react'
import { actions } from '~/actions'
import { AppWindow } from '~/components/AppWindow'
import { LanguageMenu } from '~/components/LanguageMenu'
import { TryIt } from '~/components/TryIt'
import { type Action, Binding, Keycaps, Logo, Reveal, Tile, TriggerChip } from '~/components/ui'
import { m } from '~/paraglide/messages.js'
import { getLocale, locales, localizeHref } from '~/paraglide/runtime.js'
import { type Release, getLatestRelease } from '~/release'
import { site } from '~/site'

const ogLocales = { ru: 'ru_RU', en: 'en_US', de: 'de_DE', fr: 'fr_FR', es: 'es_ES', 'zh-Hans': 'zh_CN' }

const faq = () => [
  { id: 'free', question: m.faq_free_q(), answer: m.faq_free_a() },
  { id: 'devices', question: m.faq_devices_q(), answer: m.faq_devices_a() },
  { id: 'access', question: m.faq_access_q(), answer: m.faq_access_a() },
  { id: 'warning', question: m.faq_warning_q(), answer: m.faq_warning_a() },
  { id: 'mac', question: m.faq_mac_q(), answer: m.faq_mac_a() },
]

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
  const catalog = Object.values(actions).map((action) => action())

  return (
    <>
      <header className="site-header">
        <div className="container site-header-row">
          <a className="brand" href="#top">
            <Logo size={36} />
            Rebind
          </a>
          <nav className="site-nav" aria-label={m.nav_sections()}>
            <a href="#scenarios">{m.nav_scenarios()}</a>
            <a href="#try">{m.nav_try()}</a>
            <a href="#faq">{m.nav_faq()}</a>
          </nav>
          <LanguageMenu />
          <Button asChild size="sm" className="header-download">
            <a href="#download">{m.nav_download()}</a>
          </Button>
        </div>
      </header>

      <main id="top">
        <section className="container hero">
          <Badge variant="outline" className="hero-badge">
            <BadgeDot /> {m.hero_badge()}
          </Badge>
          <h1>{m.hero_title()}</h1>
          <p className="lead">{m.hero_lead()}</p>
          <div className="hero-actions">
            <DownloadButton release={release} />
            <Button asChild variant="outline" size="xl">
              <a href="#scenarios">{m.hero_secondary()}</a>
            </Button>
          </div>
          <DownloadNote release={release} />
          <motion.div
            className="hero-window"
            initial={{ opacity: 0, y: 40, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.7, ease: [0.2, 0.8, 0.2, 1] }}
          >
            <AppWindow />
          </motion.div>
        </section>

        <section className="container">
          <Reveal>
            <dl className="card stats">
              <Stat icon={Tag} value={m.stat_price_value()} label={m.stat_price_label()} />
              <Stat icon={ShieldCheck} value={m.stat_data_value()} label={m.stat_data_label()} />
              <Stat icon={Keyboard} value={m.stat_inputs_value()} label={m.stat_inputs_label()} />
              <Stat icon={Languages} value={m.stat_languages_value()} label={m.stat_languages_label()} />
            </dl>
          </Reveal>
        </section>

        <section className="container section" id="scenarios">
          <SectionHeading title={m.scenarios_title()} lead={m.scenarios_lead()} />
          <div className="grid grid-2">
            <Scenario title={m.scenario_mouse_title()} text={m.scenario_mouse_text()}>
              <Binding trigger={<TriggerChip icon={Mouse}>{m.trigger_button4()}</TriggerChip>} action={actions.missionControl()} />
              <Binding trigger={<TriggerChip icon={Mouse}>{m.trigger_button5()}</TriggerChip>} action={actions.nextDesktop()} />
            </Scenario>
            <Scenario title={m.scenario_presses_title()} text={m.scenario_presses_text()} delay={0.08}>
              <Binding trigger={<Press kind={m.press_single()} />} action={actions.playPause()} />
              <Binding trigger={<Press kind={m.press_double()} />} action={actions.nextTrack()} />
              <Binding trigger={<Press kind={m.press_long()} />} action={actions.mute()} />
            </Scenario>
            <Scenario title={m.scenario_windows_title()} text={m.scenario_windows_text()}>
              <Binding trigger={<Keycaps keys={['⌃', '⌥', '←']} />} action={actions.leftHalf()} />
              <Binding trigger={<Keycaps keys={['⌃', '⌥', '→']} />} action={actions.rightHalf()} />
              <Binding trigger={<Keycaps keys={['⌃', '⌥', '↩']} />} action={actions.fillScreen()} />
            </Scenario>
            <Scenario title={m.scenario_launch_title()} text={m.scenario_launch_text()} delay={0.08}>
              <Binding trigger={<Keycaps keys={['⌥', 'T']} />} action={actions.openTerminal()} />
              <Binding trigger={<Keycaps keys={['F16']} />} action={actions.runShortcut()} />
              <Binding trigger={<Keycaps keys={['⌥', 'G']} />} action={actions.openLink()} />
            </Scenario>
          </div>
        </section>

        <section className="container section section-narrow" id="try">
          <SectionHeading title={m.try_title()} lead={m.try_lead()} />
          <Reveal>
            <TryIt />
          </Reveal>
        </section>

        <section className="section">
          <div className="container">
            <SectionHeading title={m.actions_title()} lead={m.actions_lead()} />
          </div>
          <ActionMarquee items={catalog.slice(0, 11)} />
          <ActionMarquee items={catalog.slice(11)} reverse />
        </section>

        <section className="container section">
          <SectionHeading title={m.why_title()} />
          <div className="why">
            <Why icon={BadgeCheck} title={m.why_free_title()} text={m.why_free_text()} large />
            <Why icon={LockKeyhole} title={m.why_private_title()} text={m.why_private_text()} large />
            <Why icon={Sparkles} title={m.why_native_title()} text={m.why_native_text()} />
            <Why icon={Layers} title={m.why_profiles_title()} text={m.why_profiles_text()} />
            <Why icon={Pause} title={m.why_pause_title()} text={m.why_pause_text()} />
          </div>
        </section>

        <section className="container section">
          <SectionHeading title={m.steps_title()} />
          <ol className="steps">
            <Step number={1} title={m.step1_title()} text={m.step1_text()} />
            <Step number={2} title={m.step2_title()} text={m.step2_text()} />
            <Step number={3} title={m.step3_title()} text={m.step3_text()} />
          </ol>
        </section>

        <section className="container section section-narrow" id="faq">
          <SectionHeading title={m.faq_title()} />
          <Reveal>
            <Accordion className="card faq" collapsible multiple defaultValue={['free']}>
              {faq().map(({ id, question, answer }) => (
                <AccordionItem key={id} value={id}>
                  <AccordionItemTrigger>
                    {question}
                    <AccordionItemIndicator />
                  </AccordionItemTrigger>
                  <AccordionItemContent>
                    <AccordionItemBody>{answer}</AccordionItemBody>
                  </AccordionItemContent>
                </AccordionItem>
              ))}
            </Accordion>
          </Reveal>
        </section>

        <section className="container section" id="download">
          <Reveal className="cta">
            <Logo size={88} />
            <h2>{m.cta_title()}</h2>
            <p className="lead">{m.cta_text()}</p>
            <DownloadButton release={release} />
            <DownloadNote release={release} />
          </Reveal>
        </section>
      </main>

      <footer className="container site-footer">
        <span>© 2026 Rebind · MIT</span>
        <span>{m.requirement()}</span>
      </footer>
    </>
  )
}

function SectionHeading({ title, lead }: { title: string; lead?: string }) {
  return (
    <Reveal className="section-heading">
      <h2>{title}</h2>
      {lead && <p className="lead">{lead}</p>}
    </Reveal>
  )
}

function Stat({ icon, value, label }: { icon: LucideIcon; value: string; label: string }) {
  return (
    <div className="stat">
      <Tile icon={icon} />
      <dt>{label}</dt>
      <dd>{value}</dd>
    </div>
  )
}

function Scenario(props: { title: string; text: string; delay?: number; children: ReactNode }) {
  return (
    <Reveal delay={props.delay}>
      <Card className="scenario">
        <CardHeader>
          <CardTitle asChild>
            <h3>{props.title}</h3>
          </CardTitle>
          <CardDescription>{props.text}</CardDescription>
        </CardHeader>
        <CardBody className="scenario-bindings">{props.children}</CardBody>
      </Card>
    </Reveal>
  )
}

function Press({ kind }: { kind: string }) {
  return (
    <>
      <Keycaps keys={['F13']} />
      <span className="press">{kind}</span>
    </>
  )
}

function ActionMarquee({ items, reverse }: { items: Action[]; reverse?: boolean }) {
  return (
    <Marquee className="action-marquee" autoFill reverse={reverse} speed={32} spacing="12px" pauseOnInteraction aria-hidden={reverse}>
      <MarqueeViewport>
        <MarqueeContent>
          {items.map((action) => (
            <MarqueeItem key={action.title} className="action-chip">
              <Tile icon={action.icon} /> {action.title}
            </MarqueeItem>
          ))}
        </MarqueeContent>
      </MarqueeViewport>
    </Marquee>
  )
}

function Why(props: { icon: LucideIcon; title: string; text: string; large?: boolean }) {
  return (
    <Reveal className={props.large ? 'why-item why-item-large' : 'why-item'}>
      <Card className="why-card">
        <CardHeader>
          <Tile icon={props.icon} />
          <CardTitle asChild>
            <h3>{props.title}</h3>
          </CardTitle>
          <CardDescription>{props.text}</CardDescription>
        </CardHeader>
      </Card>
    </Reveal>
  )
}

function Step({ number, title, text }: { number: number; title: string; text: string }) {
  return (
    <li className="step">
      <Reveal delay={(number - 1) * 0.1}>
        <span className="step-key" aria-hidden>
          {number}
        </span>
        <h3>{title}</h3>
        <p>{text}</p>
      </Reveal>
    </li>
  )
}

/** A real link once a release exists; until then a disabled button that says so. */
function DownloadButton({ release }: { release: Release | null }) {
  if (!release) {
    return (
      <Button size="xl" className="download-button" disabled>
        <Download size={18} aria-hidden /> {m.download()}
        <span className="soon">{m.download_soon()}</span>
      </Button>
    )
  }
  return (
    <Button asChild size="xl" className="download-button">
      <a href={release.url}>
        <Download size={18} aria-hidden /> {m.download()}
      </a>
    </Button>
  )
}

function DownloadNote({ release }: { release: Release | null }) {
  return (
    <p className="download-note">
      {release ? m.download_version({ version: release.version }) : m.download_pending()} · {m.requirement()}
    </p>
  )
}
