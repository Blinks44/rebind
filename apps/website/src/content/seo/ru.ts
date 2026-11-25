import type { LocaleSeoContent } from './types'

export const ruSeoContent: LocaleSeoContent = {
  alternatives: {
    'logi-options-ghub': {
      slug: 'logi-options-ghub',
      path: '/alternatives/logi-options-ghub/',
      breadcrumbLabel: 'Logi Options+ и G HUB',
      metaTitle: 'Бесплатная альтернатива Logi Options+ и Logitech G HUB для macOS · Rebind',
      metaDescription:
        'Используйте мыши Logitech MX Master и G-серии на macOS без 1 ГБ Logi Options+ и G HUB: нативный HID++ 2.0 DPI, SmartShift, Hi-Res колесо, кнопка жестов, батарея и плавный скролл.',
      headline: 'Пользуйтесь мышами Logitech на Mac без 1 ГБ Logi Options+ и G HUB.',
      subtitle:
        'Настраивайте Logitech MX Master и G-серию напрямую по нативному HID++ 2.0 на macOS: DPI, SmartShift, колесо Hi-Res, кнопку жестов, плавный скролл и заряд в меню без фирменных пакетов на гигабайт.',
      highlights: [
        {
          value: 'Без 1 ГБ балласта',
          label: 'Нативное приложение Swift 6 · без Electron, аккаунтов и тяжелых демонов',
        },
        {
          value: 'Нативный HID++ 2.0',
          label: 'DPI, SmartShift, колесо Hi-Res, кнопка жестов и заряд в меню',
        },
        {
          value: 'Только Accessibility',
          label: 'Без Input Monitoring, без логирования клавиш, fail-open пауза',
        },
      ],
      competitorColumn: 'LOGI OPTIONS+ / G HUB',
      rows: [
        {
          criterion: 'Размер и память',
          rebind: 'Компактное Swift 6 приложение · минимум RAM · MIT open source',
          other: 'Установщик ~1 ГБ + постоянные процессы Electron и агенты',
        },
        {
          criterion: 'Аккаунты и телеметрия',
          rebind: '100% локальные JSON-конфиги, без аккаунтов и телеметрии',
          other: 'Запросы облачного аккаунта, аналитика и автообновляторы',
        },
        {
          criterion: 'Права и приватность',
          rebind: 'Только Accessibility, без Input Monitoring и перехвата ввода',
          other: 'Требует Input Monitoring, Bluetooth и фоновых агентов',
        },
        {
          criterion: 'Функции Logitech HID++',
          rebind: 'DPI, SmartShift, Hi-Res колесо, кнопка жестов, батарея и G915',
          other: 'Полный фирменный набор + AI Prompt Builder и Flow',
        },
        {
          criterion: 'Скролл и плавность',
          rebind: 'Независимый V/H скролл мыши + плавность Gentle / Standard / Strong',
          other: 'Базовый переключатель; часто сбивает поведение трекпада',
        },
        {
          criterion: 'Не только Logitech',
          rebind: 'Работает с любой мышью, хоткеями, раскладкой окон и профилями',
          other: 'Привязка только к устройствам Logitech',
        },
      ],
      chooseRebind: {
        label: 'РЕКОМЕНДУЕТСЯ ДЛЯ ПОВСЕДНЕВНОЙ РАБОТЫ',
        title: 'Выбирайте Rebind, если…',
        points: [
          'Нужны DPI, SmartShift, кнопка жестов и заряд батареи без пакета на 1 ГБ',
          'Нужны независимый скролл мыши, плавная прокрутка и боковые кнопки',
          'Важны только права Accessibility, ноль телеметрии и локальные JSON-бэкапы',
        ],
      },
      stickWithOther: {
        label: 'КОГДА LOGI OPTIONS+ / G HUB ВСЕ ЕЩЕ НУЖЕН',
        title: 'Оставьте фирменное ПО, если…',
        points: [
          'Вы пользуетесь Logitech Flow для переноса буфера между компьютерами',
          'Нужны обновления прошивки или поканальная RGB-подсветка с макросами',
          'Нужно назначать боковое колесо MX Master как отдельный триггер',
        ],
      },
      steps: [
        {
          step: 'ШАГ 01',
          title: 'Закройте или удалите Logi Options+ / G HUB',
          description:
            'Уберите тяжелые фоновые агенты Logitech, чтобы они не конфликтовали за пакеты HID++. Rebind сам предупредит, если драйвер еще активен.',
        },
        {
          step: 'ШАГ 02',
          title: 'Установите Rebind и выдайте Accessibility',
          description:
            'Выполните brew install --cask blinks44/tap/rebind. Rebind запускается на паузе без правил и не просит Input Monitoring.',
        },
        {
          step: 'ШАГ 03',
          title: 'Настройте HID++, скролл и Starter Setups',
          description:
            'Выставьте DPI, SmartShift и плавность прокрутки, затем включите готовый Starter Setup или профиль под нужные приложения.',
        },
      ],
    },
    steermouse: {
      slug: 'steermouse',
      path: '/alternatives/steermouse/',
      breadcrumbLabel: 'SteerMouse',
      metaTitle: 'Бесплатная альтернатива SteerMouse и Mac Mouse Fix (Open Source) · Rebind',
      metaDescription:
        'Сравнение Rebind со SteerMouse и Mac Mouse Fix: бесплатное Swift 6 приложение под MIT с кнопками 4/5+, 4-сторонними жестами, аккордами с колесом, Logitech HID++ и раскладкой окон.',
      headline: 'Бесплатная open-source альтернатива SteerMouse и Mac Mouse Fix.',
      subtitle:
        'Назначайте кнопки 4/5+, среднюю кнопку, 4-сторонние жесты «кнопка + движение», аккорды с колесом, профили по приложениям, Logitech HID++ и хоткеи в одном MIT Swift-приложении.',
      highlights: [
        {
          value: '100% бесплатно · MIT',
          label: 'Без платной лицензии на каждую версию и серверов активации',
        },
        {
          value: 'Мышь + Клавиши + Окна',
          label: 'Боковые кнопки, аккорды, Hold-триггеры клавиш и раскладка окон',
        },
        {
          value: 'Нативный HID++ 2.0',
          label: 'Слайдер DPI, SmartShift и заряд батареи для мышей Logitech',
        },
      ],
      competitorColumn: 'STEERMOUSE / MAC MOUSE FIX',
      rows: [
        {
          criterion: 'Лицензия и цена',
          rebind: '100% бесплатно и MIT open source на GitHub',
          other: 'Платная лицензия (SteerMouse ~$20; Mac Mouse Fix платный с v3)',
        },
        {
          criterion: 'Кнопки и жесты',
          rebind: 'Кнопки 4/5+, средняя кнопка, 4-сторонние жесты и аккорды с колесом',
          other: 'Сильные аккорды кнопок и жесты перетаскивания',
        },
        {
          criterion: 'Аппаратный Logitech HID++',
          rebind: 'Встроенный DPI, SmartShift, Hi-Res колесо, кнопка жестов и батарея',
          other: 'Только скорость и ускорение курсора (без SmartShift и батареи HID++)',
        },
        {
          criterion: 'Клавиатура и окна',
          rebind: 'Press/Double Press/Hold для клавиш, сниппеты и раскладка окон',
          other: 'Утилиты только для мыши',
        },
        {
          criterion: 'Профили и безопасность',
          rebind: 'Правила по приложениям, исключение игр/VM, пауза ⌃⌥⇧⌘ Esc',
          other: 'Профили кнопок мыши по приложениям',
        },
        {
          criterion: 'Переносимость конфига',
          rebind: 'Читаемый JSON с экспортом/импортом и скользящими бэкапами',
          other: 'Бинарные или plist-настройки внутри системы',
        },
      ],
      chooseRebind: {
        label: 'РЕКОМЕНДУЕТСЯ КАК ЕДИНЫЙ ИНСТРУМЕНТ',
        title: 'Выбирайте Rebind, если…',
        points: [
          'Нужен бесплатный MIT-ремаппер кнопок мыши с жестами и аккордами колеса',
          'Нужны еще и Logitech HID++ (DPI/SmartShift), хоткеи и раскладка окон',
          'Хотите понятные JSON-профили с предпросмотром конфликтов перед включением',
        ],
      },
      stickWithOther: {
        label: 'КОГДА STEERMOUSE / MMF ВСЕ ЕЩЕ ПОДХОДИТ',
        title: 'Оставайтесь на SteerMouse или Mac Mouse Fix, если…',
        points: [
          'Нужны тонкие кастомные кривые ускорения курсора (SteerMouse)',
          'Вы на более старой macOS (< 15), где Rebind не поддерживается',
          'Лицензия уже куплена и вам нужна только базовая настройка кликов',
        ],
      },
      steps: [
        {
          step: 'ШАГ 01',
          title: 'Установите через Homebrew или DMG',
          description:
            'Выполните brew install --cask blinks44/tap/rebind и выдайте только Accessibility. Приложение стартует на паузе.',
        },
        {
          step: 'ШАГ 02',
          title: 'Выберите готовый Starter Setup',
          description:
            'Посмотрите список триггеров в пресетах Mouse & Browser или MX Master перед применением правил.',
        },
        {
          step: 'ШАГ 03',
          title: 'Добавьте профили для приложений',
          description:
            'Настройте кнопки 4/5 и аккорды колеса отдельно для браузера, IDE и Figma, а игры добавьте в исключения.',
        },
      ],
    },
    'linearmouse-mos': {
      slug: 'linearmouse-mos',
      path: '/alternatives/linearmouse-mos/',
      breadcrumbLabel: 'LinearMouse и Mos',
      metaTitle: 'Альтернатива LinearMouse и Mos с HID++ и кнопками · Rebind',
      metaDescription:
        'Инвертируйте скролл мыши отдельно от трекпада MacBook, включите плавную прокрутку по устройствам и объедините все с Logitech HID++, кнопками и раскладкой окон в одном Swift-приложении.',
      headline: 'Независимый скролл и плавность мыши, плюс кнопки и HID++.',
      subtitle:
        'Оставьте естественный скролл на трекпаде, разверните колесо внешней мыши по вертикали или горизонтали, настройте плавность Gentle / Standard / Strong и откажитесь от лишних утилит.',
      highlights: [
        {
          value: 'Трекпад не затронут',
          label: 'Колесо мыши разворачивается отдельно, трекпад остается естественным',
        },
        {
          value: 'Плавность по мышам',
          label: 'Режимы Gentle, Standard и Strong настраиваются на каждое устройство',
        },
        {
          value: 'Одна иконка в меню',
          label: 'Скролл, боковые кнопки, Logitech HID++ и раскладка окон вместе',
        },
      ],
      competitorColumn: 'LINEARMOUSE / MOS',
      rows: [
        {
          criterion: 'Независимый скролл',
          rebind: 'Раздельный V/H разворот для каждой мыши; трекпад остается естественным',
          other: 'Раздельное направление скролла мыши и трекпада',
        },
        {
          criterion: 'Плавная прокрутка',
          rebind: 'Режимы Gentle, Standard или Strong для каждой внешней мыши',
          other: 'Mos отвечает за плавность; LinearMouse - за шаги и ускорение',
        },
        {
          criterion: 'Боковые кнопки и жесты',
          rebind: 'Кнопки 4/5+, средняя кнопка, 4-сторонние жесты и аккорды с колесом',
          other: 'Только базовые кнопки «Назад/Вперед»',
        },
        {
          criterion: 'Logitech HID++ 2.0',
          rebind: 'Нативный DPI, SmartShift, Hi-Res колесо, кнопка жестов и заряд батареи',
          other: 'Не поддерживается (нужен Logi Options+ или отдельная утилита)',
        },
        {
          criterion: 'Клавиатура и окна',
          rebind: 'Press/Double Press/Hold для клавиш и встроенная раскладка окон',
          other: 'Только скролл и указатель мыши',
        },
        {
          criterion: 'Права и формат',
          rebind: 'Только Accessibility, MIT Swift 6, читаемый JSON с бэкапами',
          other: 'Доступ Accessibility; открытый код',
        },
      ],
      chooseRebind: {
        label: 'РЕКОМЕНДУЕТСЯ ДЛЯ ЧИСТОГО СТЕКА',
        title: 'Выбирайте Rebind, если…',
        points: [
          'Нужны одновременно независимый скролл И плавная прокрутка в одном приложении',
          'Нужны еще и боковые кнопки, Logitech HID++, хоткеи или раскладка окон',
          'Хотите убрать несколько конфликтующих перехватчиков ввода в фоне',
        ],
      },
      stickWithOther: {
        label: 'КОГДА LINEARMOUSE / MOS ВСЕ ЕЩЕ ПОДХОДИТ',
        title: 'Оставайтесь на LinearMouse или Mos, если…',
        points: [
          'Вам нужна именно тонкая кривая отключения ускорения курсора в LinearMouse',
          'Вы работаете на macOS 13 или 14 (Rebind требует macOS 15+)',
          'Вам нужна только плавность скролла без кнопок и настроек Logitech DPI',
        ],
      },
      steps: [
        {
          step: 'ШАГ 01',
          title: 'Отключите пересекающиеся утилиты скролла',
          description:
            'Закройте Mos, Scroll Reverser или LinearMouse, чтобы два перехватчика не инвертировали колесо дважды.',
        },
        {
          step: 'ШАГ 02',
          title: 'Разверните колесо и выберите плавность',
          description:
            'Выберите внешнюю мышь в Rebind, переключите V/H направление и выберите Gentle, Standard или Strong.',
        },
        {
          step: 'ШАГ 03',
          title: 'Настройте кнопки и исключения',
          description:
            'Назначьте кнопки 4/5 или зум колесом и добавьте полноэкранные игры или удаленный рабочий стол в исключения.',
        },
      ],
    },
  },
  guides: {
    'mx-master-mac-setup': {
      slug: 'mx-master-mac-setup',
      path: '/guides/mx-master-mac-setup/',
      breadcrumbLabel: 'Настройка MX Master',
      metaTitle: 'Настройка Logitech MX Master и G-серии на Mac без Logi Options+ · Rebind',
      metaDescription:
        'Пошаговая настройка Logitech MX Master и G-серии на macOS с Rebind: нативный HID++ 2.0 DPI, SmartShift, кнопка жестов, независимый скролл и раскладка окон без 1 ГБ пакета.',
      headline: 'Настройте MX Master и G-серию на Mac без 1 ГБ фирменного ПО.',
      subtitle:
        'Получите DPI, SmartShift, колесо Hi-Res, кнопку жестов, независимый скролл, плавность и раскладку окон на Mac без установки 1 ГБ Logitech Options+ или G HUB.',
      secondaryCtaLabel: 'Сравнить с Logi Options+ и G HUB',
      secondaryCtaTo: '/alternatives/logi-options-ghub/',
      cardsTitle: 'Начните со встроенных офлайн-пресетов Starter Setups',
      cards: [
        {
          label: 'LOGITECH HID++ 2.0',
          title: 'MX Master для работы',
          description: 'Все ключевые функции MX Master без фоновых демонов производителя.',
          items: [
            'Слайдер DPI + порог SmartShift',
            'Кнопка жестов + 4-стороннее движение',
            'Процент заряда в строке меню',
          ],
          footer: 'Встроенный офлайн Starter Setup',
        },
        {
          label: 'БРАУЗЕР И СКРОЛЛ',
          title: 'База для браузера и мыши',
          description: 'Естественный трекпад + привычное колесо мыши + плавный скролл.',
          items: [
            'Кнопки 4/5 -> Назад / Вперед',
            'Средняя + колесо -> Зум / Вкладки',
            'Плавная прокрутка: Standard',
          ],
          footer: 'Работает с любой USB и Bluetooth-мышью',
        },
        {
          label: 'ОКНА И КЛАВИАТУРА',
          title: 'Управление окнами',
          description: 'Раскладывайте окна по мониторам, не мешая играм и виртуальным машинам.',
          items: [
            'Половины · Четверти · Fill · Center',
            'Перенос между дисплеями и Spaces',
            'Исключения по приложениям для игр и VM',
          ],
          footer: 'Предпросмотр конфликтов до включения',
        },
      ],
      stepsTitle: 'Четыре шага к чистой настройке мыши',
      steps: [
        {
          step: '01 · ACCESSIBILITY',
          title: 'Выдайте одно разрешение',
          description:
            'Установите Rebind и разрешите только Accessibility. Старт на паузе без правил - Input Monitoring не нужен.',
        },
        {
          step: '02 · HID++',
          title: 'Настройте DPI и скролл',
          description:
            'Задайте DPI, SmartShift, Hi-Res колесо, независимое направление скролла и плавность для каждой мыши.',
        },
        {
          step: '03 · ПРЕСЕТЫ',
          title: 'Проверьте и включите',
          description:
            'Выберите офлайн Starter Setup с проверкой конфликтов или импортируйте готовый JSON-профиль.',
        },
        {
          step: '04 · FAIL-OPEN',
          title: 'Пауза в любой момент',
          description:
            'Нажмите ⌃⌥⇧⌘ Esc, чтобы мгновенно поставить правила на паузу. При сбое ввод возвращается к штатному macOS.',
        },
      ],
      pitfalls: [
        {
          title: 'Предупреждает о запущенном Logi Options+',
          description:
            'Два HID++ драйвера одновременно вызывают двойной скролл и сброс DPI. Rebind находит Logi Options+ или G HUB и предупреждает.',
        },
        {
          title: 'Трекпад остается естественным',
          description:
            'Разворот колеса внешней мыши никогда не ломает естественную прокрутку на MacBook Trackpad или Magic Trackpad.',
        },
        {
          title: 'Обычный JSON со скользящими бэкапами',
          description:
            'Правила и профили хранятся в ~/Library/Application Support/Rebind с автобэкапами и простым переносом.',
        },
      ],
    },
  },
}
