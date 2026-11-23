import { Download, ExternalLink, ShieldCheck, Terminal } from 'lucide-react'
import { CopyButton } from '@/components/CopyButton'
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ReleaseInfo } from '@/integrations/releases'

interface InstallSectionProps {
  release: ReleaseInfo
}

export function InstallSection({ release }: InstallSectionProps) {
  return (
    <section id="install" className="section">
      <div className="container">
        <div className="section-head is-centered" data-reveal>
          <div className="eyebrow">{m.installEyebrow()}</div>
          <h2 className="section-title">{m.installTitle()}</h2>
          <p className="section-subtitle">{m.installSubtitle()}</p>
        </div>

        <div className="install-grid" data-reveal>
          <div className="install-card">
            <span className="install-card-icon" aria-hidden="true">
              <Download size={20} />
            </span>
            <h3>{m.installDmgTitle()}</h3>
            <p>{m.installDmgDesc({ size: release.dmg.sizeLabel })}</p>
            <div>
              <a href={release.dmg.url} className="btn-rebind-primary">
                <Download size={16} aria-hidden="true" />
                <span>{m.installDmgCta({ version: release.version })}</span>
              </a>
            </div>
            <p className="install-meta">{m.installDmgMeta()}</p>
          </div>

          <div className="install-card">
            <span className="install-card-icon" aria-hidden="true">
              <Terminal size={20} />
            </span>
            <h3>{m.installBrewTitle()}</h3>
            <p>{m.installBrewDesc()}</p>
            <div className="install-cmd-box">
              <code>{site.homebrewCommand}</code>
              <CopyButton text={site.homebrewCommand} showLabel />
            </div>
            <p className="install-meta">{m.installBrewNote()}</p>
          </div>
        </div>

        <div className="install-trust-bar" data-reveal>
          <div className="install-trust-left">
            <ShieldCheck size={20} color="var(--rb-green)" aria-hidden="true" />
            <div>
              <strong>{m.installTrustTitle()}</strong>
              <span>{m.installTrustDesc()}</span>
            </div>
          </div>

          <div className="install-trust-links">
            <a
              href={release.checksumsUrl}
              target="_blank"
              rel="noreferrer"
              className="btn-rebind-outline"
            >
              <span>SHA256SUMS.txt</span>
              <ExternalLink size={13} aria-hidden="true" />
            </a>
            <a
              href={release.releaseUrl}
              target="_blank"
              rel="noreferrer"
              className="btn-rebind-outline"
            >
              <span>{m.installAllReleases()}</span>
              <ExternalLink size={13} aria-hidden="true" />
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
