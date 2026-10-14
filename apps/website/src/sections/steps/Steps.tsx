import { Heading } from '@moduix/react/heading'
import { Text } from '@moduix/react/text'
import { Reveal, Section, SectionHeading } from '~/components'
import { m } from '~/paraglide/messages.js'
import styles from './Steps.module.css'

export function Steps() {
  const steps = [
    { title: m.step1_title(), text: m.step1_text() },
    { title: m.step2_title(), text: m.step2_text() },
    { title: m.step3_title(), text: m.step3_text() },
  ]
  return (
    <Section>
      <SectionHeading title={m.steps_title()} />
      <ol className={styles.steps}>
        {steps.map((step, index) => (
          <li key={step.title}>
            <Reveal delay={index * 0.1}>
              <span className={styles.key} aria-hidden>
                {index + 1}
              </span>
              <Heading as="h3" className={styles.title}>
                {step.title}
              </Heading>
              <Text className={styles.text}>{step.text}</Text>
            </Reveal>
          </li>
        ))}
      </ol>
    </Section>
  )
}
