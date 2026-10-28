import { Tabs, TabsList, TabsIndicator, TabsTrigger, TabsContent } from '@moduix/react/tabs'
import { ProductImage } from '@/components/product-image'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './DevicesSection.module.css'

export function DevicesSection() {
  const devices = [
    ['keyboard', m.keyboard()],
    ['mouse', m.mouse()],
    ['trackpad', m.trackpad()],
    ['magic-trackpad', m.magicTrackpad()],
    ['magic-mouse', m.magicMouse()],
  ] as const
  return (
    <section id="devices" className={styles.section} aria-labelledby="devices-title">
      <p className={styles.eyebrow}>{m.devices()}</p>
      <h2 id="devices-title" className={styles.title}>
        {m.devicesTitle()}
      </h2>
      <p className={styles.lead}>{m.devicesLead()}</p>
      {/* Every panel stays mounted; hidden screenshots preload so switching tabs is instant. */}
      <Tabs defaultValue="keyboard" className={styles.tabs}>
        <div className={styles.scroll}>
          <TabsList aria-label={m.devices()} className={styles.list}>
            {devices.map(([value, label]) => (
              <TabsTrigger key={value} value={value}>
                {label}
              </TabsTrigger>
            ))}
            <TabsIndicator />
          </TabsList>
        </div>
        {devices.map(([value, label]) => (
          <TabsContent key={value} value={value} className={styles.panel}>
            <ProductImage
              view={value}
              alt={m.screenshotAlt({ device: label })}
              preload={value !== 'keyboard'}
            />
          </TabsContent>
        ))}
      </Tabs>
      <p className={styles.note}>{m.experimental()}</p>
    </section>
  )
}
