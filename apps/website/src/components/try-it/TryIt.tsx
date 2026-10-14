import { Card } from '@moduix/react/card'
import { ToggleGroup, ToggleGroupItem } from '@moduix/react/toggle-group'
import { Check } from 'lucide-react'
import { AnimatePresence, motion } from 'motion/react'
import { type KeyboardEvent, useState } from 'react'
import { actions } from '~/lib/actions'
import { m } from '~/paraglide/messages.js'
import { Binding } from '../binding/Binding'
import { Keycaps } from '../keycaps/Keycaps'
import styles from './TryIt.module.css'

const choices = ['missionControl', 'nextDesktop', 'playPause', 'closeWindow'] as const

const keyLabels: Record<string, string> = {
  ' ': 'Space',
  ArrowUp: '↑',
  ArrowDown: '↓',
  ArrowLeft: '←',
  ArrowRight: '→',
  Enter: '↩',
  Backspace: '⌫',
}

/** Modifier glyphs in the macOS order, then the key; null while only modifiers are down. */
function describe(event: KeyboardEvent): string[] | null {
  if (['Control', 'Alt', 'Shift', 'Meta'].includes(event.key)) return null
  // `code` survives Option, which otherwise turns a letter into a symbol.
  const key = /^Key[A-Z]$|^Digit\d$/.test(event.code) ? event.code.slice(-1) : (keyLabels[event.key] ?? event.key)
  return [event.ctrlKey && '⌃', event.altKey && '⌥', event.shiftKey && '⇧', event.metaKey && '⌘', key.length === 1 ? key.toUpperCase() : key].filter(
    (part): part is string => Boolean(part),
  )
}

const reveal = { initial: { opacity: 0, height: 0 }, animate: { opacity: 1, height: 'auto' }, exit: { opacity: 0, height: 0 } }

/** The page's own capture field: records a combination locally and pairs it with an action. */
export function TryIt() {
  const [keys, setKeys] = useState<string[] | null>(null)
  const [listening, setListening] = useState(false)
  const [choice, setChoice] = useState<(typeof choices)[number] | null>(null)

  function onKeyDown(event: KeyboardEvent) {
    // Tab and Escape keep their meaning so the field never traps keyboard users.
    if (event.key === 'Tab' || event.key === 'Escape') return
    const combination = describe(event)
    if (!combination) return
    event.preventDefault()
    setKeys(combination)
    setChoice(null)
  }

  return (
    <Card className={styles.card}>
      <button
        type="button"
        className={styles.capture}
        data-listening={listening || undefined}
        onKeyDown={onKeyDown}
        onFocus={() => setListening(true)}
        onBlur={() => setListening(false)}
      >
        {keys ? (
          <motion.span key={keys.join()} initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}>
            <Keycaps keys={keys} />
          </motion.span>
        ) : (
          <span className={styles.hint}>{listening ? m.try_listening() : m.try_placeholder()}</span>
        )}
      </button>

      <AnimatePresence initial={false}>
        {keys && (
          <motion.div className={styles.step} {...reveal}>
            <p className={styles.note}>{m.try_pick()}</p>
            <ToggleGroup
              className={styles.choices}
              variant="outline"
              size="sm"
              multiple={false}
              aria-label={m.try_pick()}
              value={choice ? [choice] : []}
              onValueChange={({ value }) => setChoice((value[0] as (typeof choices)[number]) ?? null)}
            >
              {choices.map((key) => {
                const action = actions[key]()
                return (
                  <ToggleGroupItem key={key} value={key}>
                    <action.icon aria-hidden /> {action.title}
                  </ToggleGroupItem>
                )
              })}
            </ToggleGroup>
          </motion.div>
        )}
        {keys && choice && (
          <motion.div className={styles.step} {...reveal}>
            <div className={styles.result}>
              <Binding trigger={<Keycaps keys={keys} />} action={actions[choice]()} />
            </div>
            <p className={styles.done}>
              <Check size={16} aria-hidden /> {m.try_result()}
            </p>
          </motion.div>
        )}
      </AnimatePresence>
      <p className={styles.note}>{m.try_privacy()}</p>
    </Card>
  )
}
