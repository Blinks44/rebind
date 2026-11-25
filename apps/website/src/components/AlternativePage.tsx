import { Link } from '@tanstack/react-router'
import { ArrowRight, ArrowUpRight, Check, Download, Minus } from 'lucide-react'
import { CopyButton } from '@/components/CopyButton'
import { Footer } from '@/components/Footer'
import { Navbar } from '@/components/Navbar'
import type { Locale } from '@/config/locales'
import { site } from '@/config/site'
import { type AlternativeSlug, getAlternativeContent } from '@/content/seo'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import type { ReleaseInfo } from '@/integrations/releases'
import { useRevealObserver } from '@/lib/reveal'
import { useTheme } from '@/lib/theme'

interface AlternativePageProps {
  slug: AlternativeSlug
  release: ReleaseInfo
}

export function AlternativePage({ slug, release }: AlternativePageProps) {
  const locale = getLocale() as Locale
  const content = getAlternativeContent(locale, slug)
  const { theme, toggleTheme } = useTheme()

  useRevealObserver()

  const switcher = [
    {
      slug: 'logi-options-ghub' as const,
      to: '/alternatives/logi-options-ghub/' as const,
      label: m.seoSwitchLogi(),
    },
    {
      slug: 'steermouse' as const,
      to: '/alternatives/steermouse/' as const,
      label: m.seoSwitchSteermouse(),
    },
    {
      slug: 'linearmouse-mos' as const,
      to: '/alternatives/linearmouse-mos/' as const,
      label: m.seoSwitchLinear(),
    },
  ]

  const internalRelated = [
    {
      to: '/alternatives/logi-options-ghub/' as const,
      title: m.seoRelatedLogiTitle(),
      description: m.seoRelatedLogiDesc(),
      exclude: slug === 'logi-options-ghub',
    },
    {
      to: '/alternatives/steermouse/' as const,
      title: m.seoRelatedSteermouseTitle(),
      description: m.seoRelatedSteermouseDesc(),
      exclude: slug === 'steermouse',
    },
    {
      to: '/alternatives/linearmouse-mos/' as const,
      title: m.seoRelatedLinearTitle(),
      description: m.seoRelatedLinearDesc(),
      exclude: slug === 'linearmouse-mos',
    },
    {
      to: '/guides/mx-master-mac-setup/' as const,
      title: m.seoRelatedMxTitle(),
      description: m.seoRelatedMxDesc(),
      exclude: false,
    },
  ].filter((item) => !item.exclude)

  return (
    <>
      <Navbar theme={theme} onToggleTheme={toggleTheme} />
      <main id="top" className="seo-subpage">
        <div className="container">
          <div className="seo-subpage-topbar">
            <nav className="seo-breadcrumbs" aria-label="Breadcrumb">
              <Link to="/">{m.seoBreadcrumbHome()}</Link>
              <span aria-hidden="true">/</span>
              <span>{m.seoBreadcrumbAlternatives()}</span>
              <span aria-hidden="true">/</span>
              <span aria-current="page">{content.breadcrumbLabel}</span>
            </nav>

            <div className="seo-pill-switcher">
              {switcher.map((item) => (
                <Link
                  key={item.slug}
                  to={item.to}
                  className={item.slug === slug ? 'seo-pill seo-pill-active' : 'seo-pill'}
                >
                  {item.label}
                </Link>
              ))}
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
              <div className="seo-brew-pill mono">
                <span className="seo-brew-prompt">$</span>
                <code>{site.homebrewCommand}</code>
                <CopyButton text={site.homebrewCommand} showLabel={false} />
              </div>
            </div>

            <div className="seo-highlights-grid">
              {content.highlights.map((item) => (
                <div key={item.value} className="seo-highlight-card">
                  <strong className="mono">{item.value}</strong>
                  <span>{item.label}</span>
                </div>
              ))}
            </div>
          </section>

          <section className="seo-block">
            <h2 className="seo-block-title">{m.seoComparisonTitle()}</h2>
            <div className="seo-table-card">
              <div className="seo-table-scroll">
                <table className="seo-compare-table">
                  <thead>
                    <tr>
                      <th scope="col">{m.seoColCriterion()}</th>
                      <th scope="col" className="seo-compare-rebind-head">
                        {m.seoColRebind()}
                      </th>
                      <th scope="col">{content.competitorColumn}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {content.rows.map((row) => (
                      <tr key={row.criterion}>
                        <th scope="row" className="seo-cell-category">
                          {row.criterion}
                        </th>
                        <td className="seo-compare-rebind-cell">
                          <span className="seo-compare-check">
                            <Check size={14} aria-hidden="true" />
                            <span>{row.rebind}</span>
                          </span>
                        </td>
                        <td className="seo-compare-other-cell">{row.other}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </section>

          <section className="seo-block">
            <div className="seo-fit-grid">
              <article className="seo-fit-card seo-fit-card-recommended">
                <span className="seo-fit-label seo-fit-label-accent">
                  {content.chooseRebind.label}
                </span>
                <h3>{content.chooseRebind.title}</h3>
                <ul className="seo-check-list">
                  {content.chooseRebind.points.map((point) => (
                    <li key={point}>
                      <Check size={15} className="seo-check-icon" aria-hidden="true" />
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>
              </article>

              <article className="seo-fit-card">
                <span className="seo-fit-label">{content.stickWithOther.label}</span>
                <h3>{content.stickWithOther.title}</h3>
                <ul className="seo-check-list seo-check-list-neutral">
                  {content.stickWithOther.points.map((point) => (
                    <li key={point}>
                      <Minus size={14} className="seo-minus-icon" aria-hidden="true" />
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>
              </article>
            </div>
          </section>

          <section className="seo-block">
            <h2 className="seo-block-title">{m.seoSwitchStepsTitle()}</h2>
            <div className="seo-steps-grid seo-steps-grid-3">
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
            <h2 className="seo-block-title">{m.seoMoreTitle()}</h2>
            <div className="seo-related-grid">
              {internalRelated.map((item) => (
                <Link key={item.to} to={item.to} className="seo-related-card">
                  <div className="seo-related-title-row">
                    <strong>{item.title}</strong>
                    <ArrowRight size={14} aria-hidden="true" />
                  </div>
                  <p>{item.description}</p>
                </Link>
              ))}
              <a
                href={site.suite.monny}
                target="_blank"
                rel="noreferrer"
                className="seo-related-card"
              >
                <div className="seo-related-title-row">
                  <strong>{m.seoRelatedMonnyTitle()}</strong>
                  <ArrowUpRight size={14} aria-hidden="true" />
                </div>
                <p>{m.seoRelatedMonnyDesc()}</p>
              </a>
            </div>
          </section>

          <section className="seo-bottom-cta">
            <div className="seo-bottom-cta-copy">
              <h2>{m.seoAltCtaTitle()}</h2>
              <p>{m.seoAltCtaSub()}</p>
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
