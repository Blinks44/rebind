import { Tag, TagLabel, TagStartElement } from '@moduix/react/tag'
import type { LucideIcon } from 'lucide-react'
import type { ReactNode } from 'react'
import styles from './TriggerChip.module.css'

/** A trigger that is not a physical key: a mouse button, a gesture or the wheel. */
export function TriggerChip({ icon: Icon, children }: { icon: LucideIcon; children: ReactNode }) {
  return (
    <Tag variant="secondary" className={styles.chip}>
      <TagStartElement>
        <Icon aria-hidden />
      </TagStartElement>
      <TagLabel className={styles.label}>{children}</TagLabel>
    </Tag>
  )
}
