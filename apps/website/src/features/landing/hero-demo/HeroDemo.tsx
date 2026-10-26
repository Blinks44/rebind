import { Button } from '@moduix/react/button'
import { Card } from '@moduix/react/card'
import {
  Carousel,
  CarouselAutoplayTrigger,
  CarouselContext,
  CarouselControl,
  CarouselIndicator,
  CarouselIndicatorGroup,
  CarouselItem,
  CarouselItemGroup,
  CarouselNextTrigger,
  CarouselPrevTrigger,
} from '@moduix/react/carousel'
import {
  ArrowLeft,
  PanelsTopLeft,
  Pause,
  Play,
  SquareArrowRight,
  SquareX,
  type LucideIcon,
} from 'lucide-react'
import { useEffect, useState } from 'react'
import { Keycap } from '@/components/keycap'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './HeroDemo.module.css'

type DemoExample = {
  keys: string[]
  title: string
  category: string
  icon: LucideIcon
}

function DemoMapping({
  example,
  pressed,
  announce = false,
}: {
  example: DemoExample
  pressed?: string | null
  announce?: boolean
}) {
  const ActionIcon = example.icon
  return (
    <div className={styles.mapping}>
      <div className={styles.trigger}>
        <p className={styles.caption}>{m.whenPress()}</p>
        <div className={styles.keys}>
          {(pressed ? [pressed] : example.keys).map((key, index) => (
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
        <div className={styles.action} aria-live={announce ? 'polite' : 'off'}>
          <span className={styles.tile}>
            <ActionIcon size={24} aria-hidden="true" />
          </span>
          <div>
            <strong>{example.title}</strong>
            <span>{example.category}</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export function HeroDemo() {
  const [example, setExample] = useState(0)
  const [pressed, setPressed] = useState<string | null>(null)
  const [mobilePage, setMobilePage] = useState(0)
  const [autoplayAllowed, setAutoplayAllowed] = useState(false)
  const examples: DemoExample[] = [
    {
      keys: ['⌃', '⌥', 'J'],
      title: m.nextDesktop(),
      category: m.spaces(),
      icon: SquareArrowRight,
    },
    {
      keys: ['F13'],
      title: m.missionControl(),
      category: m.windows(),
      icon: PanelsTopLeft,
    },
    { keys: ['⌥', 'W'], title: m.closeWindow(), category: m.windows(), icon: SquareX },
    { keys: [m.button4()], title: m.goBack(), category: m.navigation(), icon: ArrowLeft },
  ]
  useEffect(() => {
    const mobile = window.matchMedia('(max-width: 700px)')
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)')
    function updateAutoplay() {
      setAutoplayAllowed(mobile.matches && !reduceMotion.matches)
    }
    updateAutoplay()
    mobile.addEventListener('change', updateAutoplay)
    reduceMotion.addEventListener('change', updateAutoplay)
    return () => {
      mobile.removeEventListener('change', updateAutoplay)
      reduceMotion.removeEventListener('change', updateAutoplay)
    }
  }, [])
  useEffect(() => {
    function showKey(event: KeyboardEvent) {
      const target = event.target
      if (
        !window.matchMedia('(min-width: 701px) and (hover: hover) and (pointer: fine)').matches ||
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
  function select(value: number) {
    setExample(value)
    setPressed(null)
  }
  return (
    <Card className={styles.demo} aria-label={m.demoLabel()}>
      <div className={styles.desktop}>
        <DemoMapping example={examples[example]!} pressed={pressed} announce />
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
      </div>
      <Carousel
        className={styles.mobileCarousel}
        slideCount={examples.length}
        loop
        autoplay={autoplayAllowed ? { delay: 4000 } : false}
        page={mobilePage}
        onPageChange={({ page }) => setMobilePage(page)}
        aria-label={m.demoLabel()}
        translations={{
          item: (index) => examples[index]!.title,
          indicator: (index) => examples[index]!.title,
          prevTrigger: examples[(mobilePage - 1 + examples.length) % examples.length]!.title,
          nextTrigger: examples[(mobilePage + 1) % examples.length]!.title,
          autoplayStart: m.playDemo(),
          autoplayStop: m.pauseDemo(),
        }}
      >
        <CarouselItemGroup className={styles.slides}>
          {examples.map((item, index) => (
            <CarouselItem key={item.title} index={index} className={styles.slide}>
              <DemoMapping example={item} />
            </CarouselItem>
          ))}
        </CarouselItemGroup>
        <CarouselControl className={styles.mobileControls}>
          <CarouselPrevTrigger />
          <CarouselIndicatorGroup>
            {examples.map((item, index) => (
              <CarouselIndicator key={item.title} index={index} className={styles.indicator} />
            ))}
          </CarouselIndicatorGroup>
          <CarouselNextTrigger />
          <CarouselContext>
            {(api) => (
              <CarouselAutoplayTrigger disabled={!autoplayAllowed}>
                {api.isPlaying ? (
                  <Pause size={16} aria-hidden="true" />
                ) : (
                  <Play size={16} aria-hidden="true" />
                )}
              </CarouselAutoplayTrigger>
            )}
          </CarouselContext>
        </CarouselControl>
      </Carousel>
    </Card>
  )
}
