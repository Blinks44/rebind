import { SimpleGrid } from '@moduix/react/simple-grid'
import { ArrowDownUp, BatteryFull, BatteryMedium, Keyboard, type LucideIcon, Mouse, SlidersHorizontal, Waves } from 'lucide-react'
import { FeatureCard, Section, SectionHeading } from '~/components'
import { m } from '~/paraglide/messages.js'
import { getLocale } from '~/paraglide/runtime.js'
import styles from './Devices.module.css'

/** What Rebind does for the mice themselves, outside of bindings. */
export function Devices() {
  return (
    <Section id="devices">
      <SectionHeading title={m.devices_title()} lead={m.devices_lead()} />
      <SimpleGrid minChildWidth="22rem" gap="16px">
        <FeatureCard className={styles.cell} icon={Waves} title={m.devices_smooth_title()} text={m.devices_smooth_text()} />
        <FeatureCard className={styles.cell} icon={ArrowDownUp} title={m.devices_wheel_title()} text={m.devices_wheel_text()} />
        <FeatureCard className={styles.cell} icon={SlidersHorizontal} title={m.devices_logitech_title()} text={m.devices_logitech_text()} />
        <FeatureCard className={styles.cell} icon={BatteryMedium} title={m.devices_battery_title()} text={m.devices_battery_text()}>
          <ul className={styles.battery}>
            <BatteryRow icon={Mouse} name={m.app_mouse()} level={0.82} />
            <BatteryRow icon={Keyboard} name={m.app_keyboard()} level={0.54} />
          </ul>
        </FeatureCard>
      </SimpleGrid>
    </Section>
  )
}

/** A row of the battery menu: device symbol, name, charge and battery symbol. */
function BatteryRow({ icon: Icon, name, level }: { icon: LucideIcon; name: string; level: number }) {
  const percent = new Intl.NumberFormat(getLocale(), { style: 'percent' }).format(level)
  return (
    <li className={styles.row}>
      <Icon size={16} aria-hidden />
      <span className={styles.name}>{name}</span>
      <span className={styles.level}>{percent}</span>
      {level > 0.6 ? <BatteryFull size={18} aria-hidden /> : <BatteryMedium size={18} aria-hidden />}
    </li>
  )
}
