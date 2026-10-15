# Rebind: current state

Updated **2026-10-16**. Implementation HEAD `ca2e4c8` includes the Logitech/Dock/backup fixes. [Device names and keyboard visibility](tasks/DEVICE-002-device-names-discovery.md) are uncommitted on that baseline. Runtime/accessibility/safety/Dock acceptance remains open.

## Product and baseline

Native macOS **26+**, SwiftUI/AppKit, local-only rules, one manual profile; category-wide rules, manual profiles; physical attribution only for mouse settings. Scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Xcode 27 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS/Intel unverified.

Contracts/evidence: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [CAPABILITIES](CAPABILITIES.md).

## What already exists

| Area | Current implementation / limit |
| --- | --- |
| Keyboard/mouse | Quartz tap, primary modifiers, numeric middle/extra buttons, shortcuts, wheel, double/long press and four button-held directions. G603 subsets user-confirmed; physical keyboard/full safety matrix open. |
| Runtime | Bounded synchronous capture/matcher/mailbox, separate action execution, synthetic tags, protected-session/pause/cancellation safeguards and opt-in memory-only mouse diagnostics. Measured callback/action performance and full fault/recovery acceptance remain open. |
| Profiles/storage | Manual CRUD/copy/selection, atomic JSON, protected originals, schema **41**, migrations 1–40. [Switching/restart and restoration subsets user-confirmed](verification/profiles.md); login/cancellation acceptance remains open. |
| Actions | Searchable catalog: shortcuts, audio/media/mouse, AX window/app/layout/cycling, Previous Application, app/web/file, Apple Shortcuts, Spaces, sleep, experimental Dock/lock. Happy-path subsets confirmed; broader guards/platform checks remain. |
| Trackpad | Twelve complete presets, separate built-in/Magic Trackpad categories and the full action catalog. Click/corner replacement and several tap paths user-confirmed; external hardware, timing and safety acceptance open. [INPUT-004](tasks/INPUT-004-two-finger-double-tap.md), [UI-014](tasks/UI-014-trackpad-presets.md), [CAPABILITIES](CAPABILITIES.md). |
| UI/localization | Whole app uses the soft design system from `apps/rebind/rebind/UI/DesignSystem` with EN/RU/DE/FR/ES/Simplified Chinese. Running-app accessibility, focus and localized-width acceptance remain open. |
| Brand | New keycap-and-arrows **apps/rebind/rebind/AppIcon.icon** and **RebindMenuBar** template (2026-10-13). Rendered icon inspected from the Debug build; Dock/live menu/Dark/tint acceptance must be repeated. |
| Website | `apps/website`: TanStack Start + Rsbuild, six languages, local Light/Dark/phone rendering checked. Cloudflare Worker deploy prepared for `rebind.moduix.dev`, not published. Download awaits `site.githubRepo`; do not deploy before advertised Magic devices ship. |

## Design source and recent changes

