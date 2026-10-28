import { Keycap } from '@/components/keycap'
import { m } from '@/integrations/i18n/paraglide/messages'
import { FeatureCard, FeatureSection, GroupLabel } from '../feature-section'
import styles from './PrivacySection.module.css'

export function PrivacySection() {
  return (
    <FeatureSection
      id="privacy"
      eyebrow={m.privacyEyebrow()}
      title={m.privacyTitle()}
      lead={m.privacyLead()}
    >
      <FeatureCard className={styles.card}>
        <GroupLabel>{m.emergencyPause()}</GroupLabel>
        <p className={styles.shortcut}>
          <span className={styles.keys}>
            {['⌃', '⌥', '⇧', '⌘', 'Esc'].map((key) => (
              <Keycap key={key}>{key}</Keycap>
            ))}
          </span>
          <span className={styles.arrow} aria-hidden="true">
            →
          </span>
          <strong>{m.pausesEverything()}</strong>
        </p>
        <p className={styles.note}>{m.emergencyNote()}</p>
      </FeatureCard>
    </FeatureSection>
  )
}
