import { Button } from '@moduix/react/button'
import { Heading } from '@moduix/react/heading'
import { Text } from '@moduix/react/text'
import { motion } from 'motion/react'
import { AppWindow, DownloadButton, DownloadNote, Section, StatusBadge } from '~/components'
import type { Release } from '~/lib/release'
import { m } from '~/paraglide/messages.js'
import styles from './Hero.module.css'

export function Hero({ release }: { release: Release | null }) {
  return (
    <Section flush className={styles.hero}>
      <StatusBadge>{m.hero_badge()}</StatusBadge>
      <Heading as="h1" className={styles.title}>
        {m.hero_title()}
      </Heading>
      <Text className={styles.lead}>{m.hero_lead()}</Text>
      <div className={styles.actions}>
        <DownloadButton release={release} />
        <Button asChild variant="outline" size="xl">
          <a href="#scenarios">{m.hero_secondary()}</a>
        </Button>
      </div>
      <DownloadNote release={release} />
      <motion.div
        className={styles.window}
        initial={{ opacity: 0, y: 40, scale: 0.97 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.7, ease: [0.2, 0.8, 0.2, 1] }}
      >
        <AppWindow />
      </motion.div>
    </Section>
  )
}
