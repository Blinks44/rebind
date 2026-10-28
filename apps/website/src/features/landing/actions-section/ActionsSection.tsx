import { useState } from 'react'
import { Keycap } from '@/components/keycap'
import { m } from '@/integrations/i18n/paraglide/messages'
import { ChoiceChips, FeatureCard, FeatureSection, GroupLabel } from '../feature-section'
import styles from './ActionsSection.module.css'

type Layout = 'left' | 'right' | 'quarter' | 'center'

// Example bindings for the demo; Rebind ships no default shortcuts.
const shortcuts: Record<Layout, string> = { left: '←', right: '→', quarter: 'U', center: 'C' }

export function ActionsSection() {
  const [layout, setLayout] = useState<Layout>('left')
  const layouts = [
    ['left', m.leftHalf()],
    ['right', m.rightHalf()],
    ['quarter', m.topLeftQuarter()],
    ['center', m.centerWindow()],
  ] as const
  const groups = [
    [m.catKeyboard(), m.exKeyboard()],
    [m.catMouse(), m.exMouse()],
    [m.catSound(), m.playPause()],
    [m.catWindows(), m.exWindows()],
    [m.catSpaces(), m.nextSpace()],
    [m.catSystem(), m.captureArea()],
    [m.catAutomation(), m.runShortcut()],
    ['Rebind', m.nextProfile()],
  ]
  const title = layouts.find(([value]) => value === layout)![1]
  return (
    <FeatureSection
      id="actions"
      visualFirst
      eyebrow={m.actions()}
      title={m.actionsTitle()}
      lead={m.actionsLead()}
      extras={
        <dl className={styles.groups} aria-label={m.actionGroups()}>
          {groups.map(([group, example]) => (
            <div key={group}>
              <dt>{group}</dt>
              <dd>{example}</dd>
            </div>
          ))}
        </dl>
      }
    >
      <FeatureCard className={styles.card}>
        <GroupLabel>{m.exampleWindows()}</GroupLabel>
        <div className={styles.desktop} aria-hidden="true">
          <span className={styles.other} />
          <span className={styles.window} data-layout={layout}>
            {title}
          </span>
        </div>
        <p className={styles.shortcut} aria-live="polite">
          <Keycap>⌃</Keycap>
          <Keycap>⌥</Keycap>
          <Keycap>{shortcuts[layout]}</Keycap>
          <span aria-hidden="true">→</span>
          <strong>{title}</strong>
        </p>
        <ChoiceChips
          label={m.windowLayout()}
          options={layouts}
          value={layout}
          onValueChange={setLayout}
          className={styles.chips}
        />
      </FeatureCard>
    </FeatureSection>
  )
}
