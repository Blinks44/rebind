import { Button } from '@moduix/react/button'
import { Heading } from '@moduix/react/heading'
import { Kbd } from '@moduix/react/kbd'
import { Text } from '@moduix/react/text'
import { ArrowLeft } from 'lucide-react'
import { Section } from '~/components'
import { m } from '~/paraglide/messages.js'
import { localizeHref } from '~/paraglide/runtime.js'
import { SiteFooter } from '../site-footer/SiteFooter'
import { SiteHeader } from '../site-header/SiteHeader'
import styles from './NotFound.module.css'

/**
 * "404" spelled with the app's raised keycaps. The drop-in is a CSS animation, so the server-rendered
 * page shows the keys even before scripts load; each key presses down under the pointer.
 */
export function NotFound() {
  return (
    <>
      <title>{`404 · ${m.not_found_title()} · Rebind`}</title>
      <meta name="robots" content="noindex" />
      <SiteHeader />
      <main>
        <Section flush className={styles.page}>
          <div className={styles.keys} aria-label="404">
            {['4', '0', '4'].map((digit, index) => (
              <Kbd key={index} className={styles.key} aria-hidden>
                {digit}
              </Kbd>
            ))}
          </div>
          <Heading as="h1" className={styles.title}>
            {m.not_found_title()}
          </Heading>
          <Text className={styles.text}>{m.not_found_text()}</Text>
          <Button asChild size="xl" className={styles.home}>
            <a href={localizeHref('/')}>
              <ArrowLeft size={18} aria-hidden /> {m.not_found_home()}
            </a>
          </Button>
        </Section>
      </main>
      <SiteFooter />
    </>
  )
}
