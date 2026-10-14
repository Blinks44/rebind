import { Container } from '@moduix/react/container'
import { m } from '~/paraglide/messages.js'
import styles from './SiteFooter.module.css'

export function SiteFooter() {
  return (
    <Container asChild size="lg">
      <footer className={styles.footer}>
        <span>© 2026 Rebind · MIT</span>
        <span>{m.requirement()}</span>
      </footer>
    </Container>
  )
}
