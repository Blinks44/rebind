import { Badge, BadgeDot } from '@moduix/react/badge'
import type { ReactNode } from 'react'
import styles from './StatusBadge.module.css'

/** Green status pill with a dot, as in the app's toolbar. */
export function StatusBadge({ children }: { children: ReactNode }) {
  return (
    <Badge variant="outline" className={styles.badge}>
      <BadgeDot />
      {children}
    </Badge>
  )
}
