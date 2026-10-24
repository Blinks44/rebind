import { Button } from '@moduix/react/button'
import { Card } from '@moduix/react/card'
import { SquareArrowRight, Pause, Play } from 'lucide-react'
import { useEffect, useState } from 'react'
import { Keycap } from '@/components/keycap'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './HeroDemo.module.css'

export function HeroDemo() {
  const [example, setExample] = useState(0)
  const [pressed, setPressed] = useState<string | null>(null)
  const [paused, setPaused] = useState(false)
  const examples = [
    { keys: ['⌃', '⌥', 'J'], title: m.nextDesktop(), category: m.spaces() },
    { keys: ['F13'], title: m.missionControl(), category: m.windows() },
    { keys: ['⌥', 'W'], title: m.closeWindow(), category: m.windows() },
    { keys: [m.button4()], title: m.goBack(), category: m.navigation() },
  ]
  useEffect(() => {
    function showKey(event: KeyboardEvent) {
      const target = event.target
      if (
        !window.matchMedia('(hover: hover) and (pointer: fine)').matches ||
        event.repeat ||
        event.metaKey ||
        event.ctrlKey ||
        event.altKey
      )
        return
      if (
        target instanceof Element &&
        target.closest(
          'input, textarea, select, button, a, [contenteditable="true"], [role="tab"], [role="menuitemradio"]',
        )
      )
        return
      if (event.key.length !== 1 && !/^F\d{1,2}$/.test(event.key)) return
      setPressed(event.key.toUpperCase())
      setExample(event.key.toLowerCase() === 'w' ? 2 : event.key === 'F13' ? 1 : 0)
    }
    window.addEventListener('keydown', showKey)
    return () => window.removeEventListener('keydown', showKey)
  }, [])
  useEffect(() => {
    const touch = window.matchMedia('(hover: none) and (pointer: coarse)')
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)')
    let timer: ReturnType<typeof setInterval> | undefined
    function update() {
      clearInterval(timer)
      if (touch.matches && !reduce.matches && !paused)
        timer = setInterval(() => setExample((value) => (value + 1) % 3), 4000)
    }
    update()
    touch.addEventListener('change', update)
    reduce.addEventListener('change', update)
    return () => {
      clearInterval(timer)
      touch.removeEventListener('change', update)
      reduce.removeEventListener('change', update)
    }
  }, [paused])
  const current = examples[example]!
  function select(value: number) {
    setExample(value)
    setPressed(null)
    setPaused(true)
  }
  return (
    <Card className={styles.demo} aria-label={m.demoLabel()}>
      <div className={styles.mapping}>
        <div className={styles.trigger}>
          <p className={styles.caption}>{m.whenPress()}</p>
          <div className={styles.keys}>
            {(pressed ? [pressed] : current.keys).map((key, index) => (
              <Keycap key={`${key}-${index}`} large>
                {key}
              </Keycap>
            ))}
          </div>
        </div>
        <div className={styles.arrow} aria-hidden="true">
          <span>→</span>
          <span>↓</span>
        </div>
        <div className={styles.result}>
          <p className={styles.caption}>{m.rebindDoes()}</p>
          <div className={styles.action} aria-live={paused ? 'polite' : 'off'}>
            <span className={styles.tile}>
              <SquareArrowRight size={24} aria-hidden="true" />
            </span>
            <div>
              <strong>{current.title}</strong>
              <span>{current.category}</span>
            </div>
          </div>
        </div>
      </div>
      <div className={styles.bottom}>
        <p>{m.tryKey()}</p>
        <div className={styles.examples}>
          {[1, 2, 3].map((value) => (
            <Button key={value} variant="ghost" size="sm" onClick={() => select(value)}>
              {examples[value]!.keys.join('')} → {examples[value]!.title}
            </Button>
          ))}
        </div>
      </div>
      <div className={styles.mobileControls}>
        {[0, 1, 2].map((value) => (
          <button
            key={value}
            className={styles.dot}
            aria-label={examples[value]!.title}
            aria-pressed={example === value}
            onClick={() => select(value)}
          />
        ))}
        <Button
          size="icon-sm"
          variant="ghost"
          aria-label={paused ? m.playDemo() : m.pauseDemo()}
          onClick={() => setPaused((value) => !value)}
        >
          {paused ? <Play size={12} aria-hidden="true" /> : <Pause size={12} aria-hidden="true" />}
        </Button>
      </div>
    </Card>
  )
}
