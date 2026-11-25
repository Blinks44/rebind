import type { LocaleSeoContent } from './types'

export const enSeoContent: LocaleSeoContent = {
  alternatives: {
    'logi-options-ghub': {
      slug: 'logi-options-ghub',
      path: '/alternatives/logi-options-ghub/',
      breadcrumbLabel: 'Logi Options+ & G HUB',
      metaTitle: 'Free Logi Options+ & Logitech G HUB Alternative for macOS · Rebind',
      metaDescription:
        'Use Logitech MX Master and G-series mice on macOS without 1 GB Logi Options+ or G HUB: native HID++ 2.0 DPI, SmartShift, Hi-Res wheel, Gesture button, battery, and smooth scroll.',
      headline: 'Use Logitech mice on Mac without 1 GB Logi Options+ or G HUB.',
      subtitle:
        'Configure Logitech MX Master & G-series mice directly over native HID++ 2.0 on macOS: DPI, SmartShift, Hi-Res wheel, Gesture button, smooth scroll, and live battery without 1 GB vendor suites.',
      highlights: [
        {
          value: 'Zero 1 GB Bloat',
          label: 'Native Swift 6 app · zero Electron, accounts, or background daemons',
        },
        {
          value: 'Native HID++ 2.0',
          label: 'DPI, SmartShift, Hi-Res wheel, Gesture button & live battery',
        },
        {
          value: 'Accessibility Only',
          label: 'No Input Monitoring, no keystroke logging, fail-open pause',
        },
      ],
      competitorColumn: 'LOGI OPTIONS+ / G HUB',
      rows: [
        {
          criterion: 'Install size & memory',
          rebind: 'Small native Swift 6 app · low idle RAM · MIT open source',
          other: '~1 GB installer + persistent Electron and background processes',
        },
        {
          criterion: 'Accounts & telemetry',
          rebind: '100% local JSON configs, zero accounts, zero telemetry',
          other: 'Cloud account prompts, analytics & auto-updater daemons',
        },
        {
          criterion: 'Permissions & privacy',
          rebind: 'Accessibility only, zero Input Monitoring, zero keystroke logging',
          other: 'Requires Input Monitoring, Bluetooth, background agents',
        },
        {
          criterion: 'Logitech HID++ controls',
          rebind: 'DPI, SmartShift, Hi-Res wheel, Gesture button, battery & G915 lights',
          other: 'Full vendor features + AI Prompt Builder & Flow',
        },
        {
          criterion: 'Scroll & smooth glide',
          rebind: 'Independent mouse V/H scroll + Gentle/Standard/Strong smooth glide',
          other: 'Basic toggle; often breaks trackpad consistency',
        },
        {
          criterion: 'Beyond Logitech',
          rebind: 'Works with any mouse, keyboard shortcuts, window tiling & profiles',
          other: 'Locked to Logitech devices only',
        },
      ],
      chooseRebind: {
        label: 'RECOMMENDED FOR DAILY MAC USE',
        title: 'Choose Rebind when…',
        points: [
          'You want DPI, SmartShift, Gesture button & battery without 1 GB bloat',
          'You want independent mouse scroll, smooth glide & extra buttons',
          'You prefer Accessibility-only, zero telemetry & local JSON backups',
        ],
      },
      stickWithOther: {
        label: 'WHEN LOGI OPTIONS+ / G HUB STILL FITS',
        title: 'Keep vendor software when…',
        points: [
          'You rely on Logitech Flow cross-computer clipboard switching',
          'You need firmware updates or per-key RGB macros on gaming gear',
          'You want to remap the Logitech MX thumb wheel as a trigger',
        ],
      },
      steps: [
        {
          step: 'STEP 01',
          title: 'Quit or uninstall Logi Options+ / G HUB',
          description:
            'Remove heavy Logitech background agents so they do not fight over HID++ packets. Rebind automatically warns if one is still active.',
        },
        {
          step: 'STEP 02',
          title: 'Install Rebind & grant Accessibility',
          description:
            'Run brew install --cask blinks44/tap/rebind. Rebind starts paused with zero bindings and never asks for Input Monitoring.',
        },
        {
          step: 'STEP 03',
          title: 'Tune HID++, scroll & Starter Setups',
          description:
            'Adjust DPI, SmartShift, and per-mouse smooth scrolling, then activate a built-in Starter Setup or custom per-app profile.',
        },
      ],
    },
    steermouse: {
      slug: 'steermouse',
      path: '/alternatives/steermouse/',
      breadcrumbLabel: 'SteerMouse',
      metaTitle: 'Free SteerMouse & Mac Mouse Fix Alternative (Open Source) · Rebind',
      metaDescription:
        'Compare Rebind vs SteerMouse and Mac Mouse Fix: free MIT Swift 6 app with Button 4/5+, 4-way movement gestures, wheel chords, Logitech HID++, keyboard remapping, and window tiling.',
      headline: 'A free, open-source SteerMouse & Mac Mouse Fix alternative.',
      subtitle:
        'Remap Button 4/5+, middle click, 4-way Button + Movement gestures, wheel chords, per-app profiles, Logitech HID++ hardware controls, and keyboard shortcuts in one MIT Swift app.',
      highlights: [
        {
          value: '100% Free · MIT',
          label: 'No paid license per major version, no activation server',
        },
        {
          value: 'Mouse + Keys + Windows',
          label: 'Side buttons, chords, keyboard Hold triggers & window tiling',
        },
        {
          value: 'Native HID++ 2.0',
          label: 'Direct DPI, SmartShift & live menu bar battery for Logitech mice',
        },
      ],
      competitorColumn: 'STEERMOUSE / MAC MOUSE FIX',
      rows: [
        {
          criterion: 'License & cost',
          rebind: '100% free & MIT open source on GitHub',
          other: 'Paid license (SteerMouse ~$20; Mac Mouse Fix paid since v3)',
        },
        {
          criterion: 'Extra buttons & gestures',
          rebind: 'Button 4/5+, middle click, 4-way Button + Move & Button + Wheel chords',
          other: 'Strong mouse button chords, click-and-drag gestures',
        },
        {
          criterion: 'Logitech HID++ hardware',
          rebind: 'Built-in DPI slider, SmartShift, Hi-Res wheel, Gesture button & battery',
          other: 'Cursor sensitivity / acceleration only (no SmartShift or HID++ battery)',
        },
        {
          criterion: 'Keyboard & window tiling',
          rebind: 'Press/Double Press/Hold key remaps, snippets & window halves/quarters',
          other: 'Mouse-focused utilities only',
        },
        {
          criterion: 'Per-app profiles & safety',
          rebind: 'Per-app rules, game/VM exclusions, fail-open pause ⌃⌥⇧⌘ Esc',
          other: 'App-specific mouse button profiles',
        },
        {
          criterion: 'Config portability',
          rebind: 'Human-readable JSON with export/import & rolling local backups',
          other: 'App-managed binary/plist preferences',
        },
      ],
      chooseRebind: {
        label: 'RECOMMENDED ALL-IN-ONE',
        title: 'Choose Rebind when…',
        points: [
          'You want a free MIT mouse button remapper with drag gestures and wheel chords',
          'You also want Logitech HID++ DPI/SmartShift, keyboard rules & window tiling',
          'You want plain JSON profiles with conflict previews before activating',
        ],
      },
      stickWithOther: {
        label: 'WHEN STEERMOUSE / MMF STILL FITS',
        title: 'Stick with SteerMouse or Mac Mouse Fix when…',
        points: [
          'You need fine-grained custom cursor acceleration curves (SteerMouse)',
          'You are on older macOS (< 15) where Rebind does not run',
          'You already own a license and only tweak cursor speed and clicks',
        ],
      },
      steps: [
        {
          step: 'STEP 01',
          title: 'Install via Homebrew or DMG',
          description:
            'Run brew install --cask blinks44/tap/rebind and grant Accessibility only. Starts paused until you enable rules.',
        },
        {
          step: 'STEP 02',
          title: 'Pick a built-in Starter Setup',
          description:
            'Preview the Mouse & Browser or MX Master Starter Setup with trigger lists before applying a single rule.',
        },
        {
          step: 'STEP 03',
          title: 'Add per-app button & chord overrides',
          description:
            'Bind Button 4/5 or Button + Wheel differently for your browser, IDE, and design apps, and exclude games.',
        },
      ],
    },
    'linearmouse-mos': {
      slug: 'linearmouse-mos',
      path: '/alternatives/linearmouse-mos/',
      breadcrumbLabel: 'LinearMouse & Mos',
      metaTitle: 'LinearMouse & Mos Alternative With HID++ and Buttons · Rebind',
      metaDescription:
        'Reverse mouse scroll direction independently from your MacBook trackpad, add per-mouse smooth scrolling, plus Logitech HID++, extra buttons, and window tiling in one Swift app.',
      headline: 'Independent mouse scroll & smooth glide, plus buttons and HID++.',
      subtitle:
        'Keep natural trackpad scrolling while flipping external mouse wheels vertically or horizontally, add Gentle/Standard/Strong smooth glide, and retire separate button and Logitech utilities.',
      highlights: [
        {
          value: 'Trackpad Untouched',
          label: 'External mouse wheel flips cleanly while trackpad stays natural',
        },
        {
          value: 'Per-Mouse Smooth Glide',
          label: 'Gentle, Standard, or Strong smooth scroll tuned per device',
        },
        {
          value: 'One Menu Bar Icon',
          label: 'Combines scroll, extra buttons, Logitech HID++ & window tiling',
        },
      ],
      competitorColumn: 'LINEARMOUSE / MOS',
      rows: [
        {
          criterion: 'Independent scroll direction',
          rebind: 'Separate V/H scroll flip per external mouse; trackpad stays natural',
          other: 'Independent mouse vs trackpad scroll direction',
        },
        {
          criterion: 'Smooth scrolling',
          rebind: 'Per-mouse Gentle, Standard, or Strong smooth scroll glide',
          other: 'Mos specializes in smooth scroll; LinearMouse focuses on lines/acceleration',
        },
        {
          criterion: 'Extra buttons & gestures',
          rebind: 'Button 4/5+, middle click, 4-way drag gestures & Button + Wheel chords',
          other: 'Basic back/forward button support only',
        },
        {
          criterion: 'Logitech HID++ 2.0',
          rebind: 'Native DPI slider, SmartShift, Hi-Res wheel, Gesture button & battery',
          other: 'Not supported (requires Logi Options+ or another app)',
        },
        {
          criterion: 'Keyboard & window tiling',
          rebind: 'Key Press/Double Press/Hold remapping & built-in window tiling',
          other: 'Mouse scrolling/pointer only',
        },
        {
          criterion: 'Permissions & format',
          rebind: 'Accessibility only, MIT Swift 6, readable JSON config with backups',
          other: 'Accessibility permission; open source',
        },
      ],
      chooseRebind: {
        label: 'RECOMMENDED SINGLE STACK',
        title: 'Choose Rebind when…',
        points: [
          'You want both independent scroll direction AND smooth scrolling in one app',
          'You also remap side buttons, Logitech HID++ controls, keys, or window tiling',
          'You want fewer background input hooks fighting over the same mouse events',
        ],
      },
      stickWithOther: {
        label: 'WHEN LINEARMOUSE / MOS STILL FITS',
        title: 'Stick with LinearMouse or Mos when…',
        points: [
          'You specifically want LinearMouse’s pointer acceleration disable curve',
          'You run macOS 13 or 14 (Rebind targets macOS 15+)',
          'You only need scroll smoothing and never remap buttons or Logitech DPI',
        ],
      },
      steps: [
        {
          step: 'STEP 01',
          title: 'Disable overlapping scroll hooks',
          description:
            'Quit Mos, Scroll Reverser, or LinearMouse so two event taps do not double-flip or fight over scroll wheel events.',
        },
        {
          step: 'STEP 02',
          title: 'Flip mouse scroll & pick glide preset',
          description:
            'Select your external mouse in Rebind, flip vertical/horizontal direction, and choose Gentle, Standard, or Strong glide.',
        },
        {
          step: 'STEP 03',
          title: 'Add side buttons & per-app exclusions',
          description:
            'Map Button 4/5 or zoom chords and exclude fullscreen games or remote desktop sessions cleanly.',
        },
      ],
    },
  },
  guides: {
    'mx-master-mac-setup': {
      slug: 'mx-master-mac-setup',
      path: '/guides/mx-master-mac-setup/',
      breadcrumbLabel: 'MX Master Mac Setup',
      metaTitle: 'Set Up Logitech MX Master & G-Series on Mac Without Logi Options+ · Rebind',
      metaDescription:
        'Step-by-step guide to configuring Logitech MX Master and G-series mice on macOS with Rebind: native HID++ 2.0 DPI, SmartShift, Gesture button, independent scroll, and window tiling.',
      headline: 'Set up MX Master & G-series mice on Mac without vendor bloat.',
      subtitle:
        'Get DPI, SmartShift, Hi-Res wheel, Gesture button, independent scroll direction, smooth glide, and window tiling on your Mac without installing 1 GB Logitech Options+ or G HUB.',
      secondaryCtaLabel: 'Compare Logi Options+ & G HUB',
      secondaryCtaTo: '/alternatives/logi-options-ghub/',
      cardsTitle: 'Start from built-in offline Starter Setups',
      cards: [
        {
          label: 'LOGITECH HID++ 2.0',
          title: 'MX Master Productivity',
          description: 'Every essential MX Master control with zero vendor daemons.',
          items: [
            'DPI slider + SmartShift sensitivity',
            'Gesture button + 4-way drag',
            'Menu bar live battery percentage',
          ],
          footer: 'Built-in offline Starter Setup',
        },
        {
          label: 'BROWSER & SCROLL',
          title: 'Browser & Mouse Basics',
          description: 'Natural trackpad + classic mouse wheel + smooth glide.',
          items: [
            'Button 4/5 -> Back / Forward',
            'Middle click + Wheel -> Zoom / Tabs',
            'Smooth scroll: Standard glide',
          ],
          footer: 'Works on any USB or Bluetooth mouse',
        },
        {
          label: 'WINDOW & KEYBOARD',
          title: 'Window Management',
          description: 'Tile windows across displays and keep games excluded cleanly.',
          items: [
            'Halves · Quarters · Fill · Center',
            'Next display & Spaces shortcuts',
            'Per-app exclusions for games & VMs',
          ],
          footer: 'Conflict preview before enabling',
        },
      ],
      stepsTitle: 'Four steps to a bloat-free setup',
      steps: [
        {
          step: '01 · ACCESSIBILITY',
          title: 'Grant one permission',
          description:
            'Install Rebind and grant Accessibility only. Starts paused with zero bindings - no Input Monitoring.',
        },
        {
          step: '02 · HID++',
          title: 'Tune DPI & scroll',
          description:
            'Set DPI, SmartShift, Hi-Res wheel, independent scroll direction, and per-mouse smooth glide.',
        },
        {
          step: '03 · STARTER',
          title: 'Preview & activate',
          description:
            'Pick an offline Starter Setup with trigger & conflict preview, or import/export plain JSON profiles.',
        },
        {
          step: '04 · FAIL-OPEN',
          title: 'Pause anytime',
          description:
            'Press ⌃⌥⇧⌘ Escape anytime to pause all rules instantly. Any error falls back to normal macOS input.',
        },
      ],
      pitfalls: [
        {
          title: 'Warns if Logi Options+ is running',
          description:
            'Running two HID++ drivers causes double scrolls and stuck DPI. Rebind detects Logi Options+ or G HUB and alerts you.',
        },
        {
          title: 'Trackpad stays natural',
          description:
            'Flipping mouse wheel direction never breaks your MacBook trackpad or Magic Trackpad natural scrolling.',
        },
        {
          title: 'Plain JSON with rolling backups',
          description:
            'Your rules and profiles live in ~/Library/Application Support/Rebind with automatic rolling backups and easy sync.',
        },
      ],
    },
  },
}
