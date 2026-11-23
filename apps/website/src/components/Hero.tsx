import { Download, ShieldCheck, Sparkles } from 'lucide-react'
import { CopyButton } from '@/components/CopyButton'
import { HeroRebindWindow } from '@/components/HeroRebindWindow'
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ReleaseInfo } from '@/integrations/releases'
import type { ColorScheme } from '@/lib/theme'

interface HeroProps {
  theme: ColorScheme
  release: ReleaseInfo
}

export function Hero({ theme, release }: HeroProps) {
  return (
    <section id="top" className="hero-section">
      <div className="container hero-inner">
        <div className="hero-badge">
          <span className="hero-badge-dot" aria-hidden="true" />
          <span>{m.heroBadge()}</span>
        </div>

        <h1 className="hero-title">
          {m.heroTitlePrefix()} <span className="hero-title-accent">{m.heroTitleAccent()}</span>
        </h1>

        <p className="hero-subtitle">{m.heroSubtitle()}</p>

        <div className="hero-actions">
          <a href={release.dmg.url} className="btn-rb-primary hero-cta-primary">
            <Download size={17} aria-hidden="true" />
            <span>{m.heroDownloadCta({ version: release.version })}</span>
          </a>

          <div className="hero-brew-pill">
            <code>{site.homebrewCommand}</code>
            <CopyButton text={site.homebrewCommand} />
          </div>
        </div>

        <div className="hero-meta-row">
          <span className="hero-meta-item">
            <Sparkles size={13} aria-hidden="true" />
            <span>{m.heroMetaMac({ size: release.dmg.sizeLabel })}</span>
          </span>
          <span className="hero-meta-item">
            <ShieldCheck size={13} aria-hidden="true" />
            <span>{m.heroMetaPrivacy()}</span>
          </span>
        </div>

        <HeroRebindWindow theme={theme} />
      </div>
    </section>
  )
}
