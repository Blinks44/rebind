import {
  AppWindow,
  Command,
  File,
  LayoutGrid,
  Link,
  Maximize,
  Monitor,
  Moon,
  MousePointerClick,
  PanelLeft,
  PanelRight,
  Play,
  SkipForward,
  SquareArrowLeft,
  SquareArrowRight,
  SquareX,
  Terminal,
  Undo2,
  Volume2,
  VolumeX,
  Zap,
  type LucideIcon,
} from 'lucide-react'
import { m } from '~/paraglide/messages.js'

/** An action as the app lists it: icon tile, title and catalog category. */
export type Action = { icon: LucideIcon; title: string; category?: string }

/** The subset of Rebind's action catalog shown on the page; resolved per request so labels follow the locale. */
export const actions = {
  nextDesktop: (): Action => ({ icon: SquareArrowRight, title: m.action_next_desktop(), category: m.category_spaces() }),
  previousDesktop: (): Action => ({ icon: SquareArrowLeft, title: m.action_previous_desktop(), category: m.category_spaces() }),
  missionControl: (): Action => ({ icon: LayoutGrid, title: m.action_mission_control(), category: m.category_windows() }),
  closeWindow: (): Action => ({ icon: SquareX, title: m.action_close_window(), category: m.category_windows() }),
  showDesktop: (): Action => ({ icon: Monitor, title: m.action_show_desktop(), category: m.category_windows() }),
  leftHalf: (): Action => ({ icon: PanelLeft, title: m.action_left_half(), category: m.category_windows() }),
  rightHalf: (): Action => ({ icon: PanelRight, title: m.action_right_half(), category: m.category_windows() }),
  fillScreen: (): Action => ({ icon: Maximize, title: m.action_fill_screen(), category: m.category_windows() }),
  playPause: (): Action => ({ icon: Play, title: m.action_play_pause(), category: m.category_media() }),
  nextTrack: (): Action => ({ icon: SkipForward, title: m.action_next_track(), category: m.category_media() }),
  mute: (): Action => ({ icon: VolumeX, title: m.action_mute(), category: m.category_media() }),
  volumeUp: (): Action => ({ icon: Volume2, title: m.action_volume_up(), category: m.category_media() }),
  openTerminal: (): Action => ({ icon: Terminal, title: m.action_open_terminal(), category: m.category_apps() }),
  openApp: (): Action => ({ icon: AppWindow, title: m.action_open_app(), category: m.category_apps() }),
  openLink: (): Action => ({ icon: Link, title: m.action_open_link(), category: m.category_apps() }),
  openFile: (): Action => ({ icon: File, title: m.action_open_file(), category: m.category_apps() }),
  runShortcut: (): Action => ({ icon: Zap, title: m.action_run_shortcut(), category: m.category_shortcuts() }),
  previousApp: (): Action => ({ icon: Undo2, title: m.action_previous_app(), category: m.category_apps() }),
  mouseClick: (): Action => ({ icon: MousePointerClick, title: m.action_mouse_click() }),
  shortcut: (): Action => ({ icon: Command, title: m.action_shortcut() }),
  sleep: (): Action => ({ icon: Moon, title: m.action_sleep() }),
}
