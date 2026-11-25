import type { LocaleSeoContent } from './types'

export const esSeoContent: LocaleSeoContent = {
  alternatives: {
    'logi-options-ghub': {
      slug: 'logi-options-ghub',
      path: '/alternatives/logi-options-ghub/',
      breadcrumbLabel: 'Logi Options+ y G HUB',
      metaTitle: 'Alternativa gratuita a Logi Options+ y Logitech G HUB en macOS · Rebind',
      metaDescription:
        'Usa ratones Logitech MX Master y serie G en macOS sin 1 GB de Logi Options+ ni G HUB: HID++ 2.0 nativo para DPI, SmartShift, rueda Hi-Res, botón de gestos, batería y scroll suave.',
      headline: 'Usa ratones Logitech en Mac sin 1 GB de Logi Options+ ni G HUB.',
      subtitle:
        'Configura Logitech MX Master y serie G directamente por HID++ 2.0 nativo en macOS: DPI, SmartShift, rueda Hi-Res, botón de gestos, scroll suave y batería sin paquetes de 1 GB.',
      highlights: [
        {
          value: 'Cero lastre de 1 GB',
          label: 'App nativa Swift 6 · sin Electron, cuentas ni demonios pesados',
        },
        {
          value: 'HID++ 2.0 nativo',
          label: 'DPI, SmartShift, rueda Hi-Res, botón de gestos y batería en vivo',
        },
        {
          value: 'Solo Accesibilidad',
          label: 'Sin Input Monitoring, sin registro de teclas, pausa fail-open',
        },
      ],
      competitorColumn: 'LOGI OPTIONS+ / G HUB',
      rows: [
        {
          criterion: 'Tamaño y memoria',
          rebind: 'App nativa ligera en Swift 6 · bajo uso de RAM · MIT open source',
          other: 'Instalador de ~1 GB + procesos Electron y agentes persistentes',
        },
        {
          criterion: 'Cuentas y telemetría',
          rebind: 'Configs JSON 100 % locales, sin cuentas ni telemetría',
          other: 'Avisos de cuenta en la nube, analíticas y autoactualizadores',
        },
        {
          criterion: 'Permisos y privacidad',
          rebind: 'Solo Accesibilidad, cero Input Monitoring, cero registro de teclas',
          other: 'Pide Input Monitoring, Bluetooth y agentes en segundo plano',
        },
        {
          criterion: 'Controles Logitech HID++',
          rebind: 'DPI, SmartShift, rueda Hi-Res, botón de gestos, batería y G915',
          other: 'Suite completa del fabricante + AI Prompt Builder y Flow',
        },
        {
          criterion: 'Scroll y suavidad',
          rebind: 'Scroll V/H independiente + suavidad Gentle/Standard/Strong',
          other: 'Ajuste básico que suele romper la coherencia del trackpad',
        },
        {
          criterion: 'Más allá de Logitech',
          rebind: 'Sirve para cualquier ratón, atajos de teclado, ventanas y perfiles',
          other: 'Limitado solo a dispositivos Logitech',
        },
      ],
      chooseRebind: {
        label: 'RECOMENDADO PARA USO DIARIO EN MAC',
        title: 'Elige Rebind cuando…',
        points: [
          'Quieres DPI, SmartShift, botón de gestos y batería sin 1 GB de software',
          'Quieres scroll de ratón independiente, suavidad y botones extra',
          'Prefieres solo Accesibilidad, cero telemetría y copias JSON locales',
        ],
      },
      stickWithOther: {
        label: 'CUÁNDO LOGI OPTIONS+ / G HUB SIGUE ENCAJANDO',
        title: 'Conserva el software oficial cuando…',
        points: [
          'Dependes de Logitech Flow para portapapeles entre ordenadores',
          'Necesitas actualizar firmware o macros RGB por tecla en periféricos gaming',
          'Quieres usar la rueda de pulgar MX Master como disparador',
        ],
      },
      steps: [
        {
          step: 'PASO 01',
          title: 'Cierra o desinstala Logi Options+ / G HUB',
          description:
            'Retira los agentes pesados de Logitech para evitar conflictos HID++. Rebind avisa automáticamente si alguno sigue activo.',
        },
        {
          step: 'PASO 02',
          title: 'Instala Rebind y concede Accesibilidad',
          description:
            'Ejecuta brew install --cask blinks44/tap/rebind. Empieza en pausa sin reglas y nunca pide Input Monitoring.',
        },
        {
          step: 'PASO 03',
          title: 'Ajusta HID++, scroll y Starter Setups',
          description:
            'Configura DPI, SmartShift y scroll suave por ratón, luego activa un Starter Setup o perfil por app.',
        },
      ],
    },
    steermouse: {
      slug: 'steermouse',
      path: '/alternatives/steermouse/',
      breadcrumbLabel: 'SteerMouse',
      metaTitle: 'Alternativa gratuita a SteerMouse y Mac Mouse Fix (Open Source) · Rebind',
      metaDescription:
        'Compara Rebind con SteerMouse y Mac Mouse Fix: app MIT gratuita en Swift 6 con botón 4/5+, gestos de 4 direcciones, acordes de rueda, Logitech HID++, teclado y ventanas.',
      headline: 'Una alternativa gratuita y open source a SteerMouse y Mac Mouse Fix.',
      subtitle:
        'Remapea botones 4/5+, clic central, gestos de 4 direcciones, acordes de rueda, perfiles por app, controles Logitech HID++ y atajos de teclado en una app Swift bajo MIT.',
      highlights: [
        {
          value: '100 % Gratis · MIT',
          label: 'Sin licencias de pago por versión ni servidores de activación',
        },
        {
          value: 'Ratón + Teclas + Ventanas',
          label: 'Botones laterales, acordes, Hold en teclas y mosaico de ventanas',
        },
        {
          value: 'HID++ 2.0 nativo',
          label: 'DPI, SmartShift y batería en vivo para ratones Logitech',
        },
      ],
      competitorColumn: 'STEERMOUSE / MAC MOUSE FIX',
      rows: [
        {
          criterion: 'Licencia y coste',
          rebind: '100 % gratis y MIT open source en GitHub',
          other: 'Licencia de pago (SteerMouse ~$20; Mac Mouse Fix de pago desde v3)',
        },
        {
          criterion: 'Botones y gestos',
          rebind: 'Botón 4/5+, clic central, gestos 4 direcciones y acordes de rueda',
          other: 'Buenos acordes de botones y gestos de clic y arrastre',
        },
        {
          criterion: 'Hardware Logitech HID++',
          rebind: 'DPI, SmartShift, rueda Hi-Res, botón de gestos y batería incluidos',
          other: 'Solo sensibilidad/aceleración de puntero (sin SmartShift ni batería)',
        },
        {
          criterion: 'Teclado y ventanas',
          rebind: 'Press/Double Press/Hold en teclas, fragmentos y ventanas en mosaico',
          other: 'Utilidades enfocadas solo en el ratón',
        },
        {
          criterion: 'Perfiles y seguridad',
          rebind: 'Reglas por app, exclusión de juegos/VM, pausa ⌃⌥⇧⌘ Esc',
          other: 'Perfiles de botones de ratón por app',
        },
        {
          criterion: 'Portabilidad de config',
          rebind: 'JSON legible con exportar/importar y copias locales automáticas',
          other: 'Preferencias binarias o plist gestionadas por la app',
        },
      ],
      chooseRebind: {
        label: 'RECOMENDADO TODO EN UNO',
        title: 'Elige Rebind cuando…',
        points: [
          'Buscas un remapeador MIT gratuito con gestos de arrastre y acordes de rueda',
          'También quieres Logitech HID++, atajos de teclado y mosaico de ventanas',
          'Prefieres perfiles JSON claros con vista previa de conflictos',
        ],
      },
      stickWithOther: {
        label: 'CUÁNDO STEERMOUSE / MMF SIGUE ENCAJANDO',
        title: 'Quédate con SteerMouse o Mac Mouse Fix cuando…',
        points: [
          'Necesitas curvas de aceleración del cursor muy específicas (SteerMouse)',
          'Usas una versión anterior de macOS (< 15) donde Rebind no corre',
          'Ya tienes licencia y solo ajustas velocidad de puntero y clics',
        ],
      },
      steps: [
        {
          step: 'PASO 01',
          title: 'Instala con Homebrew o DMG',
          description:
            'Ejecuta brew install --cask blinks44/tap/rebind y concede solo Accesibilidad. Inicia en pausa.',
        },
        {
          step: 'PASO 02',
          title: 'Elige un Starter Setup',
          description:
            'Revisa los disparadores del Starter Setup de Navegador o MX Master antes de activar nada.',
        },
        {
          step: 'PASO 03',
          title: 'Añade perfiles por aplicación',
          description:
            'Asigna botones 4/5 y acordes de rueda para tu navegador, IDE y diseño, y excluye juegos.',
        },
      ],
    },
    'linearmouse-mos': {
      slug: 'linearmouse-mos',
      path: '/alternatives/linearmouse-mos/',
      breadcrumbLabel: 'LinearMouse y Mos',
      metaTitle: 'Alternativa a LinearMouse y Mos con HID++ y botones · Rebind',
      metaDescription:
        'Invierte el scroll del ratón sin tocar el trackpad del MacBook, añade suavidad por ratón y unifícalo con Logitech HID++, botones extra y mosaico de ventanas.',
      headline: 'Scroll independiente y suavidad por ratón, más botones y HID++.',
      subtitle:
        'Mantén el trackpad natural mientras inviertes la rueda vertical u horizontal de tu ratón, añade suavidad Gentle/Standard/Strong y jubila utilidades sueltas.',
      highlights: [
        {
          value: 'Trackpad intacto',
          label: 'La rueda del ratón se invierte sin alterar el trackpad natural',
        },
        {
          value: 'Suavidad por ratón',
          label: 'Modos Gentle, Standard o Strong ajustados por dispositivo',
        },
        {
          value: 'Un solo icono',
          label: 'Reúne scroll, botones extra, Logitech HID++ y ventanas',
        },
      ],
      competitorColumn: 'LINEARMOUSE / MOS',
      rows: [
        {
          criterion: 'Dirección independiente',
          rebind: 'Inversión V/H independiente por ratón; trackpad sigue natural',
          other: 'Dirección separada entre ratón y trackpad',
        },
        {
          criterion: 'Scroll suave',
          rebind: 'Suavidad Gentle, Standard o Strong por cada ratón',
          other: 'Mos destaca en suavidad; LinearMouse en líneas y aceleración',
        },
        {
          criterion: 'Botones extra y gestos',
          rebind: 'Botón 4/5+, clic central, gestos 4 direcciones y acordes de rueda',
          other: 'Solo soporte básico para botones atrás/adelante',
        },
        {
          criterion: 'Logitech HID++ 2.0',
          rebind: 'DPI, SmartShift, rueda Hi-Res, botón de gestos y batería nativos',
          other: 'No soportado (requiere Logi Options+ u otra app)',
        },
        {
          criterion: 'Teclado y ventanas',
          rebind: 'Remapeo Press/Double Press/Hold y mosaico de ventanas integrado',
          other: 'Solo scroll y puntero de ratón',
        },
        {
          criterion: 'Permisos y formato',
          rebind: 'Solo Accesibilidad, MIT Swift 6, JSON legible con copias',
          other: 'Permiso de Accesibilidad; código abierto',
        },
      ],
      chooseRebind: {
        label: 'STACK ÚNICO RECOMENDADO',
        title: 'Elige Rebind cuando…',
        points: [
          'Quieres dirección independiente Y scroll suave en una sola app',
          'También mapeas botones laterales, Logitech HID++, teclas o ventanas',
          'Quieres evitar varios hooks compitiendo por los mismos eventos',
        ],
      },
      stickWithOther: {
        label: 'CUÁNDO LINEARMOUSE / MOS SIGUE ENCAJANDO',
        title: 'Quédate con LinearMouse o Mos cuando…',
        points: [
          'Necesitas específicamente la curva sin aceleración de LinearMouse',
          'Estás en macOS 13 o 14 (Rebind requiere macOS 15+)',
          'Solo buscas suavizar el scroll sin botones ni controles Logitech',
        ],
      },
      steps: [
        {
          step: 'PASO 01',
          title: 'Cierra hooks de scroll solapados',
          description:
            'Cierra Mos, Scroll Reverser o LinearMouse para que dos apps no inviertan la rueda dos veces.',
        },
        {
          step: 'PASO 02',
          title: 'Invierte el scroll y elige suavidad',
          description:
            'Selecciona tu ratón en Rebind, invierte V/H y elige Gentle, Standard o Strong.',
        },
        {
          step: 'PASO 03',
          title: 'Añade botones y exclusiones',
          description:
            'Mapea botones 4/5 o acordes de zoom y excluye juegos a pantalla completa o escritorio remoto.',
        },
      ],
    },
  },
  guides: {
    'mx-master-mac-setup': {
      slug: 'mx-master-mac-setup',
      path: '/guides/mx-master-mac-setup/',
      breadcrumbLabel: 'Guía MX Master',
      metaTitle: 'Configurar Logitech MX Master y serie G en Mac sin Logi Options+ · Rebind',
      metaDescription:
        'Guía paso a paso para configurar Logitech MX Master y serie G en macOS con Rebind: HID++ 2.0 nativo, DPI, SmartShift, botón de gestos, scroll independiente y ventanas.',
      headline: 'Configura MX Master y serie G en Mac sin software pesado.',
      subtitle:
        'Consigue DPI, SmartShift, rueda Hi-Res, botón de gestos, scroll independiente, suavidad y mosaico de ventanas en Mac sin instalar 1 GB de Logitech Options+ o G HUB.',
      secondaryCtaLabel: 'Comparar con Logi Options+ y G HUB',
      secondaryCtaTo: '/alternatives/logi-options-ghub/',
      cardsTitle: 'Empieza con Starter Setups offline integrados',
      cards: [
        {
          label: 'LOGITECH HID++ 2.0',
          title: 'Productividad MX Master',
          description: 'Cada control clave del MX Master sin demonios del fabricante.',
          items: [
            'Deslizador DPI + sensibilidad SmartShift',
            'Botón de gestos + arrastre 4 direcciones',
            'Porcentaje de batería en la barra de menú',
          ],
          footer: 'Starter Setup offline integrado',
        },
        {
          label: 'NAVEGADOR Y SCROLL',
          title: 'Básicos de navegador y ratón',
          description: 'Trackpad natural + rueda clásica + desplazamiento suave.',
          items: [
            'Botón 4/5 -> Atrás / Adelante',
            'Clic central + Rueda -> Zoom / Pestañas',
            'Scroll suave: Standard glide',
          ],
          footer: 'Funciona con cualquier ratón USB o Bluetooth',
        },
        {
          label: 'VENTANAS Y TECLADO',
          title: 'Gestión de ventanas',
          description: 'Organiza ventanas entre pantallas excluyendo juegos limpiamente.',
          items: [
            'Mitades · Cuartos · Fill · Center',
            'Siguiente pantalla y atajos de Spaces',
            'Exclusiones por app para juegos y VMs',
          ],
          footer: 'Vista previa de conflictos antes de activar',
        },
      ],
      stepsTitle: 'Cuatro pasos para una configuración limpia',
      steps: [
        {
          step: '01 · ACCESIBILIDAD',
          title: 'Concede un solo permiso',
          description:
            'Instala Rebind y concede solo Accesibilidad. Inicia pausado sin reglas y sin Input Monitoring.',
        },
        {
          step: '02 · HID++',
          title: 'Ajusta DPI y scroll',
          description:
            'Configura DPI, SmartShift, rueda Hi-Res, dirección independiente y suavidad por ratón.',
        },
        {
          step: '03 · STARTER',
          title: 'Revisa y activa',
          description:
            'Elige un Starter Setup offline con vista previa de conflictos o importa/exporta perfiles JSON.',
        },
        {
          step: '04 · FAIL-OPEN',
          title: 'Pausa cuando quieras',
          description:
            'Pulsa ⌃⌥⇧⌘ Escape en cualquier momento para pausar todo. Cualquier error vuelve a la entrada normal de macOS.',
        },
      ],
      pitfalls: [
        {
          title: 'Avisa si Logi Options+ está activo',
          description:
            'Ejecutar dos controladores HID++ causa saltos de scroll y DPI bloqueado. Rebind detecta Logi Options+ o G HUB y te avisa.',
        },
        {
          title: 'El trackpad sigue natural',
          description:
            'Invertir la rueda del ratón nunca rompe el desplazamiento natural del trackpad del MacBook o Magic Trackpad.',
        },
        {
          title: 'JSON plano con copias automáticas',
          description:
            'Tus reglas viven en ~/Library/Application Support/Rebind con copias rotativas y sincronización sencilla.',
        },
      ],
    },
  },
}
