import { Marquee, MarqueeContent, MarqueeItem, MarqueeViewport } from '@moduix/react/marquee'
import { ActionTile, Section, SectionHeading } from '~/components'
import { type Action, actions } from '~/lib/actions'
import { m } from '~/paraglide/messages.js'
import styles from './ActionCatalog.module.css'

/** Two rows of catalog actions drifting in opposite directions, full-bleed past the content width. */
export function ActionCatalog() {
  const catalog = Object.values(actions).map((action) => action())
  const half = Math.ceil(catalog.length / 2)
  return (
    <section className={styles.catalog}>
      <Section flush>
        <SectionHeading title={m.actions_title()} lead={m.actions_lead()} />
      </Section>
      <Row items={catalog.slice(0, half)} />
      <Row items={catalog.slice(half)} reverse />
    </section>
  )
}

function Row({ items, reverse }: { items: Action[]; reverse?: boolean }) {
  return (
    <Marquee className={styles.row} autoFill reverse={reverse} speed={32} spacing="12px" pauseOnInteraction aria-hidden={reverse}>
      <MarqueeViewport>
        <MarqueeContent>
          {items.map((action) => (
            <MarqueeItem key={action.title} className={styles.item}>
              <ActionTile icon={action.icon} /> {action.title}
            </MarqueeItem>
          ))}
        </MarqueeContent>
      </MarqueeViewport>
    </Marquee>
  )
}
