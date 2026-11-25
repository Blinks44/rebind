import type { LocaleSeoContent } from './types'

export const frSeoContent: LocaleSeoContent = {
  alternatives: {
    'logi-options-ghub': {
      slug: 'logi-options-ghub',
      path: '/alternatives/logi-options-ghub/',
      breadcrumbLabel: 'Logi Options+ & G HUB',
      metaTitle: 'Alternative gratuite à Logi Options+ et Logitech G HUB sur macOS · Rebind',
      metaDescription:
        'Utilisez les souris Logitech MX Master et série G sur macOS sans 1 Go de Logi Options+ ni G HUB : HID++ 2.0 natif pour DPI, SmartShift, molette Hi-Res, bouton geste, batterie et défilement fluide.',
      headline: 'Utilisez vos souris Logitech sur Mac sans 1 Go de Logi Options+ ni G HUB.',
      subtitle:
        'Configurez vos souris Logitech MX Master et série G en HID++ 2.0 natif sur macOS : DPI, SmartShift, molette Hi-Res, bouton de geste, défilement fluide et batterie sans suite de 1 Go.',
      highlights: [
        {
          value: 'Zéro suite de 1 Go',
          label: 'App Swift 6 native · sans Electron, compte ni démon lourd',
        },
        {
          value: 'HID++ 2.0 natif',
          label: 'DPI, SmartShift, molette Hi-Res, bouton geste & batterie',
        },
        {
          value: 'Accessibilité seule',
          label: 'Sans Input Monitoring, sans suivi clavier, pause fail-open',
        },
      ],
      competitorColumn: 'LOGI OPTIONS+ / G HUB',
      rows: [
        {
          criterion: 'Taille & mémoire',
          rebind: 'Petite app Swift 6 native · faible RAM · MIT open source',
          other: 'Installateur ~1 Go + processus Electron et agents permanents',
        },
        {
          criterion: 'Comptes & télémétrie',
          rebind: 'Configs JSON 100 % locales, sans compte ni télémétrie',
          other: 'Invites de compte cloud, analytique & démons de mise à jour',
        },
        {
          criterion: 'Permissions & vie privée',
          rebind: 'Accessibilité seule, zéro Input Monitoring, zéro enregistrement',
          other: 'Demande Input Monitoring, Bluetooth et agents en arrière-plan',
        },
        {
          criterion: 'Contrôles Logitech HID++',
          rebind: 'DPI, SmartShift, molette Hi-Res, bouton geste, batterie & G915',
          other: 'Fonctions complètes constructeur + AI Prompt Builder & Flow',
        },
        {
          criterion: 'Défilement & fluidité',
          rebind: 'Sens V/H souris indépendant + glisse Gentle/Standard/Strong',
          other: 'Option basique perturbant souvent le trackpad',
        },
        {
          criterion: 'Au-delà de Logitech',
          rebind: 'Compatible toute souris, raccourcis clavier, fenêtres & profils',
          other: 'Limité aux périphériques Logitech',
        },
      ],
      chooseRebind: {
        label: 'RECOMMANDÉ AU QUOTIDIEN SUR MAC',
        title: 'Choisissez Rebind si…',
        points: [
          'Vous voulez DPI, SmartShift, bouton geste et batterie sans 1 Go de lourdeur',
          'Vous voulez défilement indépendant, lissage et boutons latéraux',
          'Vous préférez Accessibilité seule, zéro télémétrie et sauvegardes JSON',
        ],
      },
      stickWithOther: {
        label: 'QUAND LOGI OPTIONS+ / G HUB RESTE UTILE',
        title: 'Gardez le logiciel officiel si…',
        points: [
          'Vous utilisez Logitech Flow entre plusieurs ordinateurs',
          'Vous avez besoin de mises à jour firmware ou de macros RGB gaming',
          'Vous souhaitez remapper la molette pouce MX Master comme déclencheur',
        ],
      },
      steps: [
        {
          step: 'ÉTAPE 01',
          title: 'Quitter ou retirer Logi Options+ / G HUB',
          description:
            'Retirez les agents Logitech lourds pour éviter les conflits HID++. Rebind vous avertit automatiquement si l’un reste actif.',
        },
        {
          step: 'ÉTAPE 02',
          title: 'Installer Rebind & accorder Accessibilité',
          description:
            'Lancez brew install --cask blinks44/tap/rebind. Rebind démarre en pause sans règle et ne demande jamais Input Monitoring.',
        },
        {
          step: 'ÉTAPE 03',
          title: 'Régler HID++, défilement & Starter Setups',
          description:
            'Ajustez DPI, SmartShift et fluidité par souris, puis activez un Starter Setup hors ligne ou un profil par app.',
        },
      ],
    },
    steermouse: {
      slug: 'steermouse',
      path: '/alternatives/steermouse/',
      breadcrumbLabel: 'SteerMouse',
      metaTitle: 'Alternative gratuite à SteerMouse et Mac Mouse Fix (Open Source) · Rebind',
      metaDescription:
        'Comparez Rebind à SteerMouse et Mac Mouse Fix : app MIT gratuite en Swift 6 avec boutons 4/5+, gestes 4 directions, accords molette, Logitech HID++, clavier et fenêtres.',
      headline: 'Une alternative gratuite et open source à SteerMouse & Mac Mouse Fix.',
      subtitle:
        'Remappez boutons 4/5+, clic milieu, gestes 4 directions, accords molette, profils par app, contrôles Logitech HID++ et raccourcis clavier dans une app Swift MIT.',
      highlights: [
        {
          value: '100 % Gratuit · MIT',
          label: 'Sans licence payante par version majeure ni serveur d’activation',
        },
        {
          value: 'Souris + Clavier + Fenêtres',
          label: 'Boutons latéraux, accords, maintien clavier & disposition fenêtres',
        },
        {
          value: 'HID++ 2.0 natif',
          label: 'DPI, SmartShift et batterie en direct pour les souris Logitech',
        },
      ],
      competitorColumn: 'STEERMOUSE / MAC MOUSE FIX',
      rows: [
        {
          criterion: 'Licence & prix',
          rebind: '100 % gratuit et open source MIT sur GitHub',
          other: 'Licence payante (SteerMouse ~20 $ ; Mac Mouse Fix payant dès v3)',
        },
        {
          criterion: 'Boutons & gestes',
          rebind: 'Boutons 4/5+, clic milieu, gestes 4 directions & accords molette',
          other: 'Solides accords de boutons et gestes cliquer-glisser',
        },
        {
          criterion: 'Matériel Logitech HID++',
          rebind: 'DPI, SmartShift, molette Hi-Res, bouton geste & batterie inclus',
          other: 'Vitesse/accélération du curseur seulement (pas de SmartShift)',
        },
        {
          criterion: 'Clavier & fenêtres',
          rebind: 'Press/Double Press/Hold clavier, extraits & découpage d’écran',
          other: 'Utilitaires centrés uniquement sur la souris',
        },
        {
          criterion: 'Profils & sécurité',
          rebind: 'Règles par app, exclusion jeux/VM, pause fail-open ⌃⌥⇧⌘ Esc',
          other: 'Profils de boutons par application',
        },
        {
          criterion: 'Portabilité config',
          rebind: 'JSON lisible avec import/export & sauvegardes locales',
          other: 'Préférences binaires ou plist internes',
        },
      ],
      chooseRebind: {
        label: 'TOUT-EN-UN RECOMMANDÉ',
        title: 'Choisissez Rebind si…',
        points: [
          'Vous voulez un remappeur MIT gratuit avec gestes et accords molette',
          'Vous voulez aussi Logitech HID++, raccourcis clavier et fenêtres',
          'Vous préférez des profils JSON clairs avec aperçu des conflits',
        ],
      },
      stickWithOther: {
        label: 'QUAND STEERMOUSE / MMF RESTE UTILE',
        title: 'Gardez SteerMouse ou Mac Mouse Fix si…',
        points: [
          'Vous voulez des courbes d’accélération très fines (SteerMouse)',
          'Vous êtes sur macOS antérieur à 15 où Rebind ne tourne pas',
          'Vous avez déjà une licence et ne touchez qu’aux clics et au curseur',
        ],
      },
      steps: [
        {
          step: 'ÉTAPE 01',
          title: 'Installer via Homebrew ou DMG',
          description:
            'Lancez brew install --cask blinks44/tap/rebind et accordez Accessibilité seule. Démarre en pause.',
        },
        {
          step: 'ÉTAPE 02',
          title: 'Choisir un Starter Setup',
          description:
            'Prévisualisez les déclencheurs du preset Navigateur ou MX Master avant d’activer les règles.',
        },
        {
          step: 'ÉTAPE 03',
          title: 'Ajouter vos profils par app',
          description:
            'Assignez boutons 4/5 et accords molette pour navigateur, IDE et design, en excluant les jeux.',
        },
      ],
    },
    'linearmouse-mos': {
      slug: 'linearmouse-mos',
      path: '/alternatives/linearmouse-mos/',
      breadcrumbLabel: 'LinearMouse & Mos',
      metaTitle: 'Alternative à LinearMouse et Mos avec HID++ et boutons · Rebind',
      metaDescription:
        'Inversez le sens de la molette sans casser le trackpad du MacBook, ajoutez le lissage par souris et combinez avec Logitech HID++, boutons extra et fenêtres.',
      headline: 'Défilement indépendant & fluidité par souris, plus boutons et HID++.',
      subtitle:
        'Conservez le trackpad naturel tout en inversant la molette verticale ou horizontale, activez Gentle/Standard/Strong et remplacez les utilitaires séparés.',
      highlights: [
        {
          value: 'Trackpad préservé',
          label: 'La molette bascule proprement sans toucher au trackpad naturel',
        },
        {
          value: 'Lissage par souris',
          label: 'Modes Gentle, Standard ou Strong réglés par périphérique',
        },
        {
          value: 'Une icône dans la barre',
          label: 'Défilement, boutons extra, Logitech HID++ & fenêtres réunis',
        },
      ],
      competitorColumn: 'LINEARMOUSE / MOS',
      rows: [
        {
          criterion: 'Sens indépendant',
          rebind: 'Inversion V/H séparée par souris ; trackpad reste naturel',
          other: 'Direction séparée souris vs trackpad',
        },
        {
          criterion: 'Défilement fluide',
          rebind: 'Glisse Gentle, Standard ou Strong par souris',
          other: 'Mos pour la fluidité ; LinearMouse pour lignes et accélération',
        },
        {
          criterion: 'Boutons extra & gestes',
          rebind: 'Boutons 4/5+, clic milieu, gestes 4 directions & accords molette',
          other: 'Prise en charge basique précédent/suivant',
        },
        {
          criterion: 'Logitech HID++ 2.0',
          rebind: 'DPI, SmartShift, molette Hi-Res, bouton geste & batterie natifs',
          other: 'Non pris en charge (nécessite Logi Options+ ou une autre app)',
        },
        {
          criterion: 'Clavier & fenêtres',
          rebind: 'Remappage Press/Double Press/Hold et gestion de fenêtres intégrée',
          other: 'Défilement et pointeur uniquement',
        },
        {
          criterion: 'Permissions & format',
          rebind: 'Accessibilité seule, MIT Swift 6, JSON lisible avec sauvegardes',
          other: 'Permission Accessibilité ; open source',
        },
      ],
      chooseRebind: {
        label: 'STACK UNIQUE RECOMMANDÉ',
        title: 'Choisissez Rebind si…',
        points: [
          'Vous voulez sens indépendant ET défilement fluide dans une seule app',
          'Vous mappez aussi boutons latéraux, Logitech HID++, clavier ou fenêtres',
          'Vous évitez plusieurs hooks qui se disputent les événements souris',
        ],
      },
      stickWithOther: {
        label: 'QUAND LINEARMOUSE / MOS RESTE UTILE',
        title: 'Gardez LinearMouse ou Mos si…',
        points: [
          'Vous voulez précisément la courbe sans accélération de LinearMouse',
          'Vous êtes sous macOS 13 ou 14 (Rebind vise macOS 15+)',
          'Vous n’avez besoin que du lissage de molette sans boutons ni DPI',
        ],
      },
      steps: [
        {
          step: 'ÉTAPE 01',
          title: 'Couper les hooks concurrents',
          description:
            'Quittez Mos, Scroll Reverser ou LinearMouse pour éviter une double inversion de la molette.',
        },
        {
          step: 'ÉTAPE 02',
          title: 'Inverser la molette & choisir la glisse',
          description:
            'Sélectionnez votre souris dans Rebind, inversez V/H et choisissez Gentle, Standard ou Strong.',
        },
        {
          step: 'ÉTAPE 03',
          title: 'Ajouter boutons & exclusions',
          description:
            'Mappez boutons 4/5 ou zoom molette et excluez jeux plein écran ou bureau à distance.',
        },
      ],
    },
  },
  guides: {
    'mx-master-mac-setup': {
      slug: 'mx-master-mac-setup',
      path: '/guides/mx-master-mac-setup/',
      breadcrumbLabel: 'Configuration MX Master',
      metaTitle: 'Configurer Logitech MX Master & série G sur Mac sans Logi Options+ · Rebind',
      metaDescription:
        'Guide étape par étape pour configurer Logitech MX Master et série G sur macOS avec Rebind : HID++ 2.0 natif, DPI, SmartShift, bouton geste, défilement indépendant et fenêtres.',
      headline: 'Configurez MX Master & série G sur Mac sans suite lourde.',
      subtitle:
        'Profitez de DPI, SmartShift, molette Hi-Res, bouton de geste, défilement indépendant, fluidité et fenêtres sur Mac sans installer 1 Go de Logitech Options+ ou G HUB.',
      secondaryCtaLabel: 'Comparer à Logi Options+ & G HUB',
      secondaryCtaTo: '/alternatives/logi-options-ghub/',
      cardsTitle: 'Démarrez avec les Starter Setups hors ligne intégrés',
      cards: [
        {
          label: 'LOGITECH HID++ 2.0',
          title: 'Productivité MX Master',
          description: 'Tous les réglages clés du MX Master sans démon constructeur.',
          items: [
            'Curseur DPI + sensibilité SmartShift',
            'Bouton geste + glisser 4 directions',
            'Pourcentage de batterie dans la barre',
          ],
          footer: 'Starter Setup hors ligne intégré',
        },
        {
          label: 'NAVIGATEUR & DÉFILEMENT',
          title: 'Bases navigateur & souris',
          description: 'Trackpad naturel + molette classique + défilement fluide.',
          items: [
            'Bouton 4/5 -> Précédent / Suivant',
            'Clic milieu + Molette -> Zoom / Onglets',
            'Fluidité : Standard glide',
          ],
          footer: 'Fonctionne avec toute souris USB ou Bluetooth',
        },
        {
          label: 'FENÊTRES & CLAVIER',
          title: 'Gestion des fenêtres',
          description: 'Disposez vos fenêtres sur plusieurs écrans tout en excluant les jeux.',
          items: [
            'Moitiés · Quarts · Fill · Center',
            'Écran suivant & raccourcis Spaces',
            'Exclusions par app pour jeux & VM',
          ],
          footer: 'Aperçu des conflits avant activation',
        },
      ],
      stepsTitle: 'Quatre étapes pour un setup léger',
      steps: [
        {
          step: '01 · ACCESSIBILITÉ',
          title: 'Accorder une seule permission',
          description:
            'Installez Rebind et accordez Accessibilité seule. Démarre en pause sans règles ni Input Monitoring.',
        },
        {
          step: '02 · HID++',
          title: 'Régler DPI & défilement',
          description:
            'Ajustez DPI, SmartShift, molette Hi-Res, sens indépendant et glisse fluide par souris.',
        },
        {
          step: '03 · STARTER',
          title: 'Vérifier & activer',
          description:
            'Choisissez un Starter Setup hors ligne avec aperçu des conflits ou importez/exportez en JSON.',
        },
        {
          step: '04 · FAIL-OPEN',
          title: 'Mettre en pause à tout moment',
          description:
            'Appuyez sur ⌃⌥⇧⌘ Échap pour tout mettre en pause instantanément. En cas d’erreur, macOS reprend la main.',
        },
      ],
      pitfalls: [
        {
          title: 'Alerte si Logi Options+ tourne encore',
          description:
            'Deux pilotes HID++ provoquent doubles défilements et DPI bloqués. Rebind détecte Logi Options+ ou G HUB et prévient.',
        },
        {
          title: 'Le trackpad reste naturel',
          description:
            'Inverser la molette de la souris ne casse jamais le défilement naturel du MacBook ou du Magic Trackpad.',
        },
        {
          title: 'JSON clair avec sauvegardes rotatives',
          description:
            'Vos règles sont stockées dans ~/Library/Application Support/Rebind avec sauvegardes automatiques.',
        },
      ],
    },
  },
}
