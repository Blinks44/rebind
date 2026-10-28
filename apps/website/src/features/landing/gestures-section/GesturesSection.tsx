import { Badge } from '@moduix/react/badge'
import { useState } from 'react'
import { m } from '@/integrations/i18n/paraglide/messages'
import { ChoiceChips, FeatureCard, FeatureSection } from '../feature-section'
import styles from './GesturesSection.module.css'

type Gesture = 'tap3' | 'tap4' | 'double2' | 'corner'

export function GesturesSection() {
  const [gesture, setGesture] = useState<Gesture>('tap3')
  const gestures = [
    ['tap3', m.tap3()],
    ['tap4', m.tap4()],
    ['double2', m.doubleTap2()],
    ['corner', m.cornerTopRight()],
  ] as const
  const results: Record<Gesture, string> = {
    tap3: m.showDesktop(),
    tap4: m.missionControl(),
    double2: m.playPause(),
    corner: m.captureArea(),
  }
  const fingers = { tap3: 3, tap4: 4, double2: 2, corner: 1 }[gesture]
  const label = gestures.find(([value]) => value === gesture)![1]
  return (
    <FeatureSection
      id="gestures"
      eyebrow={m.touchDevices()}
      title={m.gesturesTitle()}
      lead={m.gesturesLead()}
      extras={
        <>
          <Badge variant="outline" className={styles.badge}>
            <span aria-hidden="true" />
            {m.experimentalBadge()}
          </Badge>
          <p className={styles.note}>{m.gesturesNote()}</p>
        </>
      }
    >
      <FeatureCard className={styles.card}>
        <div className={styles.surface}>
          <span className={styles.corner} data-active={gesture === 'corner'} aria-hidden="true" />
          <div key={gesture} className={styles.fingers} data-gesture={gesture} aria-hidden="true">
            {Array.from({ length: fingers }, (_, index) => (
              <span key={index} />
            ))}
          </div>
          <p className={styles.caption} aria-live="polite">
            {label} → {results[gesture]}
          </p>
        </div>
        <ChoiceChips
          label={m.gesture()}
          options={gestures}
          value={gesture}
          onValueChange={setGesture}
          className={styles.chips}
        />
      </FeatureCard>
    </FeatureSection>
  )
}
