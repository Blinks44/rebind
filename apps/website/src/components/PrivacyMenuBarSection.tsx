import { HardDrive, LockKeyhole, ShieldAlert, Sparkles } from 'lucide-react'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ReleaseInfo } from '@/integrations/releases'

interface PrivacyMenuBarSectionProps {
  release: ReleaseInfo
}

export function PrivacyMenuBarSection({ release }: PrivacyMenuBarSectionProps) {
  const rules = [
    {
      icon: LockKeyhole,
      title: m.privacyR1Title(),
      desc: m.privacyR1Desc(),
    },
    {
      icon: ShieldAlert,
      title: m.privacyR2Title(),
      desc: m.privacyR2Desc(),
    },
    {
      icon: HardDrive,
      title: m.privacyR3Title(),
      desc: m.privacyR3Desc(),
    },
    {
      icon: Sparkles,
      title: m.privacyR4Title(),
      desc: m.privacyR4Desc(),
    },
  ]

  const metrics = [
    { value: `~${release.dmg.sizeLabel}`, label: m.metricSizeLabel() },
    { value: '0', label: m.metricTelemetryLabel() },
    { value: '4', label: m.metricStartersLabel() },
    { value: '6', label: m.metricLangsLabel() },
  ]

  return (
    <section id="privacy" className="privacy-band-wrap">
      <div className="container">
        <div className="privacy-band" data-reveal>
          <div className="privacy-grid">
            <div>
              <div className="eyebrow">{m.privacyEyebrow()}</div>
              <h2 className="section-title">{m.privacyTitle()}</h2>
              <p className="section-subtitle">{m.privacySubtitle()}</p>

              <div className="privacy-rules">
                {rules.map((rule) => {
                  const Icon = rule.icon
                  return (
                    <div key={rule.title} className="privacy-rule-card">
                      <div className="privacy-rule-head">
                        <Icon size={15} aria-hidden="true" />
                        <span>{rule.title}</span>
                      </div>
                      <p>{rule.desc}</p>
                    </div>
                  )
                })}
              </div>
            </div>

            <div className="menubar-stage">
              <figure className="menubar-card" style={{ margin: 0 }}>
                <img
                  src="/screenshots/menubar-battery-dark.webp"
                  alt={m.menubarBatteryAlt()}
                  width={472}
                  height={552}
                  loading="lazy"
                  decoding="async"
                  className="menubar-shot"
                />
                <figcaption className="menubar-caption">{m.menubarBatteryCaption()}</figcaption>
              </figure>

              <figure className="menubar-card" style={{ margin: 0 }}>
                <img
                  src="/screenshots/menubar-dpi-dark.webp"
                  alt={m.menubarDpiAlt()}
                  width={472}
                  height={716}
                  loading="lazy"
                  decoding="async"
                  className="menubar-shot"
                />
                <figcaption className="menubar-caption">{m.menubarDpiCaption()}</figcaption>
              </figure>
            </div>
          </div>

          <div className="metrics-row">
            {metrics.map((metric) => (
              <div key={metric.label} className="metric-item">
                <div className="metric-value">{metric.value}</div>
                <div className="metric-label">{metric.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
