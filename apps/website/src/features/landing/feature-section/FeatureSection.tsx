import { Card } from '@moduix/react/card'
import { ToggleGroup, ToggleGroupItem } from '@moduix/react/toggle-group'
import type { LucideIcon } from 'lucide-react'
import type { ComponentProps, ReactNode } from 'react'
import styles from './FeatureSection.module.css'

/** A product section: text with optional extras on one side, the illustration on the other. */
export function FeatureSection({
  id,
  eyebrow,
  title,
  lead,
  extras,
  visualFirst = false,
  children,
}: {
  id: string
  eyebrow: string
  title: string
  lead: string
  extras?: ReactNode
  visualFirst?: boolean
  children: ReactNode
}) {
  return (
    <section
      id={id}
      className={visualFirst ? `${styles.section} ${styles.visualFirst}` : styles.section}
      aria-labelledby={`${id}-title`}
    >
      <div className={styles.text}>
        <p className={styles.eyebrow}>{eyebrow}</p>
        <h2 id={`${id}-title`} className={styles.title}>
          {title}
        </h2>
        <p className={styles.lead}>{lead}</p>
      </div>
      <div className={styles.visual}>{children}</div>
      {extras && <div className={styles.extras}>{extras}</div>}
    </section>
  )
}

export function FeatureCard({ className, ...props }: ComponentProps<typeof Card>) {
  return <Card className={className ? `${styles.card} ${className}` : styles.card} {...props} />
}

export function GroupLabel({ children }: { children: ReactNode }) {
  return <p className={styles.groupLabel}>{children}</p>
}

export function ActionRow({
  icon: Icon,
  title,
  caption,
}: {
  icon: LucideIcon
  title: string
  caption: string
}) {
  return (
    <div className={styles.action}>
      <span className={styles.tile}>
        <Icon size={20} aria-hidden="true" />
      </span>
      <span>
        <strong>{title}</strong>
        <span>{caption}</span>
      </span>
    </div>
  )
}

/** Single-select chips that switch an illustration; one option always stays selected. */
export function ChoiceChips<Value extends string>({
  label,
  options,
  value,
  onValueChange,
  className,
}: {
  label: string
  options: readonly (readonly [Value, string])[]
  value: Value
  onValueChange: (value: Value) => void
  className?: string
}) {
  return (
    <ToggleGroup
      aria-label={label}
      className={className ? `${styles.chips} ${className}` : styles.chips}
      value={[value]}
      deselectable={false}
      onValueChange={(details) => {
        const next = details.value[0] as Value | undefined
        if (next) onValueChange(next)
      }}
    >
      {options.map(([option, text]) => (
        <ToggleGroupItem key={option} value={option} size="sm" className={styles.chip}>
          {text}
        </ToggleGroupItem>
      ))}
    </ToggleGroup>
  )
}
