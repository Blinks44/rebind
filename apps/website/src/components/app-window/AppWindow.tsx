import { Button } from '@moduix/react/button'
import { Switch, SwitchControl, SwitchHiddenInput } from '@moduix/react/switch'
import { Tabs, TabsContent, TabsIndicator, TabsList, TabsTrigger } from '@moduix/react/tabs'
import { useMediaQuery } from '@reactuses/core'
import { ChevronsUpDown, Hand, Info, Keyboard, Layers, Mouse, MousePointer2, Plus, Settings, Touchpad } from 'lucide-react'
import { motion } from 'motion/react'
import { type ReactNode, useState } from 'react'
import { type Action, actions } from '~/lib/actions'
import { m } from '~/paraglide/messages.js'
import { Binding } from '../binding/Binding'
import { BindingList } from '../binding-list/BindingList'
import { Keycaps } from '../keycaps/Keycaps'
import { Logo } from '../logo/Logo'
import { StatusBadge } from '../status-badge/StatusBadge'
import { TriggerChip } from '../trigger-chip/TriggerChip'
import styles from './AppWindow.module.css'

type Row = { trigger: ReactNode; action: Action; off?: boolean }

const tabs = [
  {
    id: 'keyboard',
    icon: Keyboard,
    title: m.app_keyboard,
    subtitle: m.app_keyboard_subtitle,
    rows: (): Row[] => [
      { trigger: <Keycaps keys={['⌃', '⌥', 'J']} />, action: actions.nextDesktop() },
      { trigger: <Keycaps keys={['⌃', '⌥', 'K']} />, action: actions.previousDesktop() },
      { trigger: <Keycaps keys={['F13']} />, action: actions.missionControl() },
      { trigger: <Keycaps keys={['⌥', 'W']} />, action: actions.closeWindow() },
      { trigger: <Keycaps keys={['F14']} />, action: actions.playPause(), off: true },
    ],
  },
  {
    id: 'mouse',
    icon: Mouse,
    title: m.app_mouse,
    subtitle: m.app_mouse_subtitle,
    rows: (): Row[] => [
      { trigger: <TriggerChip icon={Mouse}>{m.trigger_button4()}</TriggerChip>, action: actions.missionControl() },
      { trigger: <TriggerChip icon={Mouse}>{m.trigger_button5()}</TriggerChip>, action: actions.showDesktop() },
      { trigger: <TriggerChip icon={Mouse}>{m.trigger_button4_left()}</TriggerChip>, action: actions.previousDesktop() },
      { trigger: <TriggerChip icon={Mouse}>{m.trigger_button3_double()}</TriggerChip>, action: actions.closeWindow() },
    ],
  },
  {
    id: 'trackpad',
    icon: Touchpad,
    title: m.app_trackpad,
    subtitle: m.app_gestures_subtitle,
    rows: (): Row[] => [
      { trigger: <TriggerChip icon={Touchpad}>{m.trigger_four_tap()}</TriggerChip>, action: actions.missionControl() },
      { trigger: <TriggerChip icon={Touchpad}>{m.trigger_three_double_tap()}</TriggerChip>, action: actions.playPause() },
      { trigger: <TriggerChip icon={Touchpad}>{m.trigger_two_double_tap()}</TriggerChip>, action: actions.closeWindow(), off: true },
    ],
  },
  {
    id: 'magic-trackpad',
    icon: Hand,
    title: m.app_magic_trackpad,
    subtitle: m.app_gestures_subtitle,
    rows: (): Row[] => [
      { trigger: <TriggerChip icon={Hand}>{m.trigger_three_tap()}</TriggerChip>, action: actions.showDesktop() },
      { trigger: <TriggerChip icon={Hand}>{m.trigger_four_tap()}</TriggerChip>, action: actions.missionControl() },
      { trigger: <TriggerChip icon={Hand}>{m.trigger_corner_tap()}</TriggerChip>, action: actions.openTerminal() },
    ],
  },
  {
    id: 'magic-mouse',
    icon: MousePointer2,
    title: m.app_magic_mouse,
    subtitle: m.app_gestures_subtitle,
    rows: (): Row[] => [
      { trigger: <TriggerChip icon={MousePointer2}>{m.trigger_two_scroll_up()}</TriggerChip>, action: actions.volumeUp() },
      { trigger: <TriggerChip icon={MousePointer2}>{m.trigger_three_click()}</TriggerChip>, action: actions.closeWindow() },
      { trigger: <TriggerChip icon={MousePointer2}>{m.trigger_two_tap()}</TriggerChip>, action: actions.missionControl() },
    ],
  },
]

/**
 * A working HTML rendition of the main window. The sidebar is a moduix tab list, so switching lists,
 * the selection indicator and keyboard navigation come from Ark; the toggles respond as well.
 * On narrow screens the list becomes a horizontal row, so the arrow keys and indicator follow it.
 */
export function AppWindow() {
  // The server renders the desktop layout; phones switch right after hydration.
  const narrow = useMediaQuery('(max-width: 860px)', false)
  return (
    <Tabs className={styles.window} orientation={narrow ? 'horizontal' : 'vertical'} defaultValue="keyboard" lazyMount unmountOnExit aria-label={m.app_label()}>
      <aside className={styles.sidebar}>
        <div className={styles.trafficLights} aria-hidden>
          <i />
          <i />
          <i />
        </div>
        <div className={styles.brand}>
          <Logo size={34} />
          Rebind
        </div>
        <TabsList className={styles.tabs}>
          <TabsIndicator />
          {tabs.map(({ id, icon: Icon, title }) => (
            <TabsTrigger key={id} value={id} className={styles.tab}>
              <Icon size={16} aria-hidden /> {title()}
            </TabsTrigger>
          ))}
        </TabsList>
        <div className={styles.sidebarFooter} aria-hidden>
          <span>
            <Settings size={16} /> {m.app_settings()}
          </span>
          <span>
            <Info size={16} /> {m.app_about()}
          </span>
        </div>
      </aside>
      {tabs.map((tab) => (
        <TabsContent key={tab.id} value={tab.id} className={styles.main}>
          <div className={styles.header}>
            <div>
              <div className={styles.title}>{tab.title()}</div>
              <div className={styles.subtitle}>{tab.subtitle()}</div>
            </div>
            <Button asChild size="md" className={styles.add}>
              <span>
                <Plus size={15} aria-hidden /> {m.app_add()}
              </span>
            </Button>
          </div>
          <div className={styles.toolbar}>
            <Button asChild variant="outline" size="md" className={styles.profile}>
              <span>
                <Layers size={15} aria-hidden /> {m.app_profile()} <ChevronsUpDown size={13} aria-hidden />
              </span>
            </Button>
            <StatusBadge>{m.app_status()}</StatusBadge>
          </div>
          <BindingList>
            {tab.rows().map((row, index) => (
              <motion.div key={index} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25, delay: index * 0.04 }}>
                <BindingRow row={row} />
              </motion.div>
            ))}
          </BindingList>
        </TabsContent>
      ))}
    </Tabs>
  )
}

function BindingRow({ row }: { row: Row }) {
  const [enabled, setEnabled] = useState(!row.off)
  return (
    <Binding
      trigger={row.trigger}
      action={row.action}
      dimmed={!enabled}
      trailing={
        <Switch checked={enabled} onCheckedChange={({ checked }) => setEnabled(checked)} aria-label={m.app_enabled()}>
          <SwitchControl />
          <SwitchHiddenInput />
        </Switch>
      }
    />
  )
}
