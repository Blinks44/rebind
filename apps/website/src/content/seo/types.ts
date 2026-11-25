import type { SiteRoutePath } from '@/config/locales'

export type AlternativeSlug = 'logi-options-ghub' | 'steermouse' | 'linearmouse-mos'
export type GuideSlug = 'mx-master-mac-setup'

export interface HighlightMetric {
  value: string
  label: string
}

export interface ComparisonRow {
  criterion: string
  rebind: string
  other: string
}

export interface FitCard {
  label: string
  title: string
  points: [string, string, string]
}

export interface StepCard {
  step: string
  title: string
  description: string
}

export interface AlternativePageData {
  slug: AlternativeSlug
  path: SiteRoutePath
  breadcrumbLabel: string
  metaTitle: string
  metaDescription: string
  headline: string
  subtitle: string
  highlights: [HighlightMetric, HighlightMetric, HighlightMetric]
  competitorColumn: string
  rows: ComparisonRow[]
  chooseRebind: FitCard
  stickWithOther: FitCard
  steps: [StepCard, StepCard, StepCard]
}

export interface GuideCard {
  label: string
  title: string
  description: string
  items: [string, string, string]
  footer: string
}

export interface PitfallItem {
  title: string
  description: string
}

export interface GuidePageData {
  slug: GuideSlug
  path: SiteRoutePath
  breadcrumbLabel: string
  metaTitle: string
  metaDescription: string
  headline: string
  subtitle: string
  secondaryCtaLabel: string
  secondaryCtaTo: SiteRoutePath
  cardsTitle: string
  cards: [GuideCard, GuideCard, GuideCard]
  stepsTitle: string
  steps: [StepCard, StepCard, StepCard, StepCard]
  pitfalls: [PitfallItem, PitfallItem, PitfallItem]
}

export interface LocaleSeoContent {
  alternatives: Record<AlternativeSlug, AlternativePageData>
  guides: Record<GuideSlug, GuidePageData>
}
