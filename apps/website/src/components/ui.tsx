import { Kbd, KbdGroup } from '@moduix/react/kbd'
import { ArrowRight, type LucideIcon } from 'lucide-react'
import { motion } from 'motion/react'
import type { ReactNode } from 'react'

/** The app icon, drawn from the same paths as `AppIcon.icon`. */
export function Logo({ size }: { size: number }) {
  return <img src="/favicon.svg" alt="" width={size} height={size} />
}

export function Keycaps({ keys }: { keys: string[] }) {
  return (
    <KbdGroup className="keycaps">
      {keys.map((key) => (
        <Kbd key={key} className={key.length > 3 ? 'keycap keycap-text' : 'keycap'}>
          {key}
        </Kbd>
      ))}
    </KbdGroup>
  )
}

export function TriggerChip({ icon: Icon, children }: { icon: LucideIcon; children: ReactNode }) {
  return (
    <span className="chip">
      <Icon size={15} aria-hidden />
      {children}
    </span>
  )
}

export function Tile({ icon: Icon }: { icon: LucideIcon }) {
  return (
    <span className="tile">
      <Icon size={16} aria-hidden />
    </span>
  )
}

export type Action = { icon: LucideIcon; title: string; category?: string }

/** One rule, as in the app's binding list: trigger, arrow, action, and an optional trailing control. */
export function Binding(props: { trigger: ReactNode; action: Action; trailing?: ReactNode; dimmed?: boolean }) {
  return (
    <div className="binding" data-dimmed={props.dimmed || undefined}>
      <div className="binding-trigger">{props.trigger}</div>
      <ArrowRight className="binding-arrow" size={14} aria-hidden />
      <div className="binding-action">
        <Tile icon={props.action.icon} />
        <span>
          <span className="binding-title">{props.action.title}</span>
          {props.action.category && <span className="binding-category">{props.action.category}</span>}
        </span>
      </div>
      {props.trailing}
    </div>
  )
}

/** Fades a block in as it scrolls into view. */
export function Reveal({ children, className, delay = 0 }: { children: ReactNode; className?: string; delay?: number }) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-80px' }}
      transition={{ duration: 0.5, delay, ease: 'easeOut' }}
    >
      {children}
    </motion.div>
  )
}
