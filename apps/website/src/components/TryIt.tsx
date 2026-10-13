import { Button } from '@moduix/react/button'
import { Check } from 'lucide-react'
import { AnimatePresence, motion } from 'motion/react'
import { type KeyboardEvent, useState } from 'react'
import { actions } from '~/actions'
import { m } from '~/paraglide/messages.js'
import { type Action, Binding, Keycaps } from './ui'

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

/** The page's own capture field: records a combination locally and pairs it with an action. */
export function TryIt() {
  const [keys, setKeys] = useState<string[] | null>(null)
  const [listening, setListening] = useState(false)
  const [action, setAction] = useState<Action | null>(null)
  const choices = [actions.missionControl(), actions.nextDesktop(), actions.playPause(), actions.closeWindow()]

  function onKeyDown(event: KeyboardEvent) {
    // Tab and Escape keep their meaning so the field never traps keyboard users.
    if (event.key === 'Tab' || event.key === 'Escape') return
    const combination = describe(event)
    if (!combination) return
    event.preventDefault()
    setKeys(combination)
    setAction(null)
  }

  return (
    <div className="card try">
      <button
        type="button"
        className="capture"
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
          <span className="capture-hint">{listening ? m.try_listening() : m.try_placeholder()}</span>
        )}
      </button>

      <AnimatePresence initial={false}>
        {keys && (
          <motion.div className="try-step" initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }}>
            <p className="try-label">{m.try_pick()}</p>
            <div className="try-choices">
              {choices.map((choice) => (
                <Button
                  key={choice.title}
                  variant={choice.title === action?.title ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setAction(choice)}
                >
                  <choice.icon size={15} aria-hidden /> {choice.title}
                </Button>
              ))}
            </div>
          </motion.div>
        )}
        {keys && action && (
          <motion.div className="try-step" initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }}>
            <div className="try-result">
              <Binding trigger={<Keycaps keys={keys} />} action={action} />
            </div>
            <p className="try-done">
              <Check size={16} aria-hidden /> {m.try_result()}
            </p>
          </motion.div>
        )}
      </AnimatePresence>
      <p className="try-privacy">{m.try_privacy()}</p>
    </div>
  )
}
