import { Button } from '@moduix/react/button'
import { Card } from '@moduix/react/card'
import { Empty } from '@moduix/react/empty'
import { Link } from '@tanstack/react-router'
import { CircleHelp } from 'lucide-react'
import { Keycap } from '@/components/keycap'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './NotFoundPage.module.css'

export function NotFoundPage() {
  return (
    <div className={styles.page}>
      <Empty className={styles.content}>
        <Card className={styles.binding} aria-hidden="true">
          <div className={styles.keys}>
            {['4', '0', '4'].map((key, index) => (
              <Keycap large key={index}>
                {key}
              </Keycap>
            ))}
          </div>
          <span className={styles.arrow}>
            <span>→</span>
            <span>↓</span>
          </span>
          <div className={styles.action}>
            <CircleHelp size={28} />
            <div>
              <strong>{m.noAction()}</strong>
              <span>{m.notBound()}</span>
            </div>
          </div>
        </Card>
        <p className={styles.code}>404</p>
        <h1>{m.notFoundHeading()}</h1>
        <p className={styles.lead}>{m.notFoundDescription()}</p>
        <div className={styles.actions}>
          <Button asChild size="xl">
            <Link to="/">{m.home()}</Link>
          </Button>
          <Button asChild size="xl" variant="outline">
            <a href={site.downloadUrl ?? site.releases}>{m.download()}</a>
          </Button>
        </div>
        <nav className={styles.links} aria-label={m.product()}>
          {[
            ['features', m.features()],
            ['devices', m.devices()],
            ['install', m.install()],
            ['faq', m.faq()],
          ].map(([hash, label]) => (
            <Link key={hash} to="/" hash={hash}>
              {label}
            </Link>
          ))}
          <a href={site.repository}>GitHub</a>
        </nav>
      </Empty>
      <footer className={styles.footer}>{m.legal()}</footer>
    </div>
  )
}
