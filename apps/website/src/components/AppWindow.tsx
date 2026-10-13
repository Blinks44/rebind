import { Switch, SwitchControl, SwitchHiddenInput } from '@moduix/react/switch'
import { ChevronsUpDown, Hand, Info, Keyboard, Layers, Mouse, MousePointer2, Plus, Settings, Touchpad } from 'lucide-react'
import { AnimatePresence, motion } from 'motion/react'
import { type ReactNode, useState } from 'react'
import { actions } from '~/actions'
import { m } from '~/paraglide/messages.js'
import { type Action, Binding, Keycaps, Logo, TriggerChip } from './ui'

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
      { trigger: <TriggerChip icon={MousePointer2}>{m.trigger_two_swipe_left()}</TriggerChip>, action: actions.previousDesktop() },
      { trigger: <TriggerChip icon={MousePointer2}>{m.trigger_two_swipe_right()}</TriggerChip>, action: actions.nextDesktop() },
      { trigger: <TriggerChip icon={MousePointer2}>{m.trigger_two_tap()}</TriggerChip>, action: actions.missionControl() },
    ],
  },
]

/** A working HTML rendition of the main window: the sidebar switches lists and the toggles respond. */
export function AppWindow() {
  const [tabId, setTabId] = useState('keyboard')
  const tab = tabs.find((candidate) => candidate.id === tabId) ?? tabs[0]

  return (
    <section className="window" aria-label={m.app_label()}>
      <aside className="window-sidebar">
        <div className="traffic-lights" aria-hidden>
          <i />
          <i />
          <i />
        </div>
        <div className="window-brand">
          <Logo size={34} />
          Rebind
        </div>
        {tabs.map(({ id, icon: Icon, title }) => (
          <button key={id} type="button" className="sidebar-item" aria-pressed={id === tabId} onClick={() => setTabId(id)}>
            {id === tabId && <motion.span layoutId="sidebar-selection" className="sidebar-selection" />}
            <Icon size={16} aria-hidden /> <span>{title()}</span>
          </button>
        ))}
        <span className="sidebar-item sidebar-item-bottom">
          <Settings size={16} aria-hidden /> {m.app_settings()}
        </span>
        <span className="sidebar-item">
          <Info size={16} aria-hidden /> {m.app_about()}
        </span>
      </aside>
      <div className="window-main">
        <div className="window-header">
          <div>
            <div className="window-title">{tab.title()}</div>
            <div className="window-subtitle">{tab.subtitle()}</div>
          </div>
          <span className="window-add">
            <Plus size={15} aria-hidden /> {m.app_add()}
          </span>
        </div>
        <div className="window-tabs">
          {tabs.map(({ id, title }) => (
            <button key={id} type="button" aria-pressed={id === tabId} onClick={() => setTabId(id)}>
              {title()}
            </button>
          ))}
        </div>
        <div className="window-toolbar">
          <span className="select">
            <Layers size={15} aria-hidden /> {m.app_profile()} <ChevronsUpDown size={13} aria-hidden />
          </span>
          <span className="status-pill">
            <i /> {m.app_status()}
          </span>
        </div>
        <div className="card binding-list">
          <AnimatePresence mode="popLayout" initial={false}>
            {tab.rows().map((row, index) => (
              <motion.div
                key={`${tab.id}-${index}`}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.25, delay: index * 0.04 }}
              >
                <BindingRow row={row} />
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      </div>
    </section>
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
        <Switch className="binding-switch" checked={enabled} onCheckedChange={({ checked }) => setEnabled(checked)} aria-label={m.app_enabled()}>
          <SwitchControl />
          <SwitchHiddenInput />
        </Switch>
      }
    />
  )
}
