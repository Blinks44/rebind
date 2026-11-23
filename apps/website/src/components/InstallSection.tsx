import { AlertTriangle, Download, ExternalLink, FileCheck2, Terminal } from 'lucide-react'
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
            <div className="install-card-head">
              <h3>{m.installDmgTitle()}</h3>
              <span className="rb-keycap">v{release.version}</span>
            </div>
            <p>{m.installDmgDesc({ size: release.dmg.sizeLabel })}</p>
            <div>
              <a href={release.dmg.url} className="btn-rb-primary">
                <Download size={16} aria-hidden="true" />
                <span>{m.installDmgCta({ version: release.version })}</span>
              </a>
            </div>
            <div className="install-links">
              <a
                href={release.checksumsUrl}
                target="_blank"
                rel="noreferrer"
                className="install-link"
              >
                <FileCheck2 size={14} aria-hidden="true" />
                <span>SHA256SUMS.txt</span>
              </a>
              <a
                href={release.releaseUrl}
                target="_blank"
                rel="noreferrer"
                className="install-link"
              >
                <ExternalLink size={14} aria-hidden="true" />
                <span>{m.installAllReleases()}</span>
              </a>
            </div>
          </div>

          <div className="install-card">
            <div className="install-card-head">
              <h3>{m.installBrewTitle()}</h3>
              <Terminal size={18} style={{ color: 'var(--rb-accent)' }} aria-hidden="true" />
            </div>
            <p>{m.installBrewDesc()}</p>
            <div className="install-cmd-box">
              <code>{site.homebrewCommand}</code>
              <CopyButton text={site.homebrewCommand} showLabel />
            </div>
            <div className="install-links">
              <a href={site.homebrewTap} target="_blank" rel="noreferrer" className="install-link">
                <ExternalLink size={14} aria-hidden="true" />
                <span>blinks44/homebrew-tap</span>
              </a>
            </div>
          </div>
        </div>

        <div className="first-launch-callout" data-reveal>
          <div className="first-launch-head">
            <AlertTriangle size={16} aria-hidden="true" />
            <span>{m.installFirstLaunchTitle()}</span>
          </div>
          <p>{m.installFirstLaunchDesc()}</p>
          <div className="install-cmd-box">
            <code>{site.quarantineCommand}</code>
            <CopyButton text={site.quarantineCommand} showLabel />
          </div>
        </div>
      </div>
    </section>
  )
}
