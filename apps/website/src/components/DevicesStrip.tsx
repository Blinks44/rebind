import { ArrowRight, Cpu, Hand, Keyboard, LayoutGrid, Mouse, Waves } from 'lucide-react'
import { useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'

type HardwareKey = 'keyboard' | 'mouse' | 'logitech' | 'scroll' | 'touch' | 'windows'

export function DevicesStrip() {
  const [activeRule, setActiveRule] = useState(0)

  const rules: Array<{
    trigger: string
    action: string
    tag: string
    note: string
    hardware: HardwareKey[]
  }> = [
    {
      trigger: m.stripRule1Trigger(),
      action: m.stripRule1Action(),
      tag: m.stripRule1Tag(),
      note: m.stripRule1Note(),
      hardware: ['mouse', 'windows'],
    },
    {
      trigger: m.stripRule2Trigger(),
      action: m.stripRule2Action(),
      tag: m.stripRule2Tag(),
      note: m.stripRule2Note(),
      hardware: ['keyboard', 'windows'],
    },
    {
      trigger: m.stripRule3Trigger(),
      action: m.stripRule3Action(),
      tag: m.stripRule3Tag(),
      note: m.stripRule3Note(),
      hardware: ['touch'],
    },
    {
      trigger: m.stripRule4Trigger(),
      action: m.stripRule4Action(),
      tag: m.stripRule4Tag(),
      note: m.stripRule4Note(),
      hardware: ['logitech', 'scroll'],
    },
  ]

  const items: Array<{ key: HardwareKey; icon: typeof Keyboard; label: string }> = [
    { key: 'keyboard', icon: Keyboard, label: m.stripKeyboard() },
    { key: 'mouse', icon: Mouse, label: m.stripMouse() },
    { key: 'logitech', icon: Cpu, label: m.stripLogitech() },
    { key: 'scroll', icon: Waves, label: m.stripSmoothScroll() },
    { key: 'touch', icon: Hand, label: m.stripTouch() },
    { key: 'windows', icon: LayoutGrid, label: m.stripWindows() },
  ]

  const currentRule = rules[activeRule] ?? rules[0]

  return (
    <section className="devices-strip" aria-label={m.stripEyebrow()}>
      <div className="container">
        <div className="devices-strip-label">{m.stripEyebrow()}</div>

        <div className="binding-showcase-grid" role="tablist" aria-label={m.stripEyebrow()}>
          {rules.map((rule, idx) => {
            const isActive = idx === activeRule
            return (
              <button
                key={rule.tag}
                type="button"
                role="tab"
                aria-selected={isActive}
                className={`binding-recipe-card ${isActive ? 'is-active' : ''}`}
                onClick={() => setActiveRule(idx)}
              >
                <span className="binding-recipe-tag">{rule.tag}</span>
                <span className="binding-recipe-flow">
                  <kbd className="binding-recipe-keycap">{rule.trigger}</kbd>
                  <ArrowRight size={13} className="binding-recipe-arrow" aria-hidden="true" />
                  <span className="binding-recipe-action">{rule.action}</span>
                </span>
              </button>
            )
          })}
        </div>

        {currentRule ? <p className="binding-detail-note">{currentRule.note}</p> : null}

        <div className="devices-pill-grid">
          {items.map((item) => {
            const Icon = item.icon
            const isMatched = currentRule?.hardware.includes(item.key) ?? false
            return (
              <div key={item.key} className={`device-pill ${isMatched ? 'is-highlighted' : ''}`}>
                <Icon size={15} aria-hidden="true" />
                <span>{item.label}</span>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
