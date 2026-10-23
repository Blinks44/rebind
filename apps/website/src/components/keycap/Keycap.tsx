import { Kbd } from '@moduix/react/kbd'
import type { ReactNode } from 'react'
import styles from './Keycap.module.css'

export function Keycap({ children, large = false }: { children: ReactNode; large?: boolean }) {
  return <Kbd className={large ? styles.large : styles.cap}>{children}</Kbd>
}
