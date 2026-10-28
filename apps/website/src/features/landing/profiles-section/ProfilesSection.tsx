import { useState } from 'react'
import { Keycap } from '@/components/keycap'
import { m } from '@/integrations/i18n/paraglide/messages'
import { ChoiceChips, FeatureCard, FeatureSection, GroupLabel } from '../feature-section'
import styles from './ProfilesSection.module.css'

type Profile = 'default' | 'work' | 'games'
type Rule = { trigger: string; action: string; category: string; app?: string }

export function ProfilesSection() {
  const [profile, setProfile] = useState<Profile>('work')
  const profiles = [
    ['default', m.defaultProfile()],
    ['work', m.workProfile()],
    ['games', m.gamesProfile()],
  ] as const
  const rules: Record<Profile, Rule[]> = {
    default: [
      { trigger: 'F5', action: m.playPause(), category: m.catSound() },
      { trigger: m.button4(), action: m.goBack(), category: m.catWindows() },
    ],
    work: [
      { trigger: 'F5', action: m.playPause(), category: m.catSound() },
      { trigger: m.button4(), action: m.previousTab(), category: m.catWindows(), app: 'Safari' },
      { trigger: 'F6', action: m.runShortcut(), category: m.catAutomation() },
    ],
    games: [
      { trigger: 'F6', action: m.muteMicrophone(), category: m.catSound() },
      { trigger: 'F9', action: m.captureArea(), category: m.catSystem() },
    ],
  }
  const name = profiles.find(([value]) => value === profile)![1]
  return (
    <FeatureSection
      id="profiles"
      eyebrow={m.profilesEyebrow()}
      title={m.profilesTitle()}
      lead={m.profilesLead()}
      extras={
        <FeatureCard className={styles.keys}>
          <GroupLabel>{m.switchWithKey()}</GroupLabel>
          <dl>
            {[
              ['F8', m.nextProfile()],
              ['F7', m.previousProfile()],
            ].map(([key, action]) => (
              <div key={key}>
                <dt>{m.press()}</dt>
                <dd>
                  <Keycap>{key}</Keycap>
                  <span aria-hidden="true">→</span>
                  {action}
                </dd>
              </div>
            ))}
          </dl>
        </FeatureCard>
      }
    >
      <FeatureCard className={styles.card}>
        <GroupLabel>{m.profileLabel()}</GroupLabel>
        <ChoiceChips
          label={m.profileLabel()}
          options={profiles}
          value={profile}
          onValueChange={setProfile}
        />
        <ul className={styles.rules} aria-label={m.rulesOf({ profile: name })} aria-live="polite">
          {rules[profile].map((rule) => (
            <li key={rule.trigger}>
              <Keycap>{rule.trigger}</Keycap>
              <span className={styles.arrow} aria-hidden="true">
                →
              </span>
              <span className={styles.action}>
                <strong>{rule.action}</strong>
                <span>{rule.category}</span>
              </span>
              <span className={styles.scope} data-app={Boolean(rule.app)}>
                {rule.app ? m.inApp({ app: rule.app }) : m.allApps()}
              </span>
            </li>
          ))}
        </ul>
        <p className={styles.note}>{m.excludedNote()}</p>
      </FeatureCard>
    </FeatureSection>
  )
}
