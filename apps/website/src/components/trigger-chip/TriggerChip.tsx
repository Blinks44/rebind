import { Kbd } from '@moduix/react/kbd'
import { clsx } from 'clsx'
import type { LucideIcon } from 'lucide-react'
import type { ReactNode } from 'react'
import keycaps from '../keycaps/Keycaps.module.css'
import styles from './TriggerChip.module.css'

/** A trigger that is not a keyboard key (mouse button, gesture, wheel or touch) as a raised keycap;
 * the leading icon names the input type, as in the app. */
export function TriggerChip({ icon: Icon, children }: { icon: LucideIcon; children: ReactNode }) {
  return (
    <Kbd className={clsx(keycaps.key, keycaps.word, styles.chip)}>
      <Icon aria-hidden className={styles.icon} />
      {children}
    </Kbd>
  )
}
