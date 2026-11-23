import {
  Dialog,
  DialogBackdrop,
  DialogCloseIcon,
  DialogContent,
  DialogPositioner,
  DialogTitle,
} from '@moduix/react/dialog'
import {
  Cpu,
  Hand,
  Keyboard,
  Maximize2,
  Mouse,
  MousePointerClick,
  Settings,
  Touchpad,
} from 'lucide-react'
import { useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ColorScheme } from '@/lib/theme'

type PanelId =
  | 'keyboard'
  | 'mouse'
  | 'trackpad'
  | 'magic-trackpad'
  | 'magic-mouse'
  | 'devices'
  | 'settings'

interface HeroRebindWindowProps {
  theme: ColorScheme
}

export function HeroRebindWindow({ theme }: HeroRebindWindowProps) {
  const [active, setActive] = useState<PanelId>('keyboard')
  const [lightboxOpen, setLightboxOpen] = useState(false)

  const suffix = theme === 'dark' ? 'dark' : 'light'

  const inputItems: Array<{
    id: PanelId
    label: string
    badge?: string
    badgeKind?: 'exp' | 'accent'
    icon: typeof Keyboard
  }> = [
    { id: 'keyboard', label: m.shellNavKeyboard(), badge: '7', icon: Keyboard },
    { id: 'mouse', label: m.shellNavMouse(), badge: '6', icon: Mouse },
    { id: 'trackpad', label: m.shellNavTrackpad(), badge: 'Exp', badgeKind: 'exp', icon: Touchpad },
    {
      id: 'magic-trackpad',
      label: m.shellNavMagicTrackpad(),
      badge: 'Exp',
      badgeKind: 'exp',
      icon: Hand,
    },
    {
      id: 'magic-mouse',
      label: m.shellNavMagicMouse(),
      badge: 'Exp',
      badgeKind: 'exp',
      icon: MousePointerClick,
    },
  ]

  const deviceItems: Array<{
    id: PanelId
    label: string
    badge?: string
    badgeKind?: 'exp' | 'accent'
    icon: typeof Cpu
  }> = [
    { id: 'devices', label: m.shellNavDevices(), badge: 'HID++', badgeKind: 'accent', icon: Cpu },
    { id: 'settings', label: m.shellNavSettings(), icon: Settings },
  ]

  const allItems = [...inputItems, ...deviceItems]
  const currentLabel = allItems.find((item) => item.id === active)?.label ?? m.shellNavKeyboard()

  const panelSrc = `/screenshots/panel-${active}-${suffix}.webp`
  const fullSrc =
    active === 'devices'
      ? `/screenshots/devices-inventory-${suffix}.webp`
      : `/screenshots/${active}-${suffix}.webp`

  return (
    <>
      <section className="hero-rebind-shell" aria-label={m.shellAriaLabel()}>
        <aside className="hr-sidebar">
          <div className="hr-traffic" aria-hidden="true">
            <span className="hr-dot hr-dot-red" />
            <span className="hr-dot hr-dot-yellow" />
            <span className="hr-dot hr-dot-green" />
          </div>

          <div className="hr-brand">
            <img src="/app-icon.png" alt="" width={26} height={26} />
            <div>
              <div className="hr-brand-title">Rebind</div>
              <div className="hr-brand-sub">{m.shellProfileStatus()}</div>
            </div>
          </div>

          <div className="hr-nav-group" role="tablist" aria-label={m.shellSectionsLabel()}>
            {inputItems.map((item) => {
              const Icon = item.icon
              const isSelected = active === item.id
              return (
                <button
                  key={item.id}
                  type="button"
                  role="tab"
                  aria-selected={isSelected}
                  className={`hr-nav-item ${isSelected ? 'is-active' : ''}`}
                  onClick={() => setActive(item.id)}
                >
                  <span className="hr-nav-ico">
                    <Icon size={15} aria-hidden="true" />
                  </span>
                  <span className="hr-nav-label">{item.label}</span>
                  {item.badge ? (
                    <span
                      className={`hr-nav-badge ${item.badgeKind === 'exp' ? 'is-exp' : item.badgeKind === 'accent' ? 'is-accent' : ''}`}
                    >
                      {item.badge}
                    </span>
                  ) : null}
                </button>
              )
            })}
          </div>

          <div className="hr-nav-divider" />

          <div className="hr-nav-group">
            {deviceItems.map((item) => {
              const Icon = item.icon
              const isSelected = active === item.id
              return (
                <button
                  key={item.id}
                  type="button"
                  className={`hr-nav-item ${isSelected ? 'is-active' : ''}`}
                  onClick={() => setActive(item.id)}
                >
                  <span className="hr-nav-ico">
                    <Icon size={15} aria-hidden="true" />
                  </span>
                  <span className="hr-nav-label">{item.label}</span>
                  {item.badge ? <span className="hr-nav-badge is-accent">{item.badge}</span> : null}
                </button>
              )
            })}
          </div>

          <div className="hr-sidebar-footer">
            <div className="hr-status-row">
              <span className="hr-status-left">
                <span className="hr-status-dot" />
                <span>{m.shellEngineActive()}</span>
              </span>
              <button
                type="button"
                className="hr-icon-btn"
                onClick={() => setLightboxOpen(true)}
                aria-label={m.zoomLabel()}
                title={m.zoomLabel()}
              >
                <Maximize2 size={13} aria-hidden="true" />
              </button>
            </div>
          </div>
        </aside>

        <div className="hr-stage">
          <img
            src={panelSrc}
            alt={`Rebind — ${currentLabel}`}
            width={1664}
            height={1440}
            className="hr-stage-img"
            decoding="async"
          />
        </div>
      </section>

      <div className="hero-mobile-screen">
        <div className="hero-mobile-screen-frame">
          <img
            src={`/screenshots/keyboard-${suffix}.webp`}
            alt={m.heroScreenAlt()}
            width={2160}
            height={1440}
            decoding="async"
          />
        </div>
      </div>

      <Dialog open={lightboxOpen} onOpenChange={(details) => setLightboxOpen(details.open)}>
        <DialogBackdrop />
        <DialogPositioner>
          <DialogContent className="lightbox-content">
            <div className="lightbox-header">
              <DialogTitle>
                {m.lightboxPrefix()} · {currentLabel}
              </DialogTitle>
              <DialogCloseIcon />
            </div>
            <div className="lightbox-body">
              <img
                src={fullSrc}
                alt={`Rebind — ${currentLabel}`}
                width={2160}
                height={1440}
                className="lightbox-img"
              />
            </div>
          </DialogContent>
        </DialogPositioner>
      </Dialog>
    </>
  )
}
