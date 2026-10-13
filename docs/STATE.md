# Rebind: current state

Updated **2026-10-13**. HEAD `03c1504` plus the uncommitted 2026-10-13 cleanup contains all work to date ([INPUT-009](tasks/INPUT-009-held-output-exclusions-catalog.md), sidebar brand, website). Runtime/accessibility/safety/Dock acceptance remains open.

## Product and baseline

Native macOS **26+**, SwiftUI/AppKit, local-only rules, one manual profile; no physical-device attribution/automatic activation. Scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Xcode 27 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS/Intel unverified.

Contracts/evidence: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [CAPABILITIES](CAPABILITIES.md).

## What already exists

| Area | Current implementation / limit |
| --- | --- |
| Keyboard/mouse | Quartz tap, primary modifiers, numeric middle/extra buttons, shortcuts, wheel, double/long press and four button-held directions. G603 subsets user-confirmed; physical keyboard/full safety matrix open. |
| Runtime | Bounded synchronous capture/matcher/mailbox, separate action execution, synthetic tags, protected-session/pause/cancellation safeguards and opt-in memory-only mouse diagnostics. Measured callback/action performance and full fault/recovery acceptance remain open. |
| Profiles/storage | Manual CRUD/copy/selection, atomic JSON and protected originals after launch. Schema **34**, migrations 1–33 and restoration software-tested. [Button 4 switching and restart selection/rules/pause user-confirmed](verification/profiles.md#user-switching-follow-up-2026-10-11); restoration happy path user-confirmed; login and broader cancellation/routes remain open. |
| Actions | Searchable catalog: shortcuts, audio/media/mouse, AX window/app/layout/cycling, Previous Application, app/web/file, Apple Shortcuts, Spaces, sleep, experimental Dock/lock. Happy-path subsets confirmed; broader guards/platform checks remain. |
| Trackpad | Four-finger delivery/click recovery/lifecycle are user-confirmed subsets. Three/four single/double and two-finger double engine/storage are integrated ([INPUT-004](tasks/INPUT-004-two-finger-double-tap.md)). [Tap preset editor](tasks/UI-014-trackpad-presets.md) exposes the full twelve-preset pool: 3/4 singles, 2/3/4 doubles, [2/3/4-finger physical clicks](tasks/INPUT-006-trackpad-clicks.md) and four [one-finger corner taps](tasks/INPUT-005-corner-taps.md). Hardware/native conflicts, timing/safety/platform checks remain open. Trackpad rules run [any catalog action](tasks/INPUT-007-trackpad-action-catalog.md). Native gestures are not suppressed, except that click and corner rules replace their own click (both user-confirmed happy paths). |
| UI/localization | Whole app uses the soft design system from `apps/rebind/rebind/UI/DesignSystem` with EN/RU/DE/FR/ES/Simplified Chinese. Running-app accessibility, focus and localized-width acceptance remain open. |
| Brand | New keycap-and-arrows **apps/rebind/rebind/AppIcon.icon** and **RebindMenuBar** template (2026-10-13). Rendered icon inspected from the Debug build; Dock/live menu/Dark/tint acceptance must be repeated. |
| Website | **apps/website**: one-page landing on TanStack Start + Rsbuild with moduix components, Motion and Paraglide in the app's six languages (EN at `/`, others prefixed), styled from the Theme tokens (2026-10-13). Copy describes the finished product including Magic Mouse/Magic Trackpad (user decision): do not deploy before those ship. Builds and renders locally in Light/Dark and at phone width; the download button is a placeholder until `site.githubRepo` is set, and `site.url` (canonical/Open Graph) and deployment are open. |

## Design source and recent changes

- **2026-10-13:** Repository-wide cleanup. Em dashes removed from documentation, product strings, the website and Sketch. Code simplified without behavior changes: one mailbox helper for cancelling queued work, one cancellation closure in the action worker, schema migration as a per-rule minimum-schema table, shared inset-row/round-button/margin helpers, dead parameters removed. DESIGN no longer describes the superseded Liquid Glass document. 748 Swift Testing and 15 layout tests pass; nothing was checked in the running app or on hardware.
- **2026-10-13:** [Held output, excluded apps, wider catalog and rule management](tasks/INPUT-009-held-output-exclusions-catalog.md) (schema 34): "Repeat While Held" for shortcuts and step actions, apps in which Rebind stays out of the way, 27 new catalog actions (Do Nothing, pause/profile control, editing, tabs, screenshots, Insert Text, quarters, next display), rule duplicate/copy-to-profile/note, mouse gesture distance, and wheel rules under a held mouse button. A copy review of all six languages changed 95 strings (one term per language for app, trigger, click and shortcut; Title Case action names in English). Sketch gained screens 29–33 (Button + Wheel editor, Repeat While Held with a note, Input settings with gesture distance and excluded apps, Insert Text, the binding options menu), saved 2026-10-13. Later the same day: modifier-hold actions, a short-press shortcut on hold rules, one held key for trackpad gestures, wheel direction and speed, single-profile export/import, a support report and a paused Menu Bar icon; Sketch has screens 29–38 covering every addition, `Icon/text.cursor` and `Brand/Menu Bar Template Paused`. 748 tests pass; nothing seen in the running app or tried on hardware.
- **2026-10-13:** Sidebar brand enlarged by user request: 44 pt icon and 22 pt Semibold name in all Sketch sidebar screens and in the app ([UI-023](tasks/UI-023-main-window-soft-adoption.md)). Layout tests pass; not yet seen in the running app.
- **2026-10-13:** With Show in Dock off, the Dock icon now follows window visibility (shown while a window is open, gone after the last one closes). User-confirmed in the running app.
- **2026-10-13:** Show in Dock / Show in menu bar / Start in the background settings (schema 33); windows reopen on the current Space; Spanish and Simplified Chinese added (unreviewed translations). Dock/menu bar hiding, background start and current-Space windows are user-confirmed; both new languages display correctly but their wording is not reviewed by a fluent reader.
- **2026-10-13:** A mouse button with gestures clicks again when released without movement and may also carry a press rule; Back/Forward actions send ⌘[ / ⌘] (user-confirmed); the click on a gesture button is user-confirmed too.
- **2026-10-13:** Copy review of every string in four languages (plain wording, one term per language), Back/Forward output on its own held button fixed, Sketch completed with screens 27–28 and repaired dark icon tints.
- **2026-10-13:** [Magic Trackpad section](tasks/INPUT-008-magic-trackpad.md): own rules, same presets and editor as the built-in trackpad (schema 32); no device was connected, so everything about the external surface is unverified. Gesture names use the compact Sketch form ("Tap · 4 fingers"); the diagnostics table uses design-system rows; Sketch gains the sidebar item and screens 21–23.
- **2026-10-13:** Back/Forward mouse-button and scroll actions added (schema 31); the rule row no longer draws its switch label. Outputs untested on hardware.
- **2026-10-13:** [Trackpad rules use the full action catalog](tasks/INPUT-007-trackpad-action-catalog.md); display brightness up/down added (schema 30). Complete suite passes; hardware checks open.
- **2026-10-13:** [Physical 2/3/4-finger clicks](tasks/INPUT-006-trackpad-clicks.md) replace the click with their rule (schema 29, three editor presets); injected tests pass, physical acceptance open.
- **2026-10-13:** [One-finger corner taps](tasks/INPUT-005-corner-taps.md) integrated through the tap engine with schema 28 and four editor presets; the click Tap to click makes from a configured corner is consumed so the rule replaces it. Injected tests pass and the happy path is user-confirmed with Tap to click on; other corners/options and palm false positives are open.
- **2026-10-13:** Two-finger double-tap preset exposed in the Trackpad editor; Mouse gesture direction is a segmented control (Sketch screen 19, Light/Dark); `apps/rebind/tools/magic-mouse-probe.swift` prepared for the Phase 6 hardware check. Scoped editor/layout tests pass.
- **2026-10-13:** Code and design review: design-system code consolidated under `apps/rebind/rebind/UI/DesignSystem`, legacy names and 48 unused strings removed, secondary text contrast raised, unused Sketch styles deleted. Full suite passes.
- **2026-10-13:** [Whole app restyled and reconciled with Sketch](tasks/UI-023-main-window-soft-adoption.md): main window, editor, Settings, profiles, setup and About use the soft design system; new app icon and Menu Bar template.
- **2026-10-12:** [Soft design system](tasks/UI-022-soft-design-system.md) replaces the Liquid Glass direction by user decision.
- **2026-10-12:** [Two-finger double-tap engine/storage](verification/two-finger-double-tap-engine.md): schema 27; preset exposure and physical acceptance open.
- **2026-10-12:** [Trackpad focus cancellation](verification/trackpad-focus-cancellation.md) repaired and user-confirmed; measured timing open.

Source: **Rebind - new.sketch** (38 screens × Light/Dark, English only) is the design source; [DESIGN](DESIGN.md) locates it. The earlier **Rebind.sketch** is fully superseded. Older entries: [history](history/2026-10.md).

## Open work / next steps

- **Next:** run `apps/rebind/tools/magic-mouse-probe.swift` with the Magic Mouse switched on (paired, was not connected on 2026-10-13); its contact counts decide which Magic Mouse presets are feasible and whether the sidebar section becomes real.
- **Open from review:** running-app checks of keyboard focus, VoiceOver and RU/DE/FR at minimum width; Dock/tint acceptance of the new icon.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
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
