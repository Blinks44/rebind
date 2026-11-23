import {
  Dialog,
  DialogBackdrop,
  DialogBody,
  DialogCloseIcon,
  DialogContent,
  DialogHeader,
  DialogPositioner,
  DialogTitle,
} from '@moduix/react/dialog'
import {
  Cable,
  Hand,
  Info,
  Keyboard,
  Maximize2,
  Mouse,
  Pointer,
  Settings,
  Touchpad,
} from 'lucide-react'
import { useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ColorScheme } from '@/lib/theme'

type ScreenId =
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
  const [active, setActive] = useState<ScreenId>('mouse')
  const [lightboxMode, setLightboxMode] = useState<'screen' | 'about'>('screen')
  const [lightboxOpen, setLightboxOpen] = useState(false)

  const inputItems: Array<{
    id: ScreenId
    label: string
    icon: typeof Keyboard
  }> = [
    { id: 'keyboard', label: m.shellNavKeyboard(), icon: Keyboard },
    { id: 'mouse', label: m.shellNavMouse(), icon: Mouse },
    { id: 'trackpad', label: m.shellNavTrackpad(), icon: Touchpad },
    { id: 'magic-trackpad', label: m.shellNavMagicTrackpad(), icon: Hand },
    { id: 'magic-mouse', label: m.shellNavMagicMouse(), icon: Pointer },
  ]

  const suffix = theme === 'dark' ? 'dark' : 'light'
  const panelSrc = `/screenshots/panel-${active}-${suffix}.webp`
  const fullSrc = `/screenshots/${active}-${suffix}.webp`
  const aboutSrc = `/screenshots/about-${suffix}.webp`

  const allLabels: Record<ScreenId, string> = {
    keyboard: m.shellNavKeyboard(),
    mouse: m.shellNavMouse(),
    trackpad: m.shellNavTrackpad(),
    'magic-trackpad': m.shellNavMagicTrackpad(),
    'magic-mouse': m.shellNavMagicMouse(),
    devices: m.shellNavDevices(),
    settings: m.shellNavSettings(),
  }
  const currentLabel = allLabels[active]

  return (
    <>
      <section className="hero-rebind-shell" aria-label={m.shellAriaLabel()}>
        <div className="hr-shell-inner">
          <div className="hr-sidebar-col">
            <aside className="hr-sidebar" aria-label={m.shellSectionsLabel()}>
              <div className="hr-traffic" aria-hidden="true">
                <span className="hr-dot hr-dot-red" />
                <span className="hr-dot hr-dot-yellow" />
                <span className="hr-dot hr-dot-green" />
              </div>

              <div className="hr-brand">
                <img src="/app-icon.png" alt="Rebind" width={32} height={32} />
                <span className="hr-brand-title">Rebind</span>
              </div>

              <div className="hr-nav-group">
                {inputItems.map((item) => {
                  const Icon = item.icon
                  const isSelected = active === item.id
                  return (
                    <button
                      key={item.id}
                      type="button"
                      className={`hr-nav-item ${isSelected ? 'is-active' : ''}`}
                      aria-current={isSelected ? 'page' : undefined}
                      onClick={() => setActive(item.id)}
                    >
                      <span className="hr-nav-ico">
                        <Icon size={16} strokeWidth={1.85} aria-hidden="true" />
                      </span>
                      <span className="hr-nav-label">{item.label}</span>
                    </button>
                  )
                })}
              </div>

              <div className="hr-nav-divider" />

              <div className="hr-nav-group">
                <button
                  type="button"
                  className={`hr-nav-item ${active === 'devices' ? 'is-active' : ''}`}
                  aria-current={active === 'devices' ? 'page' : undefined}
                  onClick={() => setActive('devices')}
                >
                  <span className="hr-nav-ico">
                    <Cable size={16} strokeWidth={1.85} aria-hidden="true" />
                  </span>
                  <span className="hr-nav-label">{m.shellNavDevices()}</span>
                </button>
              </div>

              <div className="hr-sidebar-footer">
                <div className="hr-nav-group">
                  <button
                    type="button"
                    className={`hr-nav-item ${active === 'settings' ? 'is-active' : ''}`}
                    aria-current={active === 'settings' ? 'page' : undefined}
                    onClick={() => setActive('settings')}
                  >
                    <span className="hr-nav-ico">
                      <Settings size={16} strokeWidth={1.85} aria-hidden="true" />
                    </span>
                    <span className="hr-nav-label">{m.shellNavSettings()}</span>
                  </button>

                  <button
                    type="button"
                    className="hr-nav-item"
                    onClick={() => {
                      setLightboxMode('about')
                      setLightboxOpen(true)
                    }}
                  >
                    <span className="hr-nav-ico">
                      <Info size={16} strokeWidth={1.85} aria-hidden="true" />
                    </span>
                    <span className="hr-nav-label">{m.shellNavAbout()}</span>
                  </button>
                </div>
              </div>
            </aside>
          </div>

          <div className="hr-stage">
            <img
              src={panelSrc}
              alt={`Rebind: ${currentLabel}`}
              width={1664}
              height={1440}
              className="hr-stage-img"
              decoding="sync"
            />
            <button
              type="button"
              className="hr-stage-zoom"
              onClick={() => {
                setLightboxMode('screen')
                setLightboxOpen(true)
              }}
              aria-label={`${m.zoomLabel()}: ${currentLabel}`}
            >
              <Maximize2 size={12} aria-hidden="true" />
              <span>{m.zoomLabel()}</span>
            </button>
          </div>
        </div>
      </section>

      <div className="hero-mobile-screen">
        <div className="hero-mobile-screen-frame">
          <img
            src={`/screenshots/mouse-${suffix}.webp`}
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
          <DialogContent
            className={`lightbox-content ${lightboxMode === 'about' ? 'lightbox-content-about' : ''}`}
          >
            <DialogHeader className="lightbox-header">
              <DialogTitle>
                {m.lightboxPrefix()} · {lightboxMode === 'about' ? m.shellNavAbout() : currentLabel}
              </DialogTitle>
              <DialogCloseIcon />
            </DialogHeader>
            <DialogBody
              className={`lightbox-body ${lightboxMode === 'about' ? 'lightbox-body-about' : ''}`}
            >
              {lightboxMode === 'about' ? (
                <img
                  src={aboutSrc}
                  alt={`Rebind: ${m.shellNavAbout()}`}
                  width={880}
                  height={896}
                  className="lightbox-img lightbox-img-about"
                />
              ) : (
                <img
                  src={fullSrc}
                  alt={`Rebind: ${currentLabel}`}
                  width={2160}
                  height={1440}
                  className="lightbox-img"
                />
              )}
            </DialogBody>
          </DialogContent>
        </DialogPositioner>
      </Dialog>
    </>
  )
}
