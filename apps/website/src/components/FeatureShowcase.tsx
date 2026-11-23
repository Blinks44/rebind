import {
  Dialog,
  DialogBackdrop,
  DialogCloseIcon,
  DialogContent,
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
    narrow?: boolean
  }>({
    title: '',
    src: `/screenshots/keyboard-${theme}.webp`,
    w: 2160,
    h: 1440,
  })

  const suffix = theme === 'dark' ? 'dark' : 'light'

  const openShot = (title: string, src: string, w: number, h: number, narrow = false) => {
    setLightboxShot({ title, src, w, h, narrow })
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

  const tabs = [
    {
      id: 'keyboard',
      label: m.tabKeyboard(),
      icon: Keyboard,
      title: m.featKeyboardTitle(),
      body: m.featKeyboardBody(),
      bullets: [m.featKeyboardB1(), m.featKeyboardB2(), m.featKeyboardB3()],
      shot: `/screenshots/editor-app-${suffix}.webp`,
      shotAlt: m.featKeyboardTitle(),
      w: 2160,
      h: 1440,
    },
    {
      id: 'mouse',
      label: m.tabMouse(),
      icon: Mouse,
      title: m.featMouseTitle(),
      body: m.featMouseBody(),
      bullets: [m.featMouseB1(), m.featMouseB2(), m.featMouseB3()],
      shot: `/screenshots/editor-gesture-${suffix}.webp`,
      shotAlt: m.featMouseTitle(),
      w: 2160,
      h: 1440,
    },
    {
      id: 'logitech',
      label: m.tabLogitech(),
      icon: Cpu,
      title: m.featLogitechTitle(),
      body: m.featLogitechBody(),
      bullets: [m.featLogitechB1(), m.featLogitechB2(), m.featLogitechB3()],
      shot: `/screenshots/devices-logitech-${suffix}.webp`,
      shotAlt: m.featLogitechTitle(),
      w: 1664,
      h: 1320,
    },
    {
      id: 'touch',
      label: m.tabTouch(),
      icon: Hand,
      experimental: true,
      title: m.featTouchTitle(),
      body: m.featTouchBody(),
      bullets: [m.featTouchB1(), m.featTouchB2(), m.featTouchB3()],
      shot: `/screenshots/magic-mouse-${suffix}.webp`,
      shotAlt: m.featTouchTitle(),
      w: 2160,
      h: 1440,
    },
    {
      id: 'profiles',
      label: m.tabProfiles(),
      icon: Layers,
      title: m.featProfilesTitle(),
      body: m.featProfilesBody(),
      bullets: [m.featProfilesB1(), m.featProfilesB2(), m.featProfilesB3()],
      shot: `/screenshots/starter-setups-${suffix}.webp`,
      shotAlt: m.featProfilesTitle(),
      w: 1360,
      h: 1200,
      narrow: true,
    },
    {
      id: 'safety',
      label: m.tabSafety(),
      icon: Shield,
      title: m.featSafetyTitle(),
      body: m.featSafetyBody(),
      bullets: [m.featSafetyB1(), m.featSafetyB2(), m.featSafetyB3()],
      shot: `/screenshots/settings-${suffix}.webp`,
      shotAlt: m.featSafetyTitle(),
      w: 2160,
      h: 1440,
    },
  ]

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
                      <FlaskConical size={13} aria-hidden="true" />
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
                  onClick={() => openShot(tab.title, tab.shot, tab.w, tab.h, tab.narrow)}
                  aria-label={`${m.zoomLabel()}: ${tab.title}`}
                >
                  <img
                    src={tab.shot}
                    alt={tab.shotAlt}
                    width={tab.w}
                    height={tab.h}
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
          <DialogContent className="lightbox-content">
            <div className="lightbox-header">
              <DialogTitle>
                {m.lightboxPrefix()} · {lightboxShot.title}
              </DialogTitle>
              <DialogCloseIcon />
            </div>
            <div className="lightbox-body">
              <img
                src={lightboxShot.src}
                alt={lightboxShot.title}
                width={lightboxShot.w}
                height={lightboxShot.h}
                className={`lightbox-img ${lightboxShot.narrow ? 'is-narrow' : ''}`}
              />
            </div>
          </DialogContent>
        </DialogPositioner>
      </Dialog>
    </section>
  )
}
