import type { LocaleSeoContent } from './types'

export const deSeoContent: LocaleSeoContent = {
  alternatives: {
    'logi-options-ghub': {
      slug: 'logi-options-ghub',
      path: '/alternatives/logi-options-ghub/',
      breadcrumbLabel: 'Logi Options+ & G HUB',
      metaTitle: 'Kostenlose Logi Options+ & Logitech G HUB Alternative für macOS · Rebind',
      metaDescription:
        'Nutze Logitech MX Master & G-Serie auf macOS ohne 1 GB Logi Options+ oder G HUB: natives HID++ 2.0 DPI, SmartShift, Hi-Res-Rad, Gestentaste, Akku und Smooth Scroll.',
      headline: 'Nutze Logitech-Mäuse auf dem Mac ohne 1 GB Logi Options+ oder G HUB.',
      subtitle:
        'Steuere Logitech MX Master & G-Serie direkt über natives HID++ 2.0 auf macOS: DPI, SmartShift, Hi-Res-Rad, Gestentaste, Smooth Scroll und Live-Akku ohne 1-GB-Herstellerpakete.',
      highlights: [
        {
          value: 'Ohne 1 GB Ballast',
          label: 'Native Swift-6-App · ohne Electron, Konten oder Hintergrund-Daemons',
        },
        {
          value: 'Natives HID++ 2.0',
          label: 'DPI, SmartShift, Hi-Res-Rad, Gestentaste & Live-Akku',
        },
        {
          value: 'Nur Bedienungshilfen',
          label: 'Kein Input Monitoring, kein Keylogging, Fail-open-Pause',
        },
      ],
      competitorColumn: 'LOGI OPTIONS+ / G HUB',
      rows: [
        {
          criterion: 'Größe & Speicher',
          rebind: 'Kompakte Swift-6-App · geringer RAM-Bedarf · MIT Open Source',
          other: '~1 GB Installer + dauerhafte Electron- und Hintergrundprozesse',
        },
        {
          criterion: 'Konten & Telemetrie',
          rebind: '100 % lokale JSON-Configs, keine Konten, keine Telemetrie',
          other: 'Cloud-Konto-Abfragen, Analytik & Auto-Updater-Daemons',
        },
        {
          criterion: 'Rechte & Datenschutz',
          rebind: 'Nur Bedienungshilfen, kein Input Monitoring, kein Mitschneiden',
          other: 'Fordert Input Monitoring, Bluetooth und Hintergrund-Agenten',
        },
        {
          criterion: 'Logitech HID++ Funktionen',
          rebind: 'DPI, SmartShift, Hi-Res-Rad, Gestentaste, Akku & G915-Licht',
          other: 'Voller Herstellerumfang + AI Prompt Builder & Flow',
        },
        {
          criterion: 'Scroll & Smooth Glide',
          rebind: 'Unabhängiges Maus-V/H-Scrollen + Gentle/Standard/Strong Glide',
          other: 'Einfacher Schalter; stört oft das Trackpad-Verhalten',
        },
        {
          criterion: 'Über Logitech hinaus',
          rebind: 'Läuft mit jeder Maus, Tastenkürzeln, Fenster-Tiling & Profilen',
          other: 'Auf Logitech-Geräte beschränkt',
        },
      ],
      chooseRebind: {
        label: 'EMPFOHLEN FÜR DEN MAC-ALLTAG',
        title: 'Wähle Rebind, wenn…',
        points: [
          'Du DPI, SmartShift, Gestentaste & Akku ohne 1-GB-Suite möchtest',
          'Du unabhängiges Mausrad-Scrollen, Smooth Glide & Zusatztasten brauchst',
          'Du nur Bedienungshilfen, null Telemetrie & lokale JSON-Backups bevorzugst',
        ],
      },
      stickWithOther: {
        label: 'WANN LOGI OPTIONS+ / G HUB WEITERHIN PASST',
        title: 'Behalte Hersteller-Software, wenn…',
        points: [
          'Du Logitech Flow für rechnerübergreifende Zwischenablage nutzt',
          'Du Firmware-Updates oder Gaming-RGB-Makros pro Taste brauchst',
          'Du das MX-Master-Daumenrad als eigenen Auslöser belegen willst',
        ],
      },
      steps: [
        {
          step: 'SCHRITT 01',
          title: 'Logi Options+ / G HUB beenden oder entfernen',
          description:
            'Beende die schweren Logitech-Agenten, damit keine HID++-Konflikte entstehen. Rebind warnt automatisch, falls einer noch läuft.',
        },
        {
          step: 'SCHRITT 02',
          title: 'Rebind installieren & Bedienungshilfen erlauben',
          description:
            'Führe brew install --cask blinks44/tap/rebind aus. Rebind startet pausiert ohne Regeln und fragt nie nach Input Monitoring.',
        },
        {
          step: 'SCHRITT 03',
          title: 'HID++, Scroll & Starter-Setups einstellen',
          description:
            'Stelle DPI, SmartShift und Smooth Scroll ein und aktiviere ein Offline-Starter-Setup oder App-Profil.',
        },
      ],
    },
    steermouse: {
      slug: 'steermouse',
      path: '/alternatives/steermouse/',
      breadcrumbLabel: 'SteerMouse',
      metaTitle: 'Kostenlose SteerMouse & Mac Mouse Fix Alternative (Open Source) · Rebind',
      metaDescription:
        'Vergleiche Rebind mit SteerMouse und Mac Mouse Fix: kostenlose MIT-Swift-6-App mit Taste 4/5+, 4-Wege-Ziehgesten, Rad-Akkorden, Logitech HID++, Tastenkürzeln und Fenster-Tiling.',
      headline: 'Eine kostenlose Open-Source-Alternative zu SteerMouse & Mac Mouse Fix.',
      subtitle:
        'Belege Taste 4/5+, Mittelklick, 4-Wege-Ziehgesten, Rad-Akkorde, App-Profile, Logitech HID++ und Tastenkürzel in einer kostenlosen MIT-Swift-App.',
      highlights: [
        {
          value: '100 % Gratis · MIT',
          label: 'Keine kostenpflichtige Lizenz pro Hauptversion, kein Aktivierungsserver',
        },
        {
          value: 'Maus + Tasten + Fenster',
          label: 'Seitentasten, Akkorde, Hold-Tasten & Fenster-Tiling vereint',
        },
        {
          value: 'Natives HID++ 2.0',
          label: 'Direkter DPI-Regler, SmartShift & Menüleisten-Akku für Logitech',
        },
      ],
      competitorColumn: 'STEERMOUSE / MAC MOUSE FIX',
      rows: [
        {
          criterion: 'Lizenz & Preis',
          rebind: '100 % kostenlos & MIT Open Source auf GitHub',
          other: 'Bezahl-Lizenz (SteerMouse ~20 $; Mac Mouse Fix ab v3 kostenpflichtig)',
        },
        {
          criterion: 'Zusatztasten & Gesten',
          rebind: 'Taste 4/5+, Mittelklick, 4-Wege-Taste+Bewegung & Rad-Akkorde',
          other: 'Starke Maustasten-Akkorde und Klick-Zieh-Gesten',
        },
        {
          criterion: 'Logitech HID++ Hardware',
          rebind: 'Eingebauter DPI-Regler, SmartShift, Hi-Res-Rad, Gestentaste & Akku',
          other: 'Nur Zeigergeschwindigkeit / Beschleunigung (kein SmartShift)',
        },
        {
          criterion: 'Tastatur & Fenster-Tiling',
          rebind: 'Press/Double-Press/Hold-Tasten, Snippets & Fenster-Hälften/-Viertel',
          other: 'Reine Maus-Utilities',
        },
        {
          criterion: 'App-Profile & Sicherheit',
          rebind: 'App-Regeln, Spiel-/VM-Ausnahmen, Fail-open-Pause ⌃⌥⇧⌘ Esc',
          other: 'App-spezifische Maustasten-Profile',
        },
        {
          criterion: 'Konfig-Portabilität',
          rebind: 'Lesbares JSON mit Export/Import & automatischen Backups',
          other: 'App-verwaltete Binär-/plist-Einstellungen',
        },
      ],
      chooseRebind: {
        label: 'EMPFOHLENES KOMPLETTPAKET',
        title: 'Wähle Rebind, wenn…',
        points: [
          'Du einen kostenlosen MIT-Maustasten-Remapper mit Ziehgesten und Rad-Akkorden willst',
          'Du zusätzlich Logitech HID++ DPI/SmartShift, Tastenkürzel & Fenster-Tiling nutzt',
          'Du lesbare JSON-Profile mit Konfliktvorschau vor dem Aktivieren möchtest',
        ],
      },
      stickWithOther: {
        label: 'WANN STEERMOUSE / MMF WEITERHIN PASST',
        title: 'Bleib bei SteerMouse oder Mac Mouse Fix, wenn…',
        points: [
          'Du feingranulare eigene Mausbeschleunigungskurven brauchst (SteerMouse)',
          'Du älteres macOS (< 15) verwendest, wo Rebind nicht läuft',
          'Du bereits eine Lizenz besitzt und nur Klicks/Zeigertempo anpasst',
        ],
      },
      steps: [
        {
          step: 'SCHRITT 01',
          title: 'Per Homebrew oder DMG installieren',
          description:
            'Führe brew install --cask blinks44/tap/rebind aus und erlaube nur Bedienungshilfen. Startet pausiert.',
        },
        {
          step: 'SCHRITT 02',
          title: 'Starter-Setup auswählen',
          description:
            'Prüfe die Auslöserliste im Starter-Setup für Browser oder MX Master vor dem Aktivieren.',
        },
        {
          step: 'SCHRITT 03',
          title: 'App-Profile ergänzen',
          description:
            'Belege Taste 4/5 oder Rad-Akkorde für Browser, IDE und Design-Apps separat und schließe Spiele aus.',
        },
      ],
    },
    'linearmouse-mos': {
      slug: 'linearmouse-mos',
      path: '/alternatives/linearmouse-mos/',
      breadcrumbLabel: 'LinearMouse & Mos',
      metaTitle: 'LinearMouse & Mos Alternative mit HID++ und Maustasten · Rebind',
      metaDescription:
        'Kehre das Mausrad unabhängig vom MacBook-Trackpad um, nutze Smooth Scroll pro Maus und kombiniere alles mit Logitech HID++, Seitentasten und Fenster-Tiling.',
      headline: 'Unabhängiges Maus-Scrollen & Smooth Glide, plus Tasten und HID++.',
      subtitle:
        'Behalte natürliches Trackpad-Scrollen bei, drehe externe Mausräder vertikal/horizontal um, stelle Gentle/Standard/Strong Glide ein und spare separate Tasten- und Logitech-Tools.',
      highlights: [
        {
          value: 'Trackpad unangetastet',
          label: 'Mausrad dreht sauber um, während das Trackpad natürlich bleibt',
        },
        {
          value: 'Smooth Glide pro Maus',
          label: 'Gentle, Standard oder Strong für jede externe Maus einstellbar',
        },
        {
          value: 'Ein Menüleisten-Symbol',
          label: 'Vereint Scrollen, Zusatztasten, Logitech HID++ & Fenster-Tiling',
        },
      ],
      competitorColumn: 'LINEARMOUSE / MOS',
      rows: [
        {
          criterion: 'Unabhängige Scrollrichtung',
          rebind: 'Getrennte V/H-Umkehr pro Maus; Trackpad bleibt natürlich',
          other: 'Unabhängige Scrollrichtung für Maus und Trackpad',
        },
        {
          criterion: 'Sanftes Scrollen',
          rebind: 'Gentle, Standard oder Strong Smooth Glide pro Maus',
          other: 'Mos für Smooth Scroll; LinearMouse für Zeilen/Beschleunigung',
        },
        {
          criterion: 'Zusatztasten & Gesten',
          rebind: 'Taste 4/5+, Mittelklick, 4-Wege-Gesten & Taste+Rad-Akkorde',
          other: 'Nur einfache Zurück-/Vorwärts-Tasten',
        },
        {
          criterion: 'Logitech HID++ 2.0',
          rebind: 'Nativer DPI-Regler, SmartShift, Hi-Res-Rad, Gestentaste & Akku',
          other: 'Nicht enthalten (erfordert Logi Options+ oder Zusatztool)',
        },
        {
          criterion: 'Tastatur & Fenster-Tiling',
          rebind: 'Press/Double-Press/Hold-Tasten & integriertes Fenster-Tiling',
          other: 'Nur Maus-Scrollen und Zeiger',
        },
        {
          criterion: 'Rechte & Format',
          rebind: 'Nur Bedienungshilfen, MIT Swift 6, lesbares JSON mit Backups',
          other: 'Bedienungshilfen; Open Source',
        },
      ],
      chooseRebind: {
        label: 'EMPFOHLENER EINZEL-STACK',
        title: 'Wähle Rebind, wenn…',
        points: [
          'Du unabhängige Scrollrichtung UND Smooth Scroll in einer App willst',
          'Du auch Seitentasten, Logitech HID++, Tastenkürzel oder Tiling nutzt',
          'Du weniger konkurrierende Eingabe-Hooks im Hintergrund laufen lassen willst',
        ],
      },
      stickWithOther: {
        label: 'WANN LINEARMOUSE / MOS WEITERHIN PASST',
        title: 'Bleib bei LinearMouse oder Mos, wenn…',
        points: [
          'Du gezielt die Beschleunigungs-Abschaltung von LinearMouse brauchst',
          'Du macOS 13 oder 14 nutzt (Rebind benötigt macOS 15+)',
          'Du wirklich nur Scroll-Glättung ohne Tasten oder Logitech-DPI brauchst',
        ],
      },
      steps: [
        {
          step: 'SCHRITT 01',
          title: 'Überlappende Scroll-Tools beenden',
          description:
            'Beende Mos, Scroll Reverser oder LinearMouse, damit nicht zwei Hooks gleichzeitig das Mausrad umkehren.',
        },
        {
          step: 'SCHRITT 02',
          title: 'Mausrad umkehren & Glide wählen',
          description:
            'Wähle deine Maus in Rebind, drehe V/H-Scroll um und stelle Gentle, Standard oder Strong ein.',
        },
        {
          step: 'SCHRITT 03',
          title: 'Tasten & Ausnahmen hinzufügen',
          description:
            'Belege Taste 4/5 oder Zoom-Akkorde und schließe Vollbildspiele oder Remote-Desktop sauber aus.',
        },
      ],
    },
  },
  guides: {
    'mx-master-mac-setup': {
      slug: 'mx-master-mac-setup',
      path: '/guides/mx-master-mac-setup/',
      breadcrumbLabel: 'MX Master Mac-Setup',
      metaTitle: 'Logitech MX Master & G-Serie auf Mac ohne Logi Options+ einrichten · Rebind',
      metaDescription:
        'Schritt-für-Schritt-Anleitung für Logitech MX Master und G-Serie auf macOS mit Rebind: natives HID++ 2.0 DPI, SmartShift, Gestentaste, unabhängiges Scrollen und Fenster-Tiling.',
      headline: 'Richte MX Master & G-Serie auf dem Mac ohne Hersteller-Ballast ein.',
      subtitle:
        'Erhalte DPI, SmartShift, Hi-Res-Rad, Gestentaste, unabhängiges Scrollen, Smooth Glide und Fenster-Tiling auf dem Mac ohne 1 GB Logitech Options+ oder G HUB.',
      secondaryCtaLabel: 'Mit Logi Options+ & G HUB vergleichen',
      secondaryCtaTo: '/alternatives/logi-options-ghub/',
      cardsTitle: 'Starte mit eingebauten Offline-Starter-Setups',
      cards: [
        {
          label: 'LOGITECH HID++ 2.0',
          title: 'MX Master Produktivität',
          description: 'Alle wichtigen MX-Master-Funktionen ohne Hersteller-Daemons.',
          items: [
            'DPI-Regler + SmartShift-Empfindlichkeit',
            'Gestentaste + 4-Wege-Bewegung',
            'Live-Akkustand in der Menüleiste',
          ],
          footer: 'Eingebautes Offline-Starter-Setup',
        },
        {
          label: 'BROWSER & SCROLL',
          title: 'Browser- & Maus-Basis',
          description: 'Natürliches Trackpad + klassisches Mausrad + Smooth Glide.',
          items: [
            'Taste 4/5 -> Zurück / Vorwärts',
            'Mittelklick + Rad -> Zoom / Tabs',
            'Smooth Scroll: Standard Glide',
          ],
          footer: 'Läuft mit jeder USB- oder Bluetooth-Maus',
        },
        {
          label: 'FENSTER & TASTATUR',
          title: 'Fensterverwaltung',
          description: 'Ordne Fenster über Displays an und halte Spiele sauber außen vor.',
          items: [
            'Hälften · Viertel · Fill · Center',
            'Nächstes Display & Spaces-Kürzel',
            'App-Ausnahmen für Spiele & VMs',
          ],
          footer: 'Konfliktvorschau vor Aktivierung',
        },
      ],
      stepsTitle: 'Vier Schritte zum schlanken Setup',
      steps: [
        {
          step: '01 · BEDIENUNGSHILFEN',
          title: 'Eine Berechtigung erteilen',
          description:
            'Rebind installieren und nur Bedienungshilfen erlauben. Startet pausiert ohne Regeln - kein Input Monitoring.',
        },
        {
          step: '02 · HID++',
          title: 'DPI & Scroll abstimmen',
          description:
            'DPI, SmartShift, Hi-Res-Rad, unabhängige Scrollrichtung und Smooth Glide pro Maus einstellen.',
        },
        {
          step: '03 · STARTER',
          title: 'Prüfen & aktivieren',
          description:
            'Offline-Starter-Setup samt Konfliktvorschau wählen oder JSON-Profile importieren/exportieren.',
        },
        {
          step: '04 · FAIL-OPEN',
          title: 'Jederzeit pausieren',
          description:
            'Drücke ⌃⌥⇧⌘ Esc, um alle Regeln sofort zu pausieren. Bei Fehlern greift sofort normale macOS-Eingabe.',
        },
      ],
      pitfalls: [
        {
          title: 'Warnt bei laufendem Logi Options+',
          description:
            'Zwei HID++-Treiber gleichzeitig verursachen doppeltes Scrollen und klemmende DPI. Rebind erkennt Logi Options+ oder G HUB und warnt dich.',
        },
        {
          title: 'Trackpad bleibt natürlich',
          description:
            'Das Umkehren des Mausrads verändert niemals das natürliche Scrollen deines MacBook- oder Magic-Trackpads.',
        },
        {
          title: 'Klartext-JSON mit rotierenden Backups',
          description:
            'Deine Regeln liegen in ~/Library/Application Support/Rebind mit automatischen Backups und einfachem Export.',
        },
      ],
    },
  },
}