- **2026-10-16:** [Devices input-only filter](tasks/DEVICE-002-device-names-discovery.md#follow-up-2026-10-16-headsets-excluded-from-devices): headset/unclassified system battery entries no longer get a Devices card; recognized mice, keyboards and trackpads remain.
- **2026-10-15:** [Device names and keyboard visibility](tasks/DEVICE-002-device-names-discovery.md): local display names in Devices and the battery menu (schema 41), keyboard-only cards, stricter HID++ type handling. Read-only hardware probe: G915 keyboard/48 %, G603 mouse/90 %, G435 rejected before opening. Software/native fixture results and open app/reconnect/VoiceOver checks are in the task.
- **2026-10-15:** [Logitech/Dock/backup fixes](tasks/INPUT-011-apps-mice-gesture-button.md): G915 voltage battery, endpoint queues, headset gate, receiver notices, sleeping-state retention, G603/G HUB ownership, Dock/background reopening, last category and backups per change. Build/tests pass; full-app runtime acceptance open.
- **2026-10-15:** [Rules for one app, per-mouse smooth scrolling and gesture button](tasks/INPUT-011-apps-mice-gesture-button.md): implemented with six languages and software checks; physical acceptance remains open.

Source: **Rebind.sketch** (English, Light/Dark) is the design source; [DESIGN](DESIGN.md) locates it. The earlier Liquid Glass document of the same name is fully superseded. Older entries: [history](history/2026-10.md).

## Open work / next steps

- **Next:** run `apps/rebind/tools/magic-mouse-probe.swift` with the Magic Mouse switched on (paired, was not connected on 2026-10-13); its contact counts decide which Magic Mouse presets are feasible and whether the sidebar section becomes real.
- **Open from review:** running-app checks of keyboard focus, VoiceOver and RU/DE/FR at minimum width; Dock/tint acceptance of the new icon.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [DEVICE-002](tasks/DEVICE-002-device-names-discovery.md) | awaiting_verification | Unassigned; released | Check Rename/save/cancel/reset, battery menu and G915 after relaunch/reconnect; reconcile Sketch and VoiceOver. |
| [INPUT-011](tasks/INPUT-011-apps-mice-gesture-button.md) | awaiting_verification | Unassigned; released | Design the new Devices/Input/editor surfaces; user checks gesture button, per-app rules, per-mouse smooth scrolling. |
| [INPUT-010](tasks/INPUT-010-smooth-scrolling.md) | awaiting_verification | Unassigned; released | User checklist: glide feel per length, wheel bindings, Cmd/Ctrl/Shift and trackpad unchanged, per-app toggles, × on the warning, Light/Dark. |
| [DEVICE-001](tasks/DEVICE-001-mouse-devices.md) | awaiting_verification | Unassigned; released | User checklist: Devices on the MX Master 2S, persistence, banner, wheel reverse/speed ("Passed on, changed" in diagnostics), trackpad unaffected, Light/Dark. |
| [UI-023](tasks/UI-023-main-window-soft-adoption.md) | awaiting_verification | Unassigned; integrated | Running-app review of focus, VoiceOver, localized widths. |
| [INPUT-009](tasks/INPUT-009-held-output-exclusions-catalog.md) | awaiting_verification | Unassigned; released | Walk the physical checklist for held output, modifiers, wheel, excluded apps, trackpad keys and the new actions. |
| [UI-022](tasks/UI-022-soft-design-system.md) | in_design | Released | Draw screens for new functionality as it is built (Mouse/Magic Mouse editors, action parameters, diagnostics). |
| [UI-014](tasks/UI-014-trackpad-presets.md) | awaiting_verification | Unassigned; tap editor released | Verify physical taps/coexistence, capture, keyboard/VoiceOver/preferences. |
| [INPUT-008](tasks/INPUT-008-magic-trackpad.md) | awaiting_verification | Unassigned; released | Connect a Magic Trackpad: discovery, gestures, reconnection; regression-check the built-in trackpad. |
| [INPUT-007](tasks/INPUT-007-trackpad-action-catalog.md) | awaiting_verification | Unassigned; released | Run non-shortcut actions from trackpad rules and the brightness actions on hardware. |
| [INPUT-006](tasks/INPUT-006-trackpad-clicks.md) | awaiting_verification | Unassigned; engine/editor released | Verify physical 2/3/4-finger clicks, resting-finger false positives and secondary-click settings. |
| [INPUT-005](tasks/INPUT-005-corner-taps.md) | awaiting_verification | Unassigned; engine/editor released | Verify physical corner taps with Tap to click off/on and accidental palm contact. |
| [INPUT-004](tasks/INPUT-004-two-finger-double-tap.md) | awaiting_verification | Unassigned; engine/data released | Preset exposed 2026-10-13; verify physical pairs/lone taps and Smart Zoom/secondary-click coexistence on a named build. |
| [INPUT-003](tasks/INPUT-003-double-tap-engine.md) | awaiting_verification | Unassigned; engine/data released | Verify physical single/double timing, click exclusion and native conflicts through UI-014. |
| [INPUT-002](tasks/INPUT-002-three-finger-tap.md) | awaiting_verification | Unassigned; engine/data released | Verify physical three/four taps and Look Up coexistence through UI-014. |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | awaiting_verification | Unassigned; focus walkthrough confirmed | Collect physical timing; preserve confirmed scenarios. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | awaiting_verification | Unassigned | Verify grants/revocation, keyboard/VoiceOver/preferences; build/layout pass. |
| [UI-003](tasks/UI-003-general-settings.md) | awaiting_verification | Unassigned | Review General on the named build; actual login/relaunch, VoiceOver/preferences remain open. |
| [UI-004](tasks/UI-004-input-settings.md) | awaiting_verification | Unassigned; materials/copy integrated | Verify physical Hold timing/cancellation, spoken VoiceOver/focus/preferences; scoped native checks pass. |
| [UI-005](tasks/UI-005-language-settings.md) | awaiting_verification | Unassigned | Apply/storage/compact/AX checked; verify actual production relaunch, Cocoa projection repair and accessibility. |
| [UI-007](tasks/UI-007-advanced-settings.md) | awaiting_verification | Unassigned | Requested Advanced checks user-confirmed; retain adaptive/platform/detailed §15.12 gates. |
| [UI-010](tasks/UI-010-about.md) | awaiting_verification | Unassigned | Verify VoiceOver/license reading, full keyboard traversal and accessibility preferences; native entry/search/closing checks pass. |
| [UI-009](tasks/UI-009-mouse-design.md) | awaiting_verification | Unassigned | Editor materials adopted in UI-016; verify capture/timing/accessibility and remaining list materials. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Release gates are listed in [PLAN](PLAN.md).
