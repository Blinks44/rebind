import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="container site-footer-inner">
        <div className="footer-left">
          <img src="/app-icon.png" alt="Rebind" width={22} height={22} />
          <span>{m.footerNote()}</span>
        </div>

        <div className="footer-links">
          <a href={site.repository} target="_blank" rel="noreferrer">
            GitHub
          </a>
          <a href={site.releases} target="_blank" rel="noreferrer">
            {m.footerReleases()}
          </a>
          <a href={site.discussions} target="_blank" rel="noreferrer">
            {m.footerDiscussions()}
          </a>
          <a href={site.suite.hearth} target="_blank" rel="noreferrer">
            Hearth
          </a>
          <a href={site.suite.monny} target="_blank" rel="noreferrer">
            Monny
          </a>
          <a href={site.author.x} target="_blank" rel="noreferrer">
            {site.author.xHandle}
          </a>
        </div>
      </div>
    </footer>
  )
}
