import { Cpu, Hand, Keyboard, LayoutGrid, Mouse, Waves } from 'lucide-react'
import * as m from '@/integrations/i18n/paraglide/messages'

export function DevicesStrip() {
  const items = [
    { icon: Keyboard, label: m.stripKeyboard() },
    { icon: Mouse, label: m.stripMouse() },
    { icon: Cpu, label: m.stripLogitech() },
    { icon: Waves, label: m.stripSmoothScroll() },
    { icon: Hand, label: m.stripTouch() },
    { icon: LayoutGrid, label: m.stripWindows() },
  ]

  return (
    <section className="devices-strip" aria-label={m.stripEyebrow()}>
      <div className="container">
        <div className="devices-strip-label">{m.stripEyebrow()}</div>
        <div className="devices-pill-grid">
          {items.map((item) => {
            const Icon = item.icon
            return (
              <div key={item.label} className="device-pill">
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
