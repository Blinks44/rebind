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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@moduix/react/tabs'
import {
  Check,
  Cpu,
  FlaskConical,
  Hand,
  Keyboard,
  Layers,
  Maximize2,
  Mouse,
  Shield,
} from 'lucide-react'
import { useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ColorScheme } from '@/lib/theme'

interface FeatureShowcaseProps {
  theme: ColorScheme
}

type TimingMode = 'press' | 'double' | 'hold'
type GestureDir = 'up' | 'left' | 'right' | 'down'
type WheelMode = 'smartshift' | 'ratchet' | 'freespin'
type LightboxSize = 'full' | 'medium' | 'narrow'

export function FeatureShowcase({ theme }: FeatureShowcaseProps) {
  const [timing, setTiming] = useState<TimingMode>('hold')
  const [gestureDir, setGestureDir] = useState<GestureDir>('up')
  const [wheelMode, setWheelMode] = useState<WheelMode>('smartshift')
  const [dpi, setDpi] = useState(1600)

  const [lightboxOpen, setLightboxOpen] = useState(false)
  const [lightboxShot, setLightboxShot] = useState<{
    title: string
    src: string
    w: number
    h: number
    size: LightboxSize
  }>({
    title: '',
    src: `/screenshots/editor-app-${theme}.webp`,
    w: 2160,
    h: 1440,
    size: 'full',
  })

  const suffix = theme === 'dark' ? 'dark' : 'light'

  const openShot = (
    title: string,
    src: string,
    w: number,
    h: number,
    size: LightboxSize = 'full',
  ) => {
    setLightboxShot({ title, src, w, h, size })
    setLightboxOpen(true)
  }

  const timingExamples: Record<TimingMode, { trigger: string; action: string; note: string }> = {
    press: {
      trigger: 'F6',
      action: m.demoTimingPressAction(),
      note: m.demoTimingPressNote(),
    },
    double: {
      trigger: '2× ⌥ Space',
      action: m.demoTimingDoubleAction(),
      note: m.demoTimingDoubleNote(),
    },
    hold: {
      trigger: 'Hold F13 (320 ms)',
      action: m.demoTimingHoldAction(),
      note: m.demoTimingHoldNote(),
    },
  }

  const gestureExamples: Record<GestureDir, { key: string; arrow: string; action: string }> = {
    up: { key: 'Side 4 + ↑', arrow: '↑', action: m.demoGestureUp() },
    left: { key: 'Side 4 + ←', arrow: '←', action: m.demoGestureLeft() },
    right: { key: 'Side 4 + →', arrow: '→', action: m.demoGestureRight() },
    down: { key: 'Side 4 + ↓', arrow: '↓', action: m.demoGestureDown() },
  }

  const wheelNotes: Record<WheelMode, string> = {
    smartshift: m.demoWheelSmartShiftNote(),
    ratchet: m.demoWheelRatchetNote(),
    freespin: m.demoWheelFreeSpinNote(),
  }

  const tabs: Array<{
    id: string
    label: string
    icon: typeof Keyboard
    experimental?: boolean
    title: string
    body: string
    bullets: string[]
    previewSrc: string
    previewW: number
    previewH: number
    fullSrc: string
    fullW: number
    fullH: number
    size: LightboxSize
  }> = [
    {
      id: 'keyboard',
      label: m.tabKeyboard(),
      icon: Keyboard,
      title: m.featKeyboardTitle(),
      body: m.featKeyboardBody(),
      bullets: [m.featKeyboardB1(), m.featKeyboardB2(), m.featKeyboardB3()],
      previewSrc: `/screenshots/panel-editor-app-${suffix}.webp`,
      previewW: 1664,
      previewH: 1440,
      fullSrc: `/screenshots/editor-app-${suffix}.webp`,
      fullW: 2160,
      fullH: 1440,
      size: 'full',
    },
    {
      id: 'mouse',
      label: m.tabMouse(),
      icon: Mouse,
      title: m.featMouseTitle(),
      body: m.featMouseBody(),
      bullets: [m.featMouseB1(), m.featMouseB2(), m.featMouseB3()],
      previewSrc: `/screenshots/panel-editor-gesture-${suffix}.webp`,
      previewW: 1664,
      previewH: 1440,
      fullSrc: `/screenshots/editor-gesture-${suffix}.webp`,
      fullW: 2160,
      fullH: 1440,
      size: 'full',
    },
    {
      id: 'logitech',
      label: m.tabLogitech(),
      icon: Cpu,
      title: m.featLogitechTitle(),
      body: m.featLogitechBody(),
      bullets: [m.featLogitechB1(), m.featLogitechB2(), m.featLogitechB3()],
      previewSrc: `/screenshots/devices-logitech-${suffix}.webp`,
      previewW: 1664,
      previewH: 1320,
      fullSrc: `/screenshots/devices-logitech-${suffix}.webp`,
      fullW: 1664,
      fullH: 1320,
      size: 'medium',
    },
    {
      id: 'touch',
      label: m.tabTouch(),
      icon: Hand,
      experimental: true,
      title: m.featTouchTitle(),
      body: m.featTouchBody(),
      bullets: [m.featTouchB1(), m.featTouchB2(), m.featTouchB3()],
      previewSrc: `/screenshots/panel-magic-mouse-${suffix}.webp`,
      previewW: 1664,
      previewH: 1440,
      fullSrc: `/screenshots/magic-mouse-${suffix}.webp`,
      fullW: 2160,
      fullH: 1440,
      size: 'full',
    },
    {
      id: 'profiles',
      label: m.tabProfiles(),
      icon: Layers,
      title: m.featProfilesTitle(),
      body: m.featProfilesBody(),
      bullets: [m.featProfilesB1(), m.featProfilesB2(), m.featProfilesB3()],
      previewSrc: `/screenshots/starter-setups-${suffix}.webp`,
      previewW: 1360,
      previewH: 1200,
      fullSrc: `/screenshots/starter-setups-${suffix}.webp`,
      fullW: 1360,
      fullH: 1200,
      size: 'narrow',
    },
    {
      id: 'safety',
      label: m.tabSafety(),
      icon: Shield,
      title: m.featSafetyTitle(),
      body: m.featSafetyBody(),
      bullets: [m.featSafetyB1(), m.featSafetyB2(), m.featSafetyB3()],
      previewSrc: `/screenshots/panel-settings-${suffix}.webp`,
      previewW: 1664,
      previewH: 1440,
      fullSrc: `/screenshots/settings-${suffix}.webp`,
      fullW: 2160,
      fullH: 1440,
      size: 'full',
    },
  ]

  const contentClass =
    lightboxShot.size === 'medium'
      ? 'lightbox-content lightbox-content-medium'
      : lightboxShot.size === 'narrow'
        ? 'lightbox-content lightbox-content-narrow'
        : 'lightbox-content'

  return (
    <section id="features" className="section">
      <div className="container">
        <div className="section-head" data-reveal>
          <div className="eyebrow">{m.featuresEyebrow()}</div>
          <h2 className="section-title">{m.featuresTitle()}</h2>
          <p className="section-subtitle">{m.featuresSubtitle()}</p>
        </div>

        <Tabs defaultValue="keyboard">
          <TabsList className="showcase-tabs-list">
            {tabs.map((tab) => {
              const Icon = tab.icon
              return (
                <TabsTrigger key={tab.id} value={tab.id} className="showcase-tab-trigger">
                  <Icon size={15} aria-hidden="true" />
                  <span>{tab.label}</span>
                </TabsTrigger>
              )
            })}
          </TabsList>

          {tabs.map((tab) => (
            <TabsContent key={tab.id} value={tab.id}>
              <div className="showcase-panel">
                <div className="showcase-copy">
                  {tab.experimental ? (
                    <div className="showcase-exp-badge">
                      <FlaskConical size={12} aria-hidden="true" />
                      <span>{m.experimentalBadge()}</span>
                    </div>
                  ) : null}
                  <h3>{tab.title}</h3>
                  <p>{tab.body}</p>
                  <ul className="showcase-bullets">
                    {tab.bullets.map((bullet) => (
                      <li key={bullet}>
                        <Check size={16} aria-hidden="true" />
                        <span>{bullet}</span>
                      </li>
                    ))}
                  </ul>

                  {tab.id === 'keyboard' ? (
                    <div className="interactive-demo">
                      <div className="interactive-demo-label">{m.demoTimingLabel()}</div>
                      <div className="demo-pills">
                        {(['press', 'double', 'hold'] as const).map((mode) => (
                          <button
                            key={mode}
                            type="button"
                            className={`demo-pill-btn ${timing === mode ? 'is-active' : ''}`}
                            onClick={() => setTiming(mode)}
                          >
                            {mode === 'press'
                              ? m.demoTimingPress()
                              : mode === 'double'
                                ? m.demoTimingDouble()
                                : m.demoTimingHold()}
                          </button>
                        ))}
                      </div>
                      <div className="demo-mapping-row">
                        <span className="rb-keycap">{timingExamples[timing].trigger}</span>
                        <span className="demo-arrow" aria-hidden="true">
                          →
                        </span>
                        <span className="rb-keycap is-accent">{timingExamples[timing].action}</span>
                      </div>
                      <p className="demo-note">{timingExamples[timing].note}</p>
                    </div>
                  ) : null}

                  {tab.id === 'mouse' ? (
                    <div className="interactive-demo">
                      <div className="interactive-demo-label">{m.demoGestureLabel()}</div>
                      <div className="demo-pills">
                        {(['up', 'left', 'right', 'down'] as const).map((dir) => (
                          <button
                            key={dir}
                            type="button"
                            className={`demo-pill-btn ${gestureDir === dir ? 'is-active' : ''}`}
                            onClick={() => setGestureDir(dir)}
                          >
                            {gestureExamples[dir].arrow} {gestureExamples[dir].action}
                          </button>
                        ))}
                      </div>
                      <div className="demo-mapping-row">
                        <span className="rb-keycap">{gestureExamples[gestureDir].key}</span>
                        <span className="demo-arrow" aria-hidden="true">
                          →
                        </span>
                        <span className="rb-keycap is-accent">
                          {gestureExamples[gestureDir].action}
                        </span>
                      </div>
                    </div>
                  ) : null}

                  {tab.id === 'logitech' ? (
                    <div className="interactive-demo">
                      <div className="interactive-demo-label">{m.demoLogitechLabel()}</div>
                      <div className="demo-pills">
                        {(['smartshift', 'ratchet', 'freespin'] as const).map((mode) => (
                          <button
                            key={mode}
                            type="button"
                            className={`demo-pill-btn ${wheelMode === mode ? 'is-active' : ''}`}
                            onClick={() => setWheelMode(mode)}
                          >
                            {mode === 'smartshift'
                              ? 'SmartShift'
                              : mode === 'ratchet'
                                ? m.demoWheelRatchet()
                                : m.demoWheelFreeSpin()}
                          </button>
                        ))}
                      </div>
                      <div className="demo-slider-row">
                        <span className="rb-keycap">{dpi} DPI</span>
                        <input
                          type="range"
                          min={400}
                          max={4000}
                          step={200}
                          value={dpi}
                          aria-label={m.demoDpiAria()}
                          onChange={(e) => setDpi(Number(e.target.value))}
                        />
                      </div>
                      <p className="demo-note">{wheelNotes[wheelMode]}</p>
                    </div>
                  ) : null}
                </div>

                <button
                  type="button"
                  className="showcase-shot-btn"
                  onClick={() => openShot(tab.title, tab.fullSrc, tab.fullW, tab.fullH, tab.size)}
                  aria-label={`${m.zoomLabel()}: ${tab.title}`}
                >
                  <img
                    src={tab.previewSrc}
                    alt={tab.title}
                    width={tab.previewW}
                    height={tab.previewH}
                    loading="lazy"
                    decoding="async"
                  />
                  <span className="shot-zoom-chip">
                    <Maximize2 size={12} aria-hidden="true" />
                    <span>{m.zoomLabel()}</span>
                  </span>
                </button>
              </div>
            </TabsContent>
          ))}
        </Tabs>
      </div>

      <Dialog open={lightboxOpen} onOpenChange={(details) => setLightboxOpen(details.open)}>
        <DialogBackdrop />
        <DialogPositioner>
          <DialogContent className={contentClass}>
            <DialogHeader className="lightbox-header">
              <DialogTitle>
                {m.lightboxPrefix()} · {lightboxShot.title}
              </DialogTitle>
              <DialogCloseIcon />
            </DialogHeader>
            <DialogBody className="lightbox-body">
              <img
                src={lightboxShot.src}
                alt={lightboxShot.title}
                width={lightboxShot.w}
                height={lightboxShot.h}
                className="lightbox-img"
              />
            </DialogBody>
          </DialogContent>
        </DialogPositioner>
      </Dialog>
    </section>
  )
}
