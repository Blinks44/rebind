import { ArrowUpRight, Download } from 'lucide-react'
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ReleaseInfo } from '@/integrations/releases'

interface FinalCtaProps {
  release: ReleaseInfo
}

export function FinalCta({ release }: FinalCtaProps) {
  return (
    <section className="section-tight">
      <div className="container">
        <div className="final-cta-card" data-reveal>
          <img src="/app-icon.png" alt="Rebind" width={60} height={60} className="final-cta-icon" />
          <h2>{m.ctaTitle()}</h2>
          <p>{m.ctaSubtitle()}</p>
          <div className="hero-actions" style={{ marginBottom: 0 }}>
            <a href={release.dmg.url} className="btn-rb-primary hero-cta-primary">
              <Download size={17} aria-hidden="true" />
              <span>{m.heroDownloadCta({ version: release.version })}</span>
            </a>
            <a
              href={site.repository}
              target="_blank"
              rel="noreferrer"
              className="btn-rb-outline hero-cta-primary"
            >
              <span>{m.ctaGithub()}</span>
              <ArrowUpRight size={16} aria-hidden="true" />
            </a>
          </div>

          <div className="suite-block">
            <p className="suite-label">{m.suiteHeading()}</p>
            <div className="suite-grid">
              <a href={site.suite.hearth} target="_blank" rel="noreferrer" className="suite-card">
                <img src="/suite/hearth.png" alt="Hearth" width={40} height={40} />
                <div>
                  <div className="suite-card-title">
                    <span>Hearth</span>
                    <ArrowUpRight size={14} aria-hidden="true" />
                  </div>
                  <div className="suite-card-desc">{m.suiteHearthDesc()}</div>
                </div>
              </a>

              <a href={site.suite.monny} target="_blank" rel="noreferrer" className="suite-card">
                <img src="/suite/monny.png" alt="Monny" width={40} height={40} />
                <div>
                  <div className="suite-card-title">
                    <span>Monny</span>
                    <ArrowUpRight size={14} aria-hidden="true" />
                  </div>
                  <div className="suite-card-desc">{m.suiteMonnyDesc()}</div>
                </div>
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
