import { ArrowRight } from 'lucide-react'
import type { ReactNode } from 'react'
import type { Action } from '~/lib/actions'
import { ActionTile } from '../action-tile/ActionTile'
import styles from './Binding.module.css'

/**
 * One rule, as in the app's list: trigger, arrow, action and an optional trailing control.
 * A parent can line the arrows up by setting `--binding-trigger-width`; in a narrow column the action
 * moves under the trigger on its own (a container query), wherever the rule is placed.
 */
export function Binding(props: { trigger: ReactNode; action: Action; trailing?: ReactNode; dimmed?: boolean }) {
  return (
    <div className={styles.binding}>
      <div className={styles.row} data-dimmed={props.dimmed || undefined}>
        <div className={styles.trigger}>{props.trigger}</div>
        <ArrowRight className={styles.arrow} size={14} aria-hidden />
        <div className={styles.action}>
          <ActionTile icon={props.action.icon} />
          <span>
            <span className={styles.title}>{props.action.title}</span>
            {props.action.category && <span className={styles.category}>{props.action.category}</span>}
          </span>
        </div>
        {props.trailing && <div className={styles.trailing}>{props.trailing}</div>}
      </div>
    </div>
  )
}
