import { Image } from '@moduix/react/image'
import keyboard from '@/assets/product/keyboard.png?w=520;1040;2080&format=webp&quality=90&effort=6&as=srcset'
import keyboardPng from '@/assets/product/keyboard.png'
import mouse from '@/assets/product/mouse.png?w=520;1040;2080&format=webp&quality=90&effort=6&as=srcset'
import mousePng from '@/assets/product/mouse.png'
import trackpad from '@/assets/product/trackpad.png?w=520;1040;2080&format=webp&quality=90&effort=6&as=srcset'
import trackpadPng from '@/assets/product/trackpad.png'
import magicTrackpad from '@/assets/product/magic-trackpad.png?w=520;1040;2080&format=webp&quality=90&effort=6&as=srcset'
import magicTrackpadPng from '@/assets/product/magic-trackpad.png'
import magicMouse from '@/assets/product/magic-mouse.png?w=520;1040;2080&format=webp&quality=90&effort=6&as=srcset'
import magicMousePng from '@/assets/product/magic-mouse.png'
import styles from './ProductImage.module.css'

const images = {
  keyboard: [keyboardPng, keyboard],
  mouse: [mousePng, mouse],
  trackpad: [trackpadPng, trackpad],
  'magic-trackpad': [magicTrackpadPng, magicTrackpad],
  'magic-mouse': [magicMousePng, magicMouse],
} as const

export function ProductImage({ view, alt }: { view: keyof typeof images; alt: string }) {
  const [src, srcSet] = images[view]
  return (
    <picture className={styles.picture}>
      <source
        type="image/webp"
        srcSet={srcSet}
        sizes="(max-width: 1080px) calc(100vw - 40px), 1040px"
      />
      <Image src={src} width={1080} height={720} alt={alt} loading="lazy" decoding="async" />
    </picture>
  )
}
