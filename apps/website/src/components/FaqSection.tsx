import {
  Accordion,
  AccordionItem,
  AccordionItemBody,
  AccordionItemContent,
  AccordionItemIndicator,
  AccordionItemTrigger,
} from '@moduix/react/accordion'
import { ChevronDown } from 'lucide-react'
import * as m from '@/integrations/i18n/paraglide/messages'

export function FaqSection() {
  const items = [
    { id: 'q1', q: m.faqQ1(), a: m.faqA1() },
    { id: 'q2', q: m.faqQ2(), a: m.faqA2() },
    { id: 'q3', q: m.faqQ3(), a: m.faqA3() },
    { id: 'q4', q: m.faqQ4(), a: m.faqA4() },
    { id: 'q5', q: m.faqQ5(), a: m.faqA5() },
    { id: 'q6', q: m.faqQ6(), a: m.faqA6() },
  ]

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
                <span>{item.q}</span>
                <AccordionItemIndicator>
                  <ChevronDown size={16} aria-hidden="true" />
                </AccordionItemIndicator>
              </AccordionItemTrigger>
              <AccordionItemContent>
                <AccordionItemBody className="faq-content">{item.a}</AccordionItemBody>
              </AccordionItemContent>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </section>
  )
}
