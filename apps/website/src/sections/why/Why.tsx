import { clsx } from 'clsx'
import { AppWindow, BadgeCheck, DatabaseBackup, Layers, LockKeyhole, Pause, Repeat, Sparkles } from 'lucide-react'
import { FeatureCard, Section, SectionHeading } from '~/components'
import { m } from '~/paraglide/messages.js'
import styles from './Why.module.css'

export function Why() {
  return (
    <Section>
      <SectionHeading title={m.why_title()} />
      <div className={styles.grid}>
        <FeatureCard className={clsx(styles.cell, styles.large)} icon={BadgeCheck} title={m.why_free_title()} text={m.why_free_text()} />
        <FeatureCard className={clsx(styles.cell, styles.large)} icon={LockKeyhole} title={m.why_private_title()} text={m.why_private_text()} />
        <FeatureCard className={styles.cell} icon={Sparkles} title={m.why_native_title()} text={m.why_native_text()} />
        <FeatureCard className={styles.cell} icon={Layers} title={m.why_profiles_title()} text={m.why_profiles_text()} />
        <FeatureCard className={styles.cell} icon={Pause} title={m.why_pause_title()} text={m.why_pause_text()} />
        <FeatureCard className={styles.cell} icon={AppWindow} title={m.why_apps_title()} text={m.why_apps_text()} />
        <FeatureCard className={styles.cell} icon={Repeat} title={m.why_repeat_title()} text={m.why_repeat_text()} />
        <FeatureCard className={styles.cell} icon={DatabaseBackup} title={m.why_backup_title()} text={m.why_backup_text()} />
      </div>
    </Section>
  )
}
