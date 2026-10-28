import {
  BatteryLow,
  BatteryMedium,
  ChevronRight,
  Keyboard,
  Mouse,
  MousePointer2,
  Settings,
} from 'lucide-react'
import { m } from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { FeatureCard, FeatureSection, GroupLabel } from '../feature-section'
import styles from './MenuBarSection.module.css'

export function MenuBarSection() {
  const percent = new Intl.NumberFormat(getLocale(), { style: 'percent' })
  const devices = [
    [Mouse, 'MX Master 3S', 0.8, BatteryMedium],
    [Keyboard, 'G915 TKL', 0.45, BatteryMedium],
    [MousePointer2, 'Magic Mouse', 0.1, BatteryLow],
  ] as const
  return (
    <FeatureSection
      id="menu-bar"
      visualFirst
      eyebrow={m.menuEyebrow()}
      title={m.menuTitle()}
      lead={m.menuLead()}
      extras={
        <>
          <FeatureCard className={styles.lighting}>
            <GroupLabel>{m.keyboardLighting()} · G915 TKL</GroupLabel>
            <dl>
              <div>
                <dt>{m.lightBrightness()}</dt>
                <dd>
                  <span className={styles.slider} aria-hidden="true" />
                  {percent.format(0.5)}
                </dd>
              </div>
              <div>
                <dt>{m.lightColor()}</dt>
                <dd>
                  <span className={styles.color} aria-hidden="true" />
                </dd>
              </div>
              <div>
                <dt>{m.idleOff()}</dt>
                <dd>{m.twoMinutes()}</dd>
              </div>
            </dl>
          </FeatureCard>
          <p className={styles.note}>{m.lightingNote()}</p>
        </>
      }
    >
      <FeatureCard className={styles.card}>
        <figure className={styles.desktop} aria-label={m.menuPreview()}>
          <div className={styles.bar}>
            <svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true">
              <g fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round">
                <rect x="2" y="2.75" width="14" height="12.5" rx="3.6" strokeWidth="1.4" />
                <path
                  strokeWidth="1.3"
                  d="M5.6 7.3H12.4M10.6 5.5L12.4 7.3L10.6 9.1M12.4 10.7H5.6M7.4 8.9L5.6 10.7L7.4 12.5"
                />
              </g>
            </svg>
          </div>
          <div className={styles.menu}>
            <p className={styles.muted}>{m.bindingsOn()}</p>
            <p>{m.openRebind()}</p>
            <p>
              {m.profileLabel()}
              <ChevronRight size={14} aria-hidden="true" />
            </p>
            <p>{m.pause()}</p>
            <p>
              <span>
                <Settings size={14} aria-hidden="true" />
                {m.settings()}
              </span>
              <kbd>⌘,</kbd>
            </p>
            <hr />
            <p className={styles.muted}>{m.battery()}</p>
            {devices.map(([Icon, name, level, BatteryIcon]) => (
              <p key={name}>
                <span>
                  <Icon size={14} aria-hidden="true" />
                  {name}
                </span>
                <span className={styles.level} data-low={level < 0.2}>
                  {percent.format(level)}
                  <BatteryIcon size={18} aria-hidden="true" />
                </span>
              </p>
            ))}
            <hr />
            <p>{m.checkUpdates()}</p>
            <p>
              {m.quitRebind()}
              <kbd>⌘Q</kbd>
            </p>
          </div>
        </figure>
      </FeatureCard>
    </FeatureSection>
  )
}
