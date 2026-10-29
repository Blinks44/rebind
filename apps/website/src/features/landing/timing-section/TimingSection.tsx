import { LayoutGrid, Play, SkipForward } from 'lucide-react'
import { Keycap } from '@/components/keycap'
import { m } from '@/integrations/i18n/paraglide/messages'
import { ActionRow, FeatureCard, FeatureSection, GroupLabel } from '../feature-section'
import styles from './TimingSection.module.css'

export function TimingSection() {
  // One binding per key: press, double press and hold on the same key conflict.
  const rows = [
    ['press', 'F5', m.press(), m.playPause(), m.catSound(), Play],
    ['double', 'F6', m.doublePress(), m.nextTrack(), m.catSound(), SkipForward],
    ['hold', 'F7', m.hold(), m.missionControl(), m.catSpaces(), LayoutGrid],
  ] as const
  return (
    <FeatureSection
      id="timing"
      eyebrow={m.timingEyebrow()}
      title={m.timingTitle()}
      lead={m.timingLead()}
      extras={
        <FeatureCard className={styles.roles}>
          <GroupLabel>{m.tapHoldTitle()}</GroupLabel>
          <dl>
            {[
              [m.tap(), 'Esc'],
              [m.hold(), m.controlWhileHeld()],
            ].map(([label, result]) => (
              <div key={label}>
                <dt>{label}</dt>
                <dd>
                  <Keycap>Esc</Keycap>
                  <span aria-hidden="true">→</span>
                  {result}
                </dd>
              </div>
            ))}
          </dl>
        </FeatureCard>
      }
    >
      <FeatureCard>
        <ul className={styles.rows}>
          {rows.map(([kind, key, label, title, caption, icon]) => (
            <li key={kind} className={styles.row}>
              <GroupLabel>{label}</GroupLabel>
              <div className={styles.input}>
                <Keycap>{key}</Keycap>
                <span className={styles.track} data-kind={kind} aria-hidden="true">
                  <span />
                  {kind === 'double' && <span />}
                  {kind === 'hold' && <i>{m.holdTime()}</i>}
                </span>
              </div>
              <ActionRow icon={icon} title={title} caption={caption} />
            </li>
          ))}
        </ul>
        <p className={styles.note}>{m.timingNote()}</p>
      </FeatureCard>
    </FeatureSection>
  )
}
