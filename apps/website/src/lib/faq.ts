import { m } from '~/paraglide/messages.js'

/** Questions shown on the page and published as FAQPage structured data. */
export const faq = () => [
  { id: 'free', question: m.faq_free_q(), answer: m.faq_free_a() },
  { id: 'devices', question: m.faq_devices_q(), answer: m.faq_devices_a() },
  { id: 'access', question: m.faq_access_q(), answer: m.faq_access_a() },
  { id: 'warning', question: m.faq_warning_q(), answer: m.faq_warning_a() },
  { id: 'mac', question: m.faq_mac_q(), answer: m.faq_mac_a() },
]
