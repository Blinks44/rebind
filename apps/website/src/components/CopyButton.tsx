import { Check, Copy } from 'lucide-react'
import { useCallback, useEffect, useRef, useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'

interface CopyButtonProps {
  text: string
  className?: string
  showLabel?: boolean
}

export function CopyButton({ text, className = '', showLabel = false }: CopyButtonProps) {
  const [copied, setCopied] = useState(false)
  const timerRef = useRef<number | null>(null)

  useEffect(() => {
    return () => {
      if (timerRef.current !== null) window.clearTimeout(timerRef.current)
    }
  }, [])

  const onCopy = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      if (timerRef.current !== null) window.clearTimeout(timerRef.current)
      timerRef.current = window.setTimeout(() => setCopied(false), 1800)
    } catch {
      // Ignore clipboard failures in restricted contexts.
    }
  }, [text])

  return (
    <button
      type="button"
      className={`copy-icon-btn ${copied ? 'is-copied' : ''} ${className}`.trim()}
      onClick={onCopy}
      aria-label={copied ? m.copiedLabel() : m.copyLabel()}
      title={copied ? m.copiedLabel() : m.copyLabel()}
    >
      {copied ? <Check size={14} aria-hidden="true" /> : <Copy size={14} aria-hidden="true" />}
      {showLabel ? <span>{copied ? m.copiedLabel() : m.copyLabel()}</span> : null}
    </button>
  )
}
