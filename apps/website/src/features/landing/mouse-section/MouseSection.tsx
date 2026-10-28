import {
  ArrowDown,
  ArrowLeft,
  ArrowRight,
  ArrowUp,
  LayoutGrid,
  Monitor,
  SquareArrowLeft,
  SquareArrowRight,
} from 'lucide-react'
import { Keycap } from '@/components/keycap'
import { m } from '@/integrations/i18n/paraglide/messages'
import { FeatureCard, FeatureSection, GroupLabel } from '../feature-section'
import styles from './MouseSection.module.css'

export function MouseSection() {
  const directions = [
    ['up', m.up(), ArrowUp, LayoutGrid, m.missionControl()],
    ['down', m.down(), ArrowDown, Monitor, m.showDesktop()],
    ['left', m.left(), ArrowLeft, SquareArrowLeft, m.previousSpace()],
    ['right', m.right(), ArrowRight, SquareArrowRight, m.nextSpace()],
  ] as const
  return (
    <FeatureSection
      id="mouse"
      visualFirst
      eyebrow={m.mouse()}
      title={m.mouseTitle()}
      lead={m.mouseLead()}
      extras={
        <>
          <FeatureCard className={styles.settings}>
            <GroupLabel>{m.logitechCard()}</GroupLabel>
            <dl>
              <div>
                <dt>{m.pointerSpeed()}</dt>
                <dd>
                  <span className={styles.slider} aria-hidden="true" />
                  1600 DPI
                </dd>
              </div>
              <div>
                <dt>SmartShift</dt>
                <dd className={styles.switch}>
                  <span className={styles.srOnly}>{m.on()}</span>
                </dd>
              </div>
              <div>
                <dt>{m.hiResWheel()}</dt>
                <dd className={styles.switch}>
                  <span className={styles.srOnly}>{m.on()}</span>
                </dd>
              </div>
              <div>
                <dt>{m.gestureButton()}</dt>
                <dd>{m.worksAsTrigger()}</dd>
              </div>
            </dl>
          </FeatureCard>
          <p className={styles.note}>{m.anyMouse()}</p>
        </>
      }
    >
      <FeatureCard className={styles.compass}>
        <div className={styles.key}>
          <Keycap>{m.holdButton4()}</Keycap>
        </div>
        <ul aria-label={m.directions()}>
          {directions.map(([direction, label, Arrow, Icon, action]) => (
            <li key={direction} className={styles[direction]}>
              <Arrow className={styles.arrow} size={24} aria-label={label} />
              <span className={styles.pill}>
                <span>
                  <Icon size={16} aria-hidden="true" />
                </span>
                {action}
              </span>
            </li>
          ))}
        </ul>
      </FeatureCard>
    </FeatureSection>
  )
}
