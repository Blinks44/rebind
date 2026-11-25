import {
  Accordion,
  AccordionItem,
  AccordionItemBody,
  AccordionItemContent,
  AccordionItemIndicator,
  AccordionItemTrigger,
} from '@moduix/react/accordion'
import { Link } from '@tanstack/react-router'
import { ArrowRight, ChevronDown } from 'lucide-react'
import type { Locale } from '@/config/locales'
import * as m from '@/integrations/i18n/paraglide/messages'

export function getLandingFaqItems(locale?: Locale) {
  const opts = locale ? { locale } : undefined
  return [
    { id: 'q1', question: m.faqQ1({}, opts), answer: m.faqA1({}, opts) },
    { id: 'q2', question: m.faqQ2({}, opts), answer: m.faqA2({}, opts) },
    { id: 'q3', question: m.faqQ3({}, opts), answer: m.faqA3({}, opts) },
    { id: 'q4', question: m.faqQ4({}, opts), answer: m.faqA4({}, opts) },
    { id: 'q5', question: m.faqQ5({}, opts), answer: m.faqA5({}, opts) },
    { id: 'q6', question: m.faqQ6({}, opts), answer: m.faqA6({}, opts) },
    { id: 'q7', question: m.faqQ7({}, opts), answer: m.faqA7({}, opts) },
    { id: 'q8', question: m.faqQ8({}, opts), answer: m.faqA8({}, opts) },
  ]
}

export function FaqSection() {
  const items = getLandingFaqItems()

  return (
    <section id="faq" className="section">
      <div className="container faq-wrap">
        <div className="section-head is-centered" data-reveal>
          <div className="eyebrow">{m.faqEyebrow()}</div>
          <h2 className="section-title">{m.faqTitle()}</h2>
          <p className="section-subtitle">{m.faqSubtitle()}</p>
        </div>

        <Accordion collapsible defaultValue={['q1']} className="faq-accordion">
          {items.map((item) => (
            <AccordionItem key={item.id} value={item.id} className="faq-item">
              <AccordionItemTrigger className="faq-trigger">
                <span>{item.question}</span>
                <AccordionItemIndicator>
                  <ChevronDown size={16} aria-hidden="true" />
                </AccordionItemIndicator>
              </AccordionItemTrigger>
              <AccordionItemContent>
                <AccordionItemBody className="faq-content">{item.answer}</AccordionItemBody>
              </AccordionItemContent>
            </AccordionItem>
          ))}
        </Accordion>

        <div className="seo-faq-links-box" data-reveal>
          <span className="seo-faq-links-label">{m.faqLinksLabel()}</span>
          <div className="seo-faq-links-grid">
            <Link to="/alternatives/logi-options-ghub/" className="seo-faq-pill">
              <span>{m.faqLinkLogi()}</span>
              <ArrowRight size={13} aria-hidden="true" />
            </Link>
            <Link to="/alternatives/steermouse/" className="seo-faq-pill">
              <span>{m.faqLinkSteermouse()}</span>
              <ArrowRight size={13} aria-hidden="true" />
            </Link>
            <Link to="/alternatives/linearmouse-mos/" className="seo-faq-pill">
              <span>{m.faqLinkLinear()}</span>
              <ArrowRight size={13} aria-hidden="true" />
            </Link>
            <Link to="/guides/mx-master-mac-setup/" className="seo-faq-pill">
              <span>{m.faqLinkMx()}</span>
              <ArrowRight size={13} aria-hidden="true" />
            </Link>
          </div>
        </div>
      </div>
    </section>
  )
}
