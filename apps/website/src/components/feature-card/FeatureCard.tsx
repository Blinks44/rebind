import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@moduix/react/card'
import type { LucideIcon } from 'lucide-react'
import type { ReactNode } from 'react'
import { ActionTile } from '../action-tile/ActionTile'
import { Reveal } from '../reveal/Reveal'
import styles from './FeatureCard.module.css'

/** A feature as an icon tile, a title and a short text, with an optional illustration under it. */
export function FeatureCard(props: { icon: LucideIcon; title: string; text: string; className?: string; children?: ReactNode }) {
  return (
    <Reveal className={props.className}>
      <Card>
        <CardHeader className={styles.header}>
          <ActionTile icon={props.icon} size="lg" />
          <CardTitle asChild>
            <h3>{props.title}</h3>
          </CardTitle>
          <CardDescription>{props.text}</CardDescription>
        </CardHeader>
        {props.children && <CardBody>{props.children}</CardBody>}
      </Card>
    </Reveal>
  )
}
