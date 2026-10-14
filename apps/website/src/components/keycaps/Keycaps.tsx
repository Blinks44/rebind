import { Kbd, KbdGroup } from '@moduix/react/kbd'
import { clsx } from 'clsx'
import styles from './Keycaps.module.css'

/** Physical keys as raised keycaps; the look comes from the moduix Kbd tokens in the theme. */
export function Keycaps({ keys }: { keys: string[] }) {
  return (
    <KbdGroup className={styles.group}>
      {keys.map((key) => (
        <Kbd key={key} className={clsx(styles.key, key.length > 3 && styles.word)}>
          {key}
        </Kbd>
      ))}
    </KbdGroup>
  )
}
