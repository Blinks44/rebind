# Rebind — current state

Updated **2026-10-12**. HEAD `2bc4b97` includes Trackpad timing/focus safeguards and Advanced/Input UI adoption; Input completion notes uncommitted. Runtime/accessibility/safety/Dock acceptance remains open.

## Product and baseline

Native macOS **26+**, SwiftUI/AppKit, local-only rules, one manual profile; no physical-device attribution/automatic activation. Scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Xcode 27 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS/Intel unverified.

Contracts/evidence: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [CAPABILITIES](CAPABILITIES.md).

## What already exists

| Area | Current implementation / limit |
| --- | --- |
| Keyboard/mouse | Quartz tap, primary modifiers, numeric middle/extra buttons, shortcuts, wheel, double/long press and four button-held directions. G603 subsets user-confirmed; physical keyboard/full safety matrix open. |
| Runtime | Bounded synchronous capture/matcher/mailbox, separate action execution, synthetic tags, protected-session/pause/cancellation safeguards and opt-in memory-only mouse diagnostics. Measured callback/action performance and full fault/recovery acceptance remain open. |
| Profiles/storage | Manual CRUD/copy/selection, atomic JSON and protected originals after launch. Schema **26**, migrations 1–25 and restoration software-tested. [Button 4 switching and restart selection/rules/pause user-confirmed](verification/profiles.md#user-switching-follow-up--2026-10-11); restoration happy path user-confirmed; login and broader cancellation/routes remain open. |
| Actions | Searchable catalog: shortcuts, audio/media/mouse, AX window/app/layout/cycling, Previous Application, app/web/file, Apple Shortcuts, Spaces, sleep, experimental Dock/lock. Happy-path subsets confirmed; broader guards/platform checks remain. |
| Trackpad | Four-finger delivery/click recovery/lifecycle are user-confirmed subsets. Three/four single/double engine/storage and [tap preset editor](tasks/UI-014-trackpad-presets.md) are integrated. Hardware/native conflicts, timing/safety/platform checks remain open. No suppression. Two-finger doubles/clicks/corners remain unwired. |
| UI/localization | Main/editors/profiles/diagnostics, setup, five Settings sections and About exist with EN/RU/DE/FR, language reopen and backup flows. Shared controls/feedback integrated; production login/relaunch, detailed import, accessibility and remaining Sketch adoption stay open. |
| Brand | **rebind/AppIcon.icon** and **RebindMenuBar** vector template exist. Build/Finder evidence recorded; Dock/live menu/macOS 26/tint acceptance remains. |

## Design source and recent changes

- **2026-10-12:** [Trackpad focus cancellation](verification/trackpad-focus-cancellation.md): A → B → A no longer revives old contacts/output. Full **666 functions / 1,870 executions**, Debug/signature pass on `a6471db`; focus-switching user-confirmed; measured timing remains open.
- **2026-10-12:** Shared [Keyboard profile selector](tasks/UI-020-paper-profile-selector.md), [Permissions](verification/permissions-feedback-adoption.md), [General](verification/general-feedback-adoption.md) and [Language](verification/language-selector-refinement.md) integrated with scoped checks; native/accessibility/preferences gates remain.

- **2026-10-12:** [Advanced](verification/advanced-feedback-adoption.md) shared cards/states integrated; requested Advanced checks user-confirmed. [Input materials/copy](verification/input-feedback-adoption.md) integrated; **20 functions / 74 executions**, 608 viewports, Debug/signature/Light/Dark review pass. Adaptive/platform/runtime gates remain.

Source: **Rebind.sketch**, 125 frames, reviewed 2026-10-12; [EN/RU/DE/FR copy](tasks/UI-018-human-interface-copy.md) ready. [DESIGN](DESIGN.md) locates Sketch; native adoption open. Images local; [history](history/2026-10.md).

## Open work / next steps

- **Design:** Coverage/review released; review justified native differences against Sketch.
- **Code:** Measure physical Trackpad scheduling through UI-014; focus-switching walkthrough confirmed. Remaining Settings/main materials and Magic Mouse hardware stay separate.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [UI-019](tasks/UI-019-language-selector-contrast.md) | awaiting_verification | Unassigned; refinement integrated | Verify Dark/menu/focus/VoiceOver/preferences; Light/build/layout pass. |
| [UI-017](tasks/UI-017-settings-control-adoption.md) | awaiting_verification | Unassigned | User review of named build; verify tab focus/VoiceOver/preferences, then remaining Settings/main. |
| [UI-016](tasks/UI-016-editor-design-adoption.md) | awaiting_verification | Unassigned | Verify editors recording/focus/VoiceOver/preferences; then Settings/main. |
| [UI-014](tasks/UI-014-trackpad-presets.md) | awaiting_verification | Unassigned; tap editor released | Verify physical taps/coexistence, capture, keyboard/VoiceOver/preferences. |
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
| [UI-011](tasks/UI-011-control-unification.md) | ready_for_implementation | Unassigned; design ready | Adopt saved glass controls/spacing from live Sketch; check native adaptive materials and focus. |
| [UI-012](tasks/UI-012-semantic-feedback.md) | ready_for_implementation | Unassigned; design ready | Adopt saved semantic feedback from live Sketch; verify native adaptive appearance, reflow and VoiceOver. |
| [UI-013](tasks/UI-013-design-coverage-completion.md) | ready_for_implementation | Unassigned; design ready | Implement the prepared final interface from live Sketch: curated touch presets, shared action/profile states and new copy. |
| [UI-015](tasks/UI-015-production-design-review.md), [UI-018](tasks/UI-018-human-interface-copy.md) | ready_for_implementation | Unassigned; design ready | Adopt components and reviewed EN/RU/DE/FR copy; verify native layout/accessibility. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Broader hardware, accessibility and release gates remain in PLAN.
