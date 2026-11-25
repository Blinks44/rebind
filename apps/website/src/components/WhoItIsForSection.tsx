import { Link } from '@tanstack/react-router'
import { ArrowRight, Check, Keyboard, Mouse, SlidersHorizontal } from 'lucide-react'
import * as m from '@/integrations/i18n/paraglide/messages'

export function WhoItIsForSection() {
  return (
    <section className="seo-section seo-section-surface">
      <div className="container">
        <div className="section-head is-centered" data-reveal>
          <div className="eyebrow">{m.whoEyebrow()}</div>
          <h2 className="section-title">{m.whoTitle()}</h2>
          <p className="section-subtitle">{m.whoSubtitle()}</p>
        </div>

        <div className="seo-who-grid seo-who-grid-3">
          <article className="seo-who-card seo-who-card-accent" data-reveal>
            <div className="seo-who-label-row">
              <span className="seo-who-badge seo-who-badge-accent">
                <Mouse size={13} aria-hidden="true" />
                <span>{m.whoLogiLabel()}</span>
              </span>
            </div>
            <h3>{m.whoLogiTitle()}</h3>
            <p className="seo-who-desc">{m.whoLogiDesc()}</p>
            <ul className="seo-check-list">
              <li>
                <Check size={15} className="seo-check-icon" aria-hidden="true" />
                <span>{m.whoLogiBullet1()}</span>
              </li>
              <li>
                <Check size={15} className="seo-check-icon" aria-hidden="true" />
                <span>{m.whoLogiBullet2()}</span>
              </li>
              <li>
                <Check size={15} className="seo-check-icon" aria-hidden="true" />
                <span>{m.whoLogiBullet3()}</span>
              </li>
            </ul>
            <Link to="/alternatives/logi-options-ghub/" className="seo-card-link">
              <span>{m.whoLogiCta()}</span>
              <ArrowRight size={15} aria-hidden="true" />
            </Link>
          </article>

          <article className="seo-who-card seo-who-card-green" data-reveal>
            <div className="seo-who-label-row">
              <span className="seo-who-badge seo-who-badge-green">
                <SlidersHorizontal size={13} aria-hidden="true" />
                <span>{m.whoScrollLabel()}</span>
              </span>
            </div>
            <h3>{m.whoScrollTitle()}</h3>
            <p className="seo-who-desc">{m.whoScrollDesc()}</p>
            <ul className="seo-check-list">
              <li>
                <Check size={15} className="seo-check-icon" aria-hidden="true" />
                <span>{m.whoScrollBullet1()}</span>
              </li>
              <li>
                <Check size={15} className="seo-check-icon" aria-hidden="true" />
                <span>{m.whoScrollBullet2()}</span>
              </li>
              <li>
                <Check size={15} className="seo-check-icon" aria-hidden="true" />
                <span>{m.whoScrollBullet3()}</span>
              </li>
            </ul>
            <Link to="/alternatives/linearmouse-mos/" className="seo-card-link">
              <span>{m.whoScrollCta()}</span>
              <ArrowRight size={15} aria-hidden="true" />
            </Link>
          </article>

          <article className="seo-who-card" data-reveal>
            <div className="seo-who-label-row">
              <span className="seo-who-badge seo-who-badge-neutral">
                <Keyboard size={13} aria-hidden="true" />
                <span>{m.whoKeysLabel()}</span>
              </span>
            </div>
            <h3>{m.whoKeysTitle()}</h3>
            <p className="seo-who-desc">{m.whoKeysDesc()}</p>
            <ul className="seo-check-list">
              <li>
                <Check size={15} className="seo-check-icon" aria-hidden="true" />
                <span>{m.whoKeysBullet1()}</span>
              </li>
              <li>
                <Check size={15} className="seo-check-icon" aria-hidden="true" />
                <span>{m.whoKeysBullet2()}</span>
              </li>
              <li>
                <Check size={15} className="seo-check-icon" aria-hidden="true" />
                <span>{m.whoKeysBullet3()}</span>
              </li>
            </ul>
            <a href="#replaces" className="seo-card-link">
              <span>{m.whoKeysCta()}</span>
              <ArrowRight size={15} aria-hidden="true" />
            </a>
          </article>
        </div>
      </div>
    </section>
  )
}
