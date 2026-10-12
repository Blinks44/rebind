# Rebind — current state

Updated **2026-10-12**. HEAD `59f5754` plus uncommitted implementation/design work. Shared controls and General/Permissions feedback integrated. Runtime/accessibility/safety/Dock gates remain open.

## Product and baseline

Native macOS **26+**, SwiftUI/AppKit, local-only rules and one manually selected profile. No physical-device attribution or automatic activation. Scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Xcode 27 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS/Intel unverified.

Read [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md) and [CAPABILITIES](CAPABILITIES.md) for contracts and evidence.

## What already exists

| Area | Current implementation / limit |
| --- | --- |
| Keyboard/mouse | Quartz tap, primary modifiers, numeric middle/extra buttons, shortcuts, wheel, double/long press and four button-held directions. G603 subsets user-confirmed; physical keyboard/full safety matrix open. |
| Runtime | Bounded synchronous capture/matcher/mailbox, separate action execution, synthetic tags, protected-session/pause/cancellation safeguards and opt-in memory-only mouse diagnostics. Measured callback/action performance and full fault/recovery acceptance remain open. |
| Profiles/storage | Manual CRUD/copy/selection, atomic JSON and protected originals after launch. Schema **26**, migrations 1–25 and restoration software-tested. [Button 4 switching and restart selection/rules/pause user-confirmed](verification/profiles.md#user-switching-follow-up--2026-10-11); restoration happy path user-confirmed; login and broader cancellation/routes remain open. |
| Actions | Searchable catalog: shortcuts, audio/media/mouse, AX window/app/layout/cycling, Previous Application, app/web/file, Apple Shortcuts, Spaces, sleep, experimental Dock/lock. Happy-path subsets confirmed; broader guards/platform checks remain. |
| Trackpad | Four-finger delivery/click recovery/lifecycle are user-confirmed subsets. Three/four single/double engine/storage and [tap preset editor](tasks/UI-014-trackpad-presets.md) are integrated. Hardware/native conflicts, timing/safety/platform checks remain open. No suppression. Two-finger doubles/clicks/corners remain unwired. |
| UI/localization | Mouse/main/profiles/diagnostics, setup, five Settings sections and About exist. Four-language copy, actual login status, language reopen, import/export/reset and shared editor/Settings navigation exist. Production login/relaunch, detailed import, accessibility and remaining Sketch adoption are open. |
| Brand | **rebind/AppIcon.icon** and **RebindMenuBar** vector template exist. Build/Finder evidence recorded; Dock/live menu/macOS 26/tint acceptance remains. |

## Design source and recent changes

- **2026-10-12:** [Permissions feedback](verification/permissions-feedback-adoption.md) integrated: 18 functions/656 viewports, Debug/signature and scoped Light/Dark live review pass; actual grants/VoiceOver/preferences remain open.
- **2026-10-12:** [Language selector contrast](tasks/UI-019-language-selector-contrast.md) saved/reviewed across all eight Sketch states; ready for native adoption.
- **2026-10-12:** [General feedback](verification/general-feedback-adoption.md) and [Settings navigation/Language](tasks/UI-017-settings-control-adoption.md) integrated; software/native checks pass. Login/focus/VoiceOver/preferences remain open.

Live source: **Rebind.sketch**, 125 frames, saved/reviewed 2026-10-12; [DESIGN](DESIGN.md) locates released design. Sketch owns visuals/copy; Git owns native evidence. Images stay local; earlier outcomes: [history](history/2026-10.md).

## Open work / next steps

- **Design:** Coverage/review released; review justified native differences against Sketch.
- **Code:** Adopt Language selector refinement or remaining Settings/main/profile materials; verify taps through UI-014. Magic Mouse awaits hardware; reuse [touch audit](research/touch-library-audit.md).

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [UI-019](tasks/UI-019-language-selector-contrast.md) | ready_for_implementation | Unassigned; selector design released | Implement the refined compact Language selector from live Sketch; verify native focus/adaptive materials. |
| [UI-017](tasks/UI-017-settings-control-adoption.md) | awaiting_verification | Unassigned; navigation/Language integrated | User review of named build; verify tab focus/VoiceOver/preferences, then remaining Settings/main. |
| [UI-016](tasks/UI-016-editor-design-adoption.md) | awaiting_verification | Unassigned; source components/copy adopted | Review final editors; verify recording/focus/VoiceOver/preferences, then Settings/main. |
| [UI-014](tasks/UI-014-trackpad-presets.md) | awaiting_verification | Unassigned; tap editor released | Verify physical taps/coexistence, capture and keyboard/VoiceOver/adaptive preferences on a named build. |
| [INPUT-003](tasks/INPUT-003-double-tap-engine.md) | awaiting_verification | Unassigned; engine/data released | Verify physical single/double timing, click exclusion and native conflicts through UI-014. |
| [INPUT-002](tasks/INPUT-002-three-finger-tap.md) | awaiting_verification | Unassigned; engine/data released | Verify physical three/four taps and Look Up coexistence through UI-014. |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | awaiting_verification | Unassigned; buffer safety released | Injected loss/recovery checks pass; verify busy-consumer cancellation/recovery and measured physical timing/stress/safety. Preserve confirmed delivery/lifecycle subsets. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | awaiting_verification | Unassigned; Settings feedback adopted | Verify actual grants/revocation, keyboard/VoiceOver/preferences; named build and native layout checks pass. |
| [UI-003](tasks/UI-003-general-settings.md) | awaiting_verification | Unassigned; General feedback adopted | Review General on the named build; actual login/relaunch, VoiceOver/preferences remain open. |
| [UI-004](tasks/UI-004-input-settings.md) | awaiting_verification | Unassigned; native integration released | Overview/Hold/save retry checked; verify physical timing/cancellation, remaining editor/accessibility states. |
| [UI-005](tasks/UI-005-language-settings.md) | awaiting_verification | Unassigned; native integration released | Apply/storage/compact/AX checked; verify actual production relaunch, Cocoa projection repair and accessibility. |
| [UI-007](tasks/UI-007-advanced-settings.md) | awaiting_verification | Unassigned; native integration released | Restoration/navigation user-confirmed broadly; retain detailed runtime, VoiceOver/preferences and artifact-specific checks. |
| [UI-010](tasks/UI-010-about.md) | awaiting_verification | Unassigned; implementation released | Verify VoiceOver/license reading, full keyboard traversal and accessibility preferences; native entry/search/closing checks pass. |
| [UI-009](tasks/UI-009-mouse-design.md) | awaiting_verification | Unassigned; native integration released | Editor materials adopted in UI-016; verify capture/timing/accessibility and remaining list materials. |
| [UI-011](tasks/UI-011-control-unification.md) | ready_for_implementation | Unassigned; design released | Adopt saved glass controls/spacing from live Sketch; check native adaptive materials and focus. |
| [UI-012](tasks/UI-012-semantic-feedback.md) | ready_for_implementation | Unassigned; design released | Adopt saved semantic feedback from live Sketch; verify native adaptive appearance, reflow and VoiceOver. |
| [UI-013](tasks/UI-013-design-coverage-completion.md) | ready_for_implementation | Unassigned; design released | Implement the prepared final interface from live Sketch: curated touch presets, shared action/profile states and new copy. |
| [UI-015](tasks/UI-015-production-design-review.md) | ready_for_implementation | Unassigned; design released | Adopt shared corrections; verify native materials, menus and alignment. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Broader hardware/accessibility/signing, macOS 26/Intel, performance and distribution gates remain in PLAN.
