import { Link } from '@tanstack/react-router'
import { ArrowRight } from 'lucide-react'
import * as m from '@/integrations/i18n/paraglide/messages'

export function ReplacesSection() {
  return (
    <section id="replaces" className="seo-section">
      <div className="container">
        <div className="section-head is-centered" data-reveal>
          <div className="eyebrow">{m.replacesEyebrow()}</div>
          <h2 className="section-title">{m.replacesTitle()}</h2>
          <p className="section-subtitle">{m.replacesSubtitle()}</p>
        </div>

        <div className="seo-table-card" data-reveal>
          <div className="seo-table-scroll">
            <table className="seo-replaces-table">
              <thead>
                <tr>
                  <th scope="col">{m.replacesColWorkflow()}</th>
                  <th scope="col">{m.replacesColTools()}</th>
                  <th scope="col">{m.replacesColRebind()}</th>
                  <th scope="col" className="seo-col-action">
                    {m.replacesColDetails()}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <th scope="row" className="seo-cell-category">
                    {m.replacesRow1Cat()}
                  </th>
                  <td className="seo-cell-tools">{m.replacesRow1Tools()}</td>
                  <td className="seo-cell-rebind">{m.replacesRow1Rebind()}</td>
                  <td className="seo-col-action">
                    <Link to="/alternatives/logi-options-ghub/" className="seo-inline-link">
                      <span>{m.replacesRow1Cta()}</span>
                      <ArrowRight size={14} aria-hidden="true" />
                    </Link>
                  </td>
                </tr>
                <tr>
                  <th scope="row" className="seo-cell-category">
                    {m.replacesRow2Cat()}
                  </th>
                  <td className="seo-cell-tools">{m.replacesRow2Tools()}</td>
                  <td className="seo-cell-rebind">{m.replacesRow2Rebind()}</td>
                  <td className="seo-col-action">
                    <Link to="/alternatives/linearmouse-mos/" className="seo-inline-link">
                      <span>{m.replacesRow2Cta()}</span>
                      <ArrowRight size={14} aria-hidden="true" />
                    </Link>
                  </td>
                </tr>
                <tr>
                  <th scope="row" className="seo-cell-category">
                    {m.replacesRow3Cat()}
                  </th>
                  <td className="seo-cell-tools">{m.replacesRow3Tools()}</td>
                  <td className="seo-cell-rebind">{m.replacesRow3Rebind()}</td>
                  <td className="seo-col-action">
                    <Link to="/alternatives/steermouse/" className="seo-inline-link">
                      <span>{m.replacesRow3Cta()}</span>
                      <ArrowRight size={14} aria-hidden="true" />
                    </Link>
                  </td>
                </tr>
                <tr>
                  <th scope="row" className="seo-cell-category">
                    {m.replacesRow4Cat()}
                  </th>
                  <td className="seo-cell-tools">{m.replacesRow4Tools()}</td>
                  <td className="seo-cell-rebind">{m.replacesRow4Rebind()}</td>
                  <td className="seo-col-action">
                    <Link to="/guides/mx-master-mac-setup/" className="seo-inline-link">
                      <span>{m.replacesRow4Cta()}</span>
                      <ArrowRight size={14} aria-hidden="true" />
                    </Link>
                  </td>
                </tr>
                <tr>
                  <th scope="row" className="seo-cell-category">
                    {m.replacesRow5Cat()}
                  </th>
                  <td className="seo-cell-tools">{m.replacesRow5Tools()}</td>
                  <td className="seo-cell-rebind">{m.replacesRow5Rebind()}</td>
                  <td className="seo-col-action">
                    <a href="#features" className="seo-inline-link">
                      <span>{m.replacesRow5Cta()}</span>
                      <ArrowRight size={14} aria-hidden="true" />
                    </a>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div className="seo-scope-bar" data-reveal>
          <p>{m.replacesScopeNote()}</p>
          <span className="seo-scope-badge">{m.replacesBadge()}</span>
        </div>
      </div>
    </section>
  )
}
