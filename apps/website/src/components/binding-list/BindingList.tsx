import { Card } from '@moduix/react/card'
import { clsx } from 'clsx'
import type { ReactNode } from 'react'
import styles from './BindingList.module.css'

/** Rules on one raised card separated by hairlines, like the app's main list. */
export function BindingList({ children, className }: { children: ReactNode; className?: string }) {
  return <Card className={clsx(styles.list, className)}>{children}</Card>
}
