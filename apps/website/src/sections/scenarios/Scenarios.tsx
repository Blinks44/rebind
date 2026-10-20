import { Card, CardBody, CardDescription, CardHeader, CardTitle } from '@moduix/react/card'
import { SimpleGrid } from '@moduix/react/simple-grid'
import { Command, Mouse, MoveVertical } from 'lucide-react'
import type { ReactNode } from 'react'
import { Binding, Keycaps, Reveal, Section, SectionHeading, TriggerChip } from '~/components'
import { type Action, actions } from '~/lib/actions'
import { m } from '~/paraglide/messages.js'
import styles from './Scenarios.module.css'

export function Scenarios() {
  return (
    <Section id="scenarios">
      <SectionHeading title={m.scenarios_title()} lead={m.scenarios_lead()} />
      <SimpleGrid minChildWidth="22rem" gap="16px">
        <Scenario title={m.scenario_mouse_title()} text={m.scenario_mouse_text()}>
          <Binding trigger={<TriggerChip icon={Mouse}>{m.trigger_button4()}</TriggerChip>} action={actions.missionControl()} />
          <Binding trigger={<TriggerChip icon={Mouse}>{m.trigger_button5()}</TriggerChip>} action={actions.nextDesktop()} />
        </Scenario>
        <Scenario title={m.scenario_presses_title()} text={m.scenario_presses_text()} delay={0.08}>
          <Binding trigger={<Press kind={m.press_single()} />} action={actions.playPause()} />
          <Binding trigger={<Press keyName="F14" kind={m.press_double()} />} action={actions.nextTrack()} />
          <Binding trigger={<Press keyName="F15" kind={m.press_long()} />} action={actions.mute()} />
        </Scenario>
        <Scenario title={m.scenario_windows_title()} text={m.scenario_windows_text()}>
          <Binding trigger={<Keycaps keys={['⌃', '⌥', '←']} />} action={actions.leftHalf()} />
          <Binding trigger={<Keycaps keys={['⌃', '⌥', '→']} />} action={actions.rightHalf()} />
          <Binding trigger={<Keycaps keys={['⌃', '⌥', '↩']} />} action={actions.fillScreen()} />
        </Scenario>
        <Scenario title={m.scenario_launch_title()} text={m.scenario_launch_text()} delay={0.08}>
          <Binding trigger={<Keycaps keys={['⌥', 'T']} />} action={actions.openTerminal()} />
          <Binding trigger={<Keycaps keys={['F16']} />} action={actions.runShortcut()} />
          <Binding trigger={<Keycaps keys={['⌥', 'G']} />} action={actions.openLink()} />
        </Scenario>
        <Scenario title={m.scenario_dual_title()} text={m.scenario_dual_text()}>
          <Binding trigger={<Press kind={m.press_single()} />} action={escape()} />
          <Binding trigger={<Press kind={m.press_long()} />} action={actions.holdControl()} />
        </Scenario>
        <Scenario title={m.scenario_wheel_title()} text={m.scenario_wheel_text()} delay={0.08}>
          <Binding trigger={<TriggerChip icon={MoveVertical}>{m.trigger_button4_wheel_up()}</TriggerChip>} action={actions.volumeUp()} />
          <Binding trigger={<TriggerChip icon={MoveVertical}>{m.trigger_button4_wheel_down()}</TriggerChip>} action={actions.volumeDown()} />
        </Scenario>
      </SimpleGrid>
    </Section>
  )
}

function Scenario(props: { title: string; text: string; delay?: number; children: ReactNode }) {
  return (
    <Reveal delay={props.delay} className={styles.cell}>
      <Card>
        <CardHeader>
          <CardTitle asChild>
            <h3>{props.title}</h3>
          </CardTitle>
          <CardDescription>{props.text}</CardDescription>
        </CardHeader>
        <CardBody className={styles.bindings}>{props.children}</CardBody>
      </Card>
    </Reveal>
  )
}

/** The short press of a dual-role key sends a plain shortcut; it is not a catalog action. */
const escape = (): Action => ({ icon: Command, title: m.action_escape(), category: m.action_shortcut() })

/** A distinct key for each example; one input cannot have competing activation rules. */
function Press({ kind, keyName = 'F13' }: { kind: string; keyName?: string }) {
  return (
    <>
      <Keycaps keys={[keyName]} />
      <span className={styles.press}>{kind}</span>
    </>
  )
}
