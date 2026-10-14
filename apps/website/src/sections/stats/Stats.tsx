import { Card } from '@moduix/react/card'
import { Keyboard, Languages, type LucideIcon, ShieldCheck, Tag } from 'lucide-react'
import { ActionTile, Reveal, Section } from '~/components'
import { m } from '~/paraglide/messages.js'
import styles from './Stats.module.css'

export function Stats() {
  return (
    <Section flush>
      <Reveal>
        <Card asChild className={styles.stats}>
          <dl>
            <Stat icon={Tag} value={m.stat_price_value()} label={m.stat_price_label()} />
            <Stat icon={ShieldCheck} value={m.stat_data_value()} label={m.stat_data_label()} />
            <Stat icon={Keyboard} value={m.stat_inputs_value()} label={m.stat_inputs_label()} />
            <Stat icon={Languages} value={m.stat_languages_value()} label={m.stat_languages_label()} />
          </dl>
        </Card>
      </Reveal>
    </Section>
  )
}

function Stat({ icon, value, label }: { icon: LucideIcon; value: string; label: string }) {
  return (
    <div className={styles.stat}>
      <ActionTile icon={icon} />
      <dt className={styles.label}>{label}</dt>
      <dd className={styles.value}>{value}</dd>
    </div>
  )
}
