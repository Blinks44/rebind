import { clsx } from 'clsx'
import type { LucideIcon } from 'lucide-react'
import styles from './ActionTile.module.css'

/** Accent tile that carries an action symbol, as in the app's lists. */
export function ActionTile({ icon: Icon, size = 'md' }: { icon: LucideIcon; size?: 'md' | 'lg' }) {
  return (
    <span className={clsx(styles.tile, size === 'lg' && styles.large)}>
      <Icon size={16} aria-hidden />
    </span>
  )
}
