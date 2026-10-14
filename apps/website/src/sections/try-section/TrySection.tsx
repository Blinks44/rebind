import { Reveal, Section, SectionHeading, TryIt } from '~/components'
import { m } from '~/paraglide/messages.js'

export function TrySection() {
  return (
    <Section id="try" narrow>
      <SectionHeading title={m.try_title()} lead={m.try_lead()} centered />
      <Reveal>
        <TryIt />
      </Reveal>
    </Section>
  )
}
