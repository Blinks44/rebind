import { Button } from '@moduix/react/button'
import { Container } from '@moduix/react/container'
import { LanguageMenu, Logo } from '~/components'
import { m } from '~/paraglide/messages.js'
import { localizeHref } from '~/paraglide/runtime.js'
import styles from './SiteHeader.module.css'

/** Links point at the landing page's anchors, so they also work from other pages such as 404. */
export function SiteHeader() {
  const home = localizeHref('/')
  return (
    <header className={styles.header}>
      <Container size="lg" className={styles.row}>
        <a className={styles.brand} href={`${home}#top`}>
          <Logo size={36} />
          Rebind
        </a>
        <nav className={styles.nav} aria-label={m.nav_sections()}>
          <a href={`${home}#scenarios`}>{m.nav_scenarios()}</a>
          <a href={`${home}#try`}>{m.nav_try()}</a>
          <a href={`${home}#faq`}>{m.nav_faq()}</a>
        </nav>
        <LanguageMenu />
        <Button asChild size="sm" className={styles.download}>
          <a href={`${home}#download`}>{m.nav_download()}</a>
        </Button>
      </Container>
    </header>
  )
}
