import {
  Drawer,
  DrawerBackdrop,
  DrawerBody,
  DrawerCloseIcon,
  DrawerContent,
  DrawerHeader,
  DrawerPositioner,
  DrawerTitle,
  DrawerTrigger,
} from '@moduix/react/drawer'
import {
  Menu,
  MenuContent,
  MenuItemIndicator,
  MenuItemText,
  MenuPositioner,
  MenuRadioItem,
  MenuRadioItemGroup,
  MenuTrigger,
} from '@moduix/react/menu'
import { Link } from '@tanstack/react-router'
import { Check, ChevronDown, Globe, Menu as MenuIcon, Moon, Sun } from 'lucide-react'
import { useState } from 'react'
import { languageNames, type Locale, locales } from '@/config/locales'
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale, setLocale } from '@/integrations/i18n/paraglide/runtime'
import type { ColorScheme } from '@/lib/theme'

interface NavbarProps {
  theme: ColorScheme
  onToggleTheme: () => void
}

type NavItem =
  | { id: string; to: '/'; hash: string; label: string }
  | {
      id: string
      to: '/alternatives/logi-options-ghub/' | '/guides/mx-master-mac-setup/'
      hash?: undefined
      label: string
    }

const LOCALE_CODES: Record<Locale, string> = {
  en: 'EN',
  ru: 'RU',
  de: 'DE',
  fr: 'FR',
  es: 'ES',
  'zh-Hans': '中文',
}

function GitHubIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M12 0.5C5.37 0.5 0 5.87 0 12.5c0 5.3 3.44 9.8 8.21 11.39.6.11.82-.26.82-.58 0-.29-.01-1.05-.02-2.06-3.34.73-4.04-1.61-4.04-1.61-.55-1.38-1.33-1.75-1.33-1.75-1.09-.74.08-.73.08-.73 1.2.09 1.84 1.24 1.84 1.24 1.07 1.83 2.81 1.3 3.49 1 .11-.78.42-1.3.76-1.6-2.67-.3-5.47-1.33-5.47-5.93 0-1.31.47-2.38 1.24-3.22-.12-.3-.54-1.52.12-3.18 0 0 1.01-.32 3.3 1.23a11.5 11.5 0 0 1 6.01 0c2.29-1.55 3.3-1.23 3.3-1.23.66 1.66.24 2.88.12 3.18.77.84 1.24 1.91 1.24 3.22 0 4.61-2.81 5.62-5.48 5.92.43.37.81 1.1.81 2.22 0 1.61-.01 2.9-.01 3.29 0 .32.22.7.83.58C20.56 22.3 24 17.8 24 12.5 24 5.87 18.63 0.5 12 0.5Z" />
    </svg>
  )
}

export function Navbar({ theme, onToggleTheme }: NavbarProps) {
  const [drawerOpen, setDrawerOpen] = useState(false)
  const currentLocale = getLocale() as Locale

  const navItems: NavItem[] = [
    { id: 'features', to: '/', hash: 'features', label: m.navFeatures() },
    { id: 'alternatives', to: '/alternatives/logi-options-ghub/', label: m.navAlternatives() },
    { id: 'guides', to: '/guides/mx-master-mac-setup/', label: m.navGuides() },
    { id: 'install', to: '/', hash: 'install', label: m.navInstall() },
    { id: 'faq', to: '/', hash: 'faq', label: m.navFaq() },
  ]

  const onSelectLocale = (value: string) => {
    const next = value as Locale
    if (next !== currentLocale) {
      setLocale(next)
    }
  }

  return (
    <header className="site-nav">
      <div className="container site-nav-inner">
        <Link to="/" className="site-brand">
          <img src="/app-icon.png" alt="Rebind" width={28} height={28} />
          <span>{site.name}</span>
        </Link>

        <nav className="site-nav-links" aria-label={m.navPrimaryLabel()}>
          {navItems.map((item) => (
            <Link key={item.id} to={item.to} hash={item.hash} className="site-nav-link">
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="site-nav-actions">
          <Menu>
            <MenuTrigger className="btn-rb-outline nav-lang-btn" aria-label={m.navLanguageLabel()}>
              <Globe size={14} aria-hidden="true" />
              <span>{LOCALE_CODES[currentLocale]}</span>
              <ChevronDown size={13} aria-hidden="true" />
            </MenuTrigger>
            <MenuPositioner>
              <MenuContent>
                <MenuRadioItemGroup
                  value={currentLocale}
                  onValueChange={(details) => onSelectLocale(details.value)}
                >
                  {locales.map((loc) => (
                    <MenuRadioItem key={loc} value={loc}>
                      <MenuItemIndicator>
                        <Check size={14} aria-hidden="true" />
                      </MenuItemIndicator>
                      <MenuItemText>{languageNames[loc]}</MenuItemText>
                    </MenuRadioItem>
                  ))}
                </MenuRadioItemGroup>
              </MenuContent>
            </MenuPositioner>
          </Menu>

          <a
            href={site.repository}
            target="_blank"
            rel="noreferrer"
            className="btn-rb-outline nav-icon-btn nav-github-desktop"
            aria-label={m.navGithub()}
            title={m.navGithub()}
          >
            <GitHubIcon size={16} />
          </a>

          <button
            type="button"
            className="btn-rb-outline nav-icon-btn nav-theme-desktop"
            onClick={onToggleTheme}
            aria-label={m.navThemeToggle()}
            title={m.navThemeToggle()}
          >
            {theme === 'dark' ? (
              <Sun size={16} aria-hidden="true" />
            ) : (
              <Moon size={16} aria-hidden="true" />
            )}
          </button>

          <Link to="/" hash="install" className="btn-rb-dark nav-download-btn">
            {m.navDownload()}
          </Link>

          <Drawer open={drawerOpen} onOpenChange={(details) => setDrawerOpen(details.open)}>
            <DrawerTrigger
              className="btn-rb-outline nav-icon-btn mobile-menu-trigger"
              aria-label={m.navMenuLabel()}
            >
              <MenuIcon size={17} aria-hidden="true" />
            </DrawerTrigger>
            <DrawerBackdrop />
            <DrawerPositioner>
              <DrawerContent>
                <DrawerHeader>
                  <DrawerTitle>{site.name}</DrawerTitle>
                  <DrawerCloseIcon />
                </DrawerHeader>
                <DrawerBody>
                  <div className="drawer-nav-list">
                    {navItems.map((item) => (
                      <Link
                        key={item.id}
                        to={item.to}
                        hash={item.hash}
                        className="drawer-nav-link"
                        onClick={() => setDrawerOpen(false)}
                      >
                        {item.label}
                      </Link>
                    ))}
                    <a
                      href={site.repository}
                      target="_blank"
                      rel="noreferrer"
                      className="drawer-nav-link"
                      onClick={() => setDrawerOpen(false)}
                    >
                      <span>{m.navGithub()}</span>
                      <GitHubIcon size={16} />
                    </a>
                    <button
                      type="button"
                      className="drawer-nav-link"
                      style={{
                        border: 0,
                        background: 'transparent',
                        width: '100%',
                        cursor: 'pointer',
                      }}
                      onClick={() => {
                        onToggleTheme()
                        setDrawerOpen(false)
                      }}
                    >
                      <span>{m.navThemeToggle()}</span>
                      {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
                    </button>
                  </div>
                </DrawerBody>
              </DrawerContent>
            </DrawerPositioner>
          </Drawer>
        </div>
      </div>
    </header>
  )
}
