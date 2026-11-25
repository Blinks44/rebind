import { Link } from '@tanstack/react-router'
import { ArrowRight, ArrowUpRight, Download, ShieldCheck } from 'lucide-react'
import { Footer } from '@/components/Footer'
import { Navbar } from '@/components/Navbar'
import type { Locale } from '@/config/locales'
import { site } from '@/config/site'
import { type GuideSlug, getGuideContent } from '@/content/seo'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import type { ReleaseInfo } from '@/integrations/releases'
import { useRevealObserver } from '@/lib/reveal'
import { useTheme } from '@/lib/theme'

interface GuidePageProps {
  slug: GuideSlug
  release: ReleaseInfo
}

export function GuidePage({ slug, release }: GuidePageProps) {
  const locale = getLocale() as Locale
  const content = getGuideContent(locale, slug)
  const { theme, toggleTheme } = useTheme()

  useRevealObserver()

  return (
    <>
      <Navbar theme={theme} onToggleTheme={toggleTheme} />
      <main id="top" className="seo-subpage">
        <div className="container">
          <div className="seo-subpage-topbar">
            <nav className="seo-breadcrumbs" aria-label="Breadcrumb">
              <Link to="/">{m.seoBreadcrumbHome()}</Link>
              <span aria-hidden="true">/</span>
              <span>{m.seoBreadcrumbGuides()}</span>
              <span aria-hidden="true">/</span>
              <span aria-current="page">{content.breadcrumbLabel}</span>
            </nav>

            <div className="seo-pill-switcher">
              <Link to="/guides/mx-master-mac-setup/" className="seo-pill seo-pill-active">
                {m.seoSwitchMx()}
              </Link>
              <Link to="/alternatives/logi-options-ghub/" className="seo-pill">
                {m.seoSwitchLogi()}
              </Link>
              <Link to="/alternatives/linearmouse-mos/" className="seo-pill">
                {m.seoSwitchLinear()}
              </Link>
            </div>
          </div>

          <section className="seo-subpage-hero">
            <h1>{content.headline}</h1>
            <p className="seo-subpage-subtitle">{content.subtitle}</p>

            <div className="seo-hero-actions">
              <a href={release.dmg.url} className="btn-rb-primary">
                <Download size={16} aria-hidden="true" />
                <span>{m.seoDownloadFree()}</span>
              </a>
              <Link to={content.secondaryCtaTo} className="btn-rb-outline seo-secondary-btn">
                <span>{content.secondaryCtaLabel}</span>
                <ArrowRight size={14} aria-hidden="true" />
              </Link>
            </div>
          </section>

          <section className="seo-block">
            <h2 className="seo-block-title">{content.cardsTitle}</h2>
            <div className="seo-guide-cards-grid">
              {content.cards.map((card) => (
                <article key={card.title} className="seo-guide-card">
                  <span className="seo-guide-card-label">{card.label}</span>
                  <h3>{card.title}</h3>
                  <p className="seo-guide-card-desc">{card.description}</p>
                  <div className="seo-guide-code-box mono">
                    {card.items.map((line) => (
                      <div key={line}>{line}</div>
                    ))}
                  </div>
                  <p className="seo-guide-card-foot">{card.footer}</p>
                </article>
              ))}
            </div>
          </section>

          <section className="seo-block">
            <h2 className="seo-block-title">{content.stepsTitle}</h2>
            <div className="seo-steps-grid seo-steps-grid-4">
              {content.steps.map((step) => (
                <article key={step.step} className="seo-step-card">
                  <span className="seo-step-kicker mono">{step.step}</span>
                  <h3>{step.title}</h3>
                  <p>{step.description}</p>
                </article>
              ))}
            </div>
          </section>

          <section className="seo-block">
            <h2 className="seo-block-title">{m.seoPitfallsTitle()}</h2>
            <div className="seo-safety-grid">
              {content.pitfalls.map((item) => (
                <article key={item.title} className="seo-safety-card">
                  <div className="seo-safety-head">
                    <ShieldCheck size={16} className="seo-safety-icon" aria-hidden="true" />
                    <h3>{item.title}</h3>
                  </div>
                  <p>{item.description}</p>
                </article>
              ))}
            </div>
          </section>

          <section className="seo-block">
            <h2 className="seo-block-title">{m.seoExploreTitle()}</h2>
            <div className="seo-related-grid">
              <Link to="/alternatives/logi-options-ghub/" className="seo-related-card">
                <div className="seo-related-title-row">
                  <strong>{m.seoRelatedLogiTitle()}</strong>
                  <ArrowRight size={14} aria-hidden="true" />
                </div>
                <p>{m.seoRelatedLogiDesc()}</p>
              </Link>
              <Link to="/alternatives/steermouse/" className="seo-related-card">
                <div className="seo-related-title-row">
                  <strong>{m.seoRelatedSteermouseTitle()}</strong>
                  <ArrowRight size={14} aria-hidden="true" />
                </div>
                <p>{m.seoRelatedSteermouseDesc()}</p>
              </Link>
              <Link to="/alternatives/linearmouse-mos/" className="seo-related-card">
                <div className="seo-related-title-row">
                  <strong>{m.seoRelatedLinearTitle()}</strong>
                  <ArrowRight size={14} aria-hidden="true" />
                </div>
                <p>{m.seoRelatedLinearDesc()}</p>
              </Link>
              <a
                href={site.suite.hearth}
                target="_blank"
                rel="noreferrer"
                className="seo-related-card"
              >
                <div className="seo-related-title-row">
                  <strong>{m.seoRelatedHearthTitle()}</strong>
                  <ArrowUpRight size={14} aria-hidden="true" />
                </div>
                <p>{m.seoRelatedHearthDesc()}</p>
              </a>
            </div>
          </section>

          <section className="seo-bottom-cta">
            <div className="seo-bottom-cta-copy">
              <h2>{m.seoGuideCtaTitle()}</h2>
              <p>{m.seoGuideCtaSub()}</p>
            </div>
            <a href={release.dmg.url} className="btn-rb-primary">
              <Download size={16} aria-hidden="true" />
              <span>{m.seoDownloadFree()}</span>
            </a>
          </section>
        </div>
      </main>
      <Footer />
    </>
  )
}
