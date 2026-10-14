import { Card, CardDescription, CardHeader, CardTitle } from '@moduix/react/card'
import { clsx } from 'clsx'
import { BadgeCheck, Layers, LockKeyhole, type LucideIcon, Pause, Sparkles } from 'lucide-react'
import { ActionTile, Reveal, Section, SectionHeading } from '~/components'
import { m } from '~/paraglide/messages.js'
import styles from './Why.module.css'

export function Why() {
  return (
    <Section>
      <SectionHeading title={m.why_title()} />
      <div className={styles.grid}>
        <Reason icon={BadgeCheck} title={m.why_free_title()} text={m.why_free_text()} large />
        <Reason icon={LockKeyhole} title={m.why_private_title()} text={m.why_private_text()} large />
        <Reason icon={Sparkles} title={m.why_native_title()} text={m.why_native_text()} />
        <Reason icon={Layers} title={m.why_profiles_title()} text={m.why_profiles_text()} />
        <Reason icon={Pause} title={m.why_pause_title()} text={m.why_pause_text()} />
      </div>
    </Section>
  )
}

function Reason(props: { icon: LucideIcon; title: string; text: string; large?: boolean }) {
  return (
    <Reveal className={clsx(styles.cell, props.large && styles.large)}>
      <Card>
        <CardHeader className={styles.header}>
          <ActionTile icon={props.icon} size="lg" />
          <CardTitle asChild>
            <h3 className={styles.title}>{props.title}</h3>
          </CardTitle>
          <CardDescription>{props.text}</CardDescription>
        </CardHeader>
      </Card>
    </Reveal>
  )
}
