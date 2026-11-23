import {
  Dialog,
  DialogBackdrop,
  DialogCloseIcon,
  DialogContent,
  DialogPositioner,
  DialogTitle,
} from '@moduix/react/dialog'
import { Maximize2 } from 'lucide-react'
import { useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ColorScheme } from '@/lib/theme'

interface BentoGridProps {
  theme: ColorScheme
}

export function BentoGrid({ theme }: BentoGridProps) {
  const suffix = theme === 'dark' ? 'dark' : 'light'
  const [lightboxOpen, setLightboxOpen] = useState(false)
  const [activeCard, setActiveCard] = useState<{
    title: string
    src: string
    w: number
    h: number
    narrow?: boolean
  }>({
    title: '',
    src: `/screenshots/keyboard-${suffix}.webp`,
    w: 2160,
    h: 1440,
  })

  const cards = [
    {
      id: 'keyboard',
      title: m.bentoKeyboardTitle(),
      sub: m.bentoKeyboardSub(),
      src: `/screenshots/keyboard-${suffix}.webp`,
      w: 2160,
      h: 1440,
    },
    {
      id: 'mouse',
      title: m.bentoMouseTitle(),
      sub: m.bentoMouseSub(),
      src: `/screenshots/mouse-${suffix}.webp`,
      w: 2160,
      h: 1440,
    },
    {
      id: 'devices',
      title: m.bentoDevicesTitle(),
      sub: m.bentoDevicesSub(),
      src: `/screenshots/devices-${suffix}.webp`,
      w: 2160,
      h: 1440,
    },
    {
      id: 'trackpad',
      title: m.bentoTrackpadTitle(),
      sub: m.bentoTrackpadSub(),
      src: `/screenshots/trackpad-${suffix}.webp`,
      w: 2160,
      h: 1440,
    },
    {
      id: 'magic-mouse',
      title: m.bentoMagicMouseTitle(),
      sub: m.bentoMagicMouseSub(),
      src: `/screenshots/magic-mouse-${suffix}.webp`,
      w: 2160,
      h: 1440,
    },
    {
      id: 'starter-setups',
      title: m.bentoStartersTitle(),
      sub: m.bentoStartersSub(),
      src: `/screenshots/starter-setups-${suffix}.webp`,
      w: 1360,
      h: 1200,
      narrow: true,
    },
  ]

  return (
    <section id="screens" className="section">
      <div className="container">
        <div className="section-head" data-reveal>
          <div className="eyebrow">{m.bentoEyebrow()}</div>
          <h2 className="section-title">{m.bentoTitle()}</h2>
          <p className="section-subtitle">{m.bentoSubtitle()}</p>
        </div>

        <div className="bento-grid">
          {cards.map((card) => (
            <button
              key={card.id}
              type="button"
              className="bento-card"
              onClick={() => {
                setActiveCard({
                  title: card.title,
                  src: card.src,
                  w: card.w,
                  h: card.h,
                  narrow: card.narrow,
                })
                setLightboxOpen(true)
              }}
            >
              <div className="bento-card-head">
                <h3 className="bento-card-title">{card.title}</h3>
              </div>
              <p className="bento-card-sub">{card.sub}</p>
              <div className="bento-card-media">
                <img
                  src={card.src}
                  alt={card.title}
                  width={card.w}
                  height={card.h}
                  loading="lazy"
                  decoding="async"
                />
                <span className="shot-zoom-chip">
                  <Maximize2 size={12} aria-hidden="true" />
                  <span>{m.zoomLabel()}</span>
                </span>
              </div>
            </button>
          ))}
        </div>
      </div>

      <Dialog open={lightboxOpen} onOpenChange={(details) => setLightboxOpen(details.open)}>
        <DialogBackdrop />
        <DialogPositioner>
          <DialogContent className="lightbox-content">
            <div className="lightbox-header">
              <DialogTitle>
                {m.lightboxPrefix()} · {activeCard.title}
              </DialogTitle>
              <DialogCloseIcon />
            </div>
            <div className="lightbox-body">
              <img
                src={activeCard.src}
                alt={activeCard.title}
                width={activeCard.w}
                height={activeCard.h}
                className={`lightbox-img ${activeCard.narrow ? 'is-narrow' : ''}`}
              />
            </div>
          </DialogContent>
        </DialogPositioner>
      </Dialog>
    </section>
  )
}
