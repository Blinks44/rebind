import type { LocaleSeoContent } from './types'

export const zhHansSeoContent: LocaleSeoContent = {
  alternatives: {
    'logi-options-ghub': {
      slug: 'logi-options-ghub',
      path: '/alternatives/logi-options-ghub/',
      breadcrumbLabel: 'Logi Options+ & G HUB',
      metaTitle: '免费的 macOS Logi Options+ 与 Logitech G HUB 替代方案 · Rebind',
      metaDescription:
        '无需安装约 1 GB 的 Logi Options+ 或 G HUB，在 macOS 上通过原生 HID++ 2.0 控制罗技 MX Master 与 G 系列鼠标：DPI、SmartShift、高分滚轮、手势键、电量与平滑滚动。',
      headline: '在 Mac 上使用罗技鼠标，无需 1 GB 的 Logi Options+ 或 G HUB。',
      subtitle:
        '通过原生 HID++ 2.0 在 macOS 上直接配置 Logitech MX Master 与 G 系列鼠标：DPI、SmartShift、高分辨率滚轮、手势键、平滑滚动与实时电量，告别 1 GB 厂商套件。',
      highlights: [
        {
          value: '告别 1 GB 臃肿套件',
          label: '原生 Swift 6 应用 · 无 Electron、无账号、无常驻后台守护进程',
        },
        {
          value: '原生 HID++ 2.0',
          label: 'DPI、SmartShift、高分辨率滚轮、手势键与菜单栏实时电量',
        },
        {
          value: '仅需辅助功能',
          label: '无需输入监控，不记录击键，故障开放式一键暂停',
        },
      ],
      competitorColumn: 'LOGI OPTIONS+ / G HUB',
      rows: [
        {
          criterion: '体积与内存',
          rebind: '轻量原生 Swift 6 应用 · 低内存占用 · MIT 开源',
          other: '约 1 GB 安装包 + 常驻 Electron 与多个后台进程',
        },
        {
          criterion: '账号与遥测',
          rebind: '100% 本地 JSON 配置，无需账号，零遥测上报',
          other: '云账号弹窗、使用统计与自动更新守护进程',
        },
        {
          criterion: '权限与隐私',
          rebind: '仅需辅助功能权限，无需输入监控，绝不记录击键',
          other: '需要输入监控、蓝牙与常驻后台代理',
        },
        {
          criterion: '罗技 HID++ 控制',
          rebind: 'DPI、SmartShift、高分滚轮、手势键、电量与 G915 灯光',
          other: '完整厂商功能 + AI Prompt Builder 与 Flow',
        },
        {
          criterion: '滚动与平滑手感',
          rebind: '独立鼠标垂直/水平滚动 + 柔和/标准/强劲三档平滑滚动',
          other: '基础开关，常与触控板自然滚动冲突',
        },
        {
          criterion: '不止于罗技',
          rebind: '支持任意鼠标、键盘快捷键、窗口平铺与应用配置',
          other: '仅限罗技品牌设备',
        },
      ],
      chooseRebind: {
        label: '推荐用于日常 MAC 办公与开发',
        title: '选择 Rebind 的场景…',
        points: [
          '想要 DPI、SmartShift、手势键和电量显示，但不想装 1 GB 套件',
          '同时需要独立鼠标滚动、平滑滚动和自定义侧键',
          '偏好仅辅助功能权限、零遥测和本地 JSON 备份',
        ],
      },
      stickWithOther: {
        label: '仍适合 LOGI OPTIONS+ / G HUB 的场景',
        title: '保留官方软件的场景…',
        points: [
          '重度依赖 Logitech Flow 跨电脑剪切板与无缝切换',
          '需要为游戏外设更新固件或录制单键 RGB 宏',
          '需要将 MX Master 拇指滚轮单独设为触发器',
        ],
      },
      steps: [
        {
          step: '步骤 01',
          title: '退出或卸载 Logi Options+ / G HUB',
          description:
            '移除沉重的罗技后台代理，避免抢占 HID++ 数据包。如果检测到仍在运行，Rebind 会自动提醒。',
        },
        {
          step: '步骤 02',
          title: '安装 Rebind 并授予辅助功能权限',
          description:
            '运行 brew install --cask blinks44/tap/rebind。默认暂停且零规则，绝不请求输入监控。',
        },
        {
          step: '步骤 03',
          title: '调整 HID++、滚动与 Starter Setups',
          description:
            '设定 DPI、SmartShift 和单鼠平滑滚动，再启用内置离线 Starter Setup 或按应用配置。',
        },
      ],
    },
    steermouse: {
      slug: 'steermouse',
      path: '/alternatives/steermouse/',
      breadcrumbLabel: 'SteerMouse',
      metaTitle: '免费的 SteerMouse 与 Mac Mouse Fix 替代方案（开源）· Rebind',
      metaDescription:
        '对比 Rebind 与 SteerMouse、Mac Mouse Fix：免费 MIT 原生 Swift 6 应用，支持侧键 4/5+、四向按键拖动手势、滚轮组合键、罗技 HID++、键盘映射与窗口平铺。',
      headline: '免费开源的 SteerMouse 与 Mac Mouse Fix 替代方案。',
      subtitle:
        '在一款 MIT 开源 Swift 应用里，配置侧键 4/5+、中键、四向按键拖动手势、滚轮组合键、按应用配置、罗技 HID++ 硬件控制与键盘快捷键。',
      highlights: [
        {
          value: '100% 免费 · MIT',
          label: '无需按大版本付费购买许可，无在线激活服务器',
        },
        {
          value: '鼠标 + 键盘 + 窗口',
          label: '侧键、手势组合、键盘长按触发与窗口平铺一步到位',
        },
        {
          value: '原生 HID++ 2.0',
          label: '为罗技鼠标提供直接 DPI 滑块、SmartShift 与菜单栏电量',
        },
      ],
      competitorColumn: 'STEERMOUSE / MAC MOUSE FIX',
      rows: [
        {
          criterion: '许可与价格',
          rebind: '100% 免费，GitHub 上采用 MIT 开源协议',
          other: '付费许可（SteerMouse 约 $20；Mac Mouse Fix 自 v3 起收费）',
        },
        {
          criterion: '侧键与手势',
          rebind: '侧键 4/5+、中键、四向按键拖动与按键+滚轮组合',
          other: '强大的鼠标按键组合与点击拖动手势',
        },
        {
          criterion: '罗技 HID++ 硬件',
          rebind: '内置 DPI 滑块、SmartShift、高分滚轮、手势键与电量',
          other: '仅指针灵敏度/加速度（无 SmartShift 或 HID++ 电量）',
        },
        {
          criterion: '键盘与窗口平铺',
          rebind: '单击/双击/长按按键映射、文本片段与半屏/四分屏平铺',
          other: '仅专注鼠标功能',
        },
        {
          criterion: '应用配置与安全',
          rebind: '按应用规则、游戏/VM 排除、紧急暂停 ⌃⌥⇧⌘ Esc',
          other: '按应用配置鼠标按键',
        },
        {
          criterion: '配置可迁移性',
          rebind: '人类可读 JSON，支持导入导出与自动滚动备份',
          other: '应用管理的二进制/plist 偏好文件',
        },
      ],
      chooseRebind: {
        label: '推荐一站式方案',
        title: '选择 Rebind 的场景…',
        points: [
          '需要免费开源的鼠标侧键映射、拖动手势与滚轮组合键',
          '同时希望管理罗技 HID++ DPI/SmartShift、键盘规则与窗口平铺',
          '想要清晰可读的 JSON 配置，并在启用前预览冲突',
        ],
      },
      stickWithOther: {
        label: '仍适合 STEERMOUSE / MMF 的场景',
        title: '继续使用 SteerMouse 或 Mac Mouse Fix 的场景…',
        points: [
          '需要非常细致的自定义指针加速曲线（SteerMouse）',
          '仍在使用较旧的 macOS（< 15），无法运行 Rebind',
          '已购买许可且只需简单调整指针速度与点击',
        ],
      },
      steps: [
        {
          step: '步骤 01',
          title: '通过 Homebrew 或 DMG 安装',
          description:
            '运行 brew install --cask blinks44/tap/rebind 并仅授予辅助功能。启用规则前保持暂停。',
        },
        {
          step: '步骤 02',
          title: '选用内置 Starter Setup',
          description: '在启用前先预览浏览器或 MX Master Starter Setup 的全部触发器清单。',
        },
        {
          step: '步骤 03',
          title: '按应用细化侧键与组合键',
          description:
            '为浏览器、IDE 和设计软件分别配置侧键 4/5 与滚轮组合，并将游戏加入排除列表。',
        },
      ],
    },
    'linearmouse-mos': {
      slug: 'linearmouse-mos',
      path: '/alternatives/linearmouse-mos/',
      breadcrumbLabel: 'LinearMouse & Mos',
      metaTitle: '集成 HID++ 与侧键的 LinearMouse 与 Mos 替代方案 · Rebind',
      metaDescription:
        '独立反转外接鼠标滚轮而不影响 MacBook 触控板，按鼠标微调平滑滚动，并整合罗技 HID++、侧键手势与窗口平铺。',
      headline: '独立鼠标滚动与平滑手感，外加侧键与 HID++。',
      subtitle:
        '保留触控板自然滚动，独立反转外接鼠标垂直/水平滚轮，按鼠标开启柔和/标准/强劲平滑滚动，取代多个零散工具。',
      highlights: [
        {
          value: '触控板原样保留',
          label: '外接鼠标滚轮干净反转，触控板依然保持自然滚动',
        },
        {
          value: '单鼠平滑滚动',
          label: '按设备分别设置柔和、标准或强劲三档平滑效果',
        },
        {
          value: '单一菜单栏图标',
          label: '整合滚动、侧键、罗技 HID++ 与窗口平铺',
        },
      ],
      competitorColumn: 'LINEARMOUSE / MOS',
      rows: [
        {
          criterion: '独立滚动方向',
          rebind: '按外接鼠标分别反转垂直/水平方向，触控板保持自然',
          other: '鼠标与触控板独立滚动方向',
        },
        {
          criterion: '平滑滚动',
          rebind: '按鼠标设置柔和、标准或强劲平滑滚动',
          other: 'Mos 专精平滑滚动；LinearMouse 侧重行数与指针加速',
        },
        {
          criterion: '侧键与手势',
          rebind: '侧键 4/5+、中键、四向拖动与按键+滚轮组合',
          other: '仅基础前进/后退侧键',
        },
        {
          criterion: '罗技 HID++ 2.0',
          rebind: '原生 DPI 滑块、SmartShift、高分滚轮、手势键与电量',
          other: '不支持（需额外安装 Logi Options+ 等工具）',
        },
        {
          criterion: '键盘与窗口平铺',
          rebind: '支持单击/双击/长按按键重映射及内置窗口平铺',
          other: '仅限鼠标滚动与指针',
        },
        {
          criterion: '权限与配置格式',
          rebind: '仅辅助功能权限，MIT Swift 6，可读 JSON 与自动备份',
          other: '辅助功能权限；开源',
        },
      ],
      chooseRebind: {
        label: '推荐精简工具栈',
        title: '选择 Rebind 的场景…',
        points: [
          '希望在一个应用里同时获得独立滚动方向和平滑滚动',
          '同时需要侧键映射、罗技 HID++ 控制、快捷键或窗口平铺',
          '不想让多个后台输入钩子互相争抢鼠标事件',
        ],
      },
      stickWithOther: {
        label: '仍适合 LINEARMOUSE / MOS 的场景',
        title: '继续使用 LinearMouse 或 Mos 的场景…',
        points: [
          '专门需要 LinearMouse 的关闭指针加速曲线',
          '使用 macOS 13 或 14（Rebind 面向 macOS 15+）',
          '只需要单纯的滚动平滑，不需要侧键或罗技 DPI 控制',
        ],
      },
      steps: [
        {
          step: '步骤 01',
          title: '关闭重叠的滚动工具',
          description: '退出 Mos、Scroll Reverser 或 LinearMouse，避免两个事件拦截器重复反转滚轮。',
        },
        {
          step: '步骤 02',
          title: '反转鼠标滚轮并选择平滑档位',
          description: '在 Rebind 中选择外接鼠标，切换垂直/水平方向并挑选柔和、标准或强劲模式。',
        },
        {
          step: '步骤 03',
          title: '补充侧键与应用排除',
          description: '配置侧键 4/5 或缩放滚轮组合，并把全屏游戏或远程桌面加入排除名单。',
        },
      ],
    },
  },
  guides: {
    'mx-master-mac-setup': {
      slug: 'mx-master-mac-setup',
      path: '/guides/mx-master-mac-setup/',
      breadcrumbLabel: 'MX Master 配置指南',
      metaTitle: '无需 Logi Options+ 在 Mac 上配置 Logitech MX Master 与 G 系列 · Rebind',
      metaDescription:
        '使用 Rebind 在 macOS 上分步配置罗技 MX Master 与 G 系列鼠标：原生 HID++ 2.0 DPI、SmartShift、手势键、独立滚动与窗口平铺。',
      headline: '无需臃肿套件，在 Mac 上配好 MX Master 与 G 系列鼠标。',
      subtitle:
        '不必安装 1 GB 的 Logitech Options+ 或 G HUB，就能在 Mac 上拥有 DPI、SmartShift、高分滚轮、手势键、独立滚动、平滑手感与窗口平铺。',
      secondaryCtaLabel: '与 Logi Options+ / G HUB 对比',
      secondaryCtaTo: '/alternatives/logi-options-ghub/',
      cardsTitle: '从内置离线 Starter Setups 开始',
      cards: [
        {
          label: 'LOGITECH HID++ 2.0',
          title: 'MX Master 效率套装',
          description: '涵盖 MX Master 核心控制，零厂商后台守护进程。',
          items: ['DPI 滑块 + SmartShift 灵敏度', '手势键 + 四向拖动手势', '菜单栏实时电量百分比'],
          footer: '内置离线 Starter Setup',
        },
        {
          label: '浏览器与滚动',
          title: '浏览器与鼠标基础',
          description: '自然触控板 + 传统鼠标滚轮 + 平滑滚动。',
          items: [
            '侧键 4/5 -> 后退 / 前进',
            '中键 + 滚轮 -> 缩放 / 切换标签',
            '平滑滚动：标准档位',
          ],
          footer: '适用于任意 USB 或蓝牙鼠标',
        },
        {
          label: '窗口与键盘',
          title: '窗口布局管理',
          description: '跨屏平铺窗口，同时干净排除游戏与虚拟机。',
          items: [
            '半屏 · 四分屏 · 填充 · 居中',
            '切换屏幕与桌面空间快捷键',
            '按应用排除游戏与虚拟机',
          ],
          footer: '启用前自动预览冲突',
        },
      ],
      stepsTitle: '四步完成清爽配置',
      steps: [
        {
          step: '01 · 辅助功能',
          title: '只授予一项权限',
          description: '安装 Rebind 并仅授予辅助功能权限。默认暂停且零规则，无需输入监控。',
        },
        {
          step: '02 · HID++',
          title: '微调 DPI 与滚动',
          description: '设置 DPI、SmartShift、高分滚轮、独立滚动方向与单鼠平滑滚动。',
        },
        {
          step: '03 · 预设',
          title: '预览并启用',
          description: '挑选带冲突预览的离线 Starter Setup，或导入/导出纯文本 JSON 配置。',
        },
        {
          step: '04 · 故障开放',
          title: '随时一键暂停',
          description: '随时按 ⌃⌥⇧⌘ Esc 暂停全部规则；出现异常时自动退回 macOS 原始输入。',
        },
      ],
      pitfalls: [
        {
          title: '检测并提醒正在运行的 Logi Options+',
          description:
            '同时运行两个 HID++ 驱动会导致滚轮跳动和 DPI 失灵。Rebind 会检测 Logi Options+ 或 G HUB 并给出提示。',
        },
        {
          title: '触控板始终保持自然滚动',
          description: '反转外接鼠标滚轮方向绝不会破坏 MacBook 触控板或妙控板的自然滚动。',
        },
        {
          title: '纯文本 JSON 与自动滚动备份',
          description:
            '所有规则与配置保存在 ~/Library/Application Support/Rebind，自带滚动备份且便于同步。',
        },
      ],
    },
  },
}
