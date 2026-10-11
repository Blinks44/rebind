# Rebind — current state

Updated **2026-10-12**. HEAD `afb7411` plus uncommitted input/editor/design work. Final Sketch is released. Settings/About/Mouse/tap editor integrated; runtime/accessibility/safety/Dock gates remain open.

## Product and baseline

Native macOS **26+**, SwiftUI/AppKit, local-only rules and one manually selected profile. No physical-device attribution or automatic activation. Scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Xcode 27 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS/Intel unverified.

Read [WORKFLOW](WORKFLOW.md) for startup/handoff, [PLAN](PLAN.md) for remaining phases, [SPEC](SPEC.md) for required behavior, [CAPABILITIES](CAPABILITIES.md) for detailed evidence.

## What already exists

| Area | Current implementation / limit |
| --- | --- |
| Keyboard/mouse | Quartz tap, primary modifiers, numeric middle/extra buttons, shortcuts, wheel, double/long press and four button-held directions. G603 subsets user-confirmed; physical keyboard/full safety matrix open. |
| Runtime | Bounded synchronous capture/matcher/mailbox, separate action execution, synthetic tags, protected-session/pause/cancellation safeguards and opt-in memory-only mouse diagnostics. Measured callback/action performance and full fault/recovery acceptance remain open. |
| Profiles/storage | Manual CRUD/copy/selection, atomic JSON and protected originals after launch. Schema **26**, migrations 1–25 and restoration software-tested. [Button 4 switching and restart selection/rules/pause user-confirmed](verification/profiles.md#user-switching-follow-up--2026-10-11); restoration happy path user-confirmed; login and broader cancellation/routes remain open. |
| Actions | Searchable catalog: shortcuts, audio/media/mouse, AX window/app/layout/cycling, Previous Application, app/web/file, Apple Shortcuts, Spaces, sleep, experimental Dock/lock. Happy-path subsets confirmed; broader guards/platform checks remain. |
| Trackpad | Four-finger delivery/click recovery/lifecycle are user-confirmed subsets. Three/four single/double engine/storage and [tap preset editor](tasks/UI-014-trackpad-presets.md) are integrated. Hardware/native conflicts, timing/safety/platform checks remain open. No suppression. Two-finger doubles/clicks/corners remain unwired. |
| UI/localization | Mouse/main/profiles/diagnostics, setup, five Settings sections and About implemented. Four-language copy, actual-state login, saved/active/reopen language, staged import/export and atomic reset exist. Production login/relaunch, detailed import, accessibility and Sketch adoption remain open. |
| Brand | **rebind/AppIcon.icon** and **RebindMenuBar** vector template exist. Build/Finder evidence recorded; Dock/live menu/macOS 26/tint acceptance remains. |

## Design source and recent changes

- **2026-10-12:** [Final design coverage](tasks/UI-013-design-coverage-completion.md) saved/reviewed, including canvas-gap and shared Light/Dark keycap corrections. Native adoption/acceptance remain open.

- **2026-10-12:** [Tap preset editor](verification/trackpad-preset-editor.md) connects the four engine-backed gestures, independent shortcut recording and conditional native conflict guidance. Software/native presentation checked; hardware/accessibility acceptance remains open. Earlier engine evidence: [double taps](verification/double-tap-engine.md).

Live source: **Rebind.sketch**, 125 screen/state frames, saved/reviewed 2026-10-12. [Glass controls](tasks/UI-011-control-unification.md), [semantic feedback](tasks/UI-012-semantic-feedback.md) and [final design coverage](tasks/UI-013-design-coverage-completion.md), Foundations 14–22, are released. Native adoption is open. [DESIGN](DESIGN.md) locates the saved revision. Sketch owns visuals/copy; native results stay in Git and verification images stay local. Earlier outcomes: [history](history/2026-10.md).

## Open work / next steps

Resume compatible work by role; [WORKFLOW](WORKFLOW.md#short-requests-and-role-aware-task-selection) defines task selection/access.

- **Design:** Remaining planned coverage is saved/released in [UI-013](tasks/UI-013-design-coverage-completion.md). Next review justified native differences against live Sketch; capability verification stays separate.
- **Code:** Verify physical three/four single/double taps through the integrated [preset editor](tasks/UI-014-trackpad-presets.md) on a named build. Remaining touch engines/actions/list states and broader UI-011/012/013 adoption stay in PLAN. Runtime/accessibility, production language/login/grants and hardware gates remain open.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [UI-014](tasks/UI-014-trackpad-presets.md) | awaiting_verification | Unassigned; tap editor released | Verify physical taps/coexistence, capture and keyboard/VoiceOver/adaptive preferences on a named build. |
| [INPUT-003](tasks/INPUT-003-double-tap-engine.md) | awaiting_verification | Unassigned; engine/data released | Verify physical single/double timing, click exclusion and native conflicts through UI-014. |
| [INPUT-002](tasks/INPUT-002-three-finger-tap.md) | awaiting_verification | Unassigned; engine/data released | Verify physical three/four taps and Look Up coexistence through UI-014. |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | awaiting_verification | Unassigned; buffer safety released | Injected loss/recovery checks pass; verify busy-consumer cancellation/recovery and measured physical timing/stress/safety. Preserve confirmed delivery/lifecycle subsets. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | awaiting_verification | Unassigned; repair verified/released | Verify actual grants/revocation and accessibility; repaired window/native navigation/deferral and software checks pass. |
| [UI-003](tasks/UI-003-general-settings.md) | awaiting_verification | Unassigned; warning isolated | OS sharing indicator identified; user-led restart checks and VoiceOver remain open. |
| [UI-004](tasks/UI-004-input-settings.md) | awaiting_verification | Unassigned; native integration released | Overview/Hold/save retry checked; verify physical timing/cancellation, remaining editor/accessibility states. |
| [UI-005](tasks/UI-005-language-settings.md) | awaiting_verification | Unassigned; native integration released | Apply/storage/compact/AX checked; verify actual production relaunch, Cocoa projection repair and accessibility. |
| [UI-007](tasks/UI-007-advanced-settings.md) | awaiting_verification | Unassigned; native integration released | Restoration/navigation user-confirmed broadly; retain detailed runtime, VoiceOver/preferences and artifact-specific checks. |
| [UI-010](tasks/UI-010-about.md) | awaiting_verification | Unassigned; implementation released | Verify VoiceOver/license reading, full keyboard traversal and accessibility preferences; native entry/search/closing checks pass. |
| [UI-009](tasks/UI-009-mouse-design.md) | awaiting_verification | Unassigned; native integration released | Verify capture/cancellation, physical timing and accessibility; adopt released UI-011 materials. |
| [UI-011](tasks/UI-011-control-unification.md) | ready_for_implementation | Unassigned; design released | Adopt saved glass controls/spacing from live Sketch; check native adaptive materials and focus. |
| [UI-012](tasks/UI-012-semantic-feedback.md) | ready_for_implementation | Unassigned; design released | Adopt saved semantic feedback from live Sketch; verify native adaptive appearance, reflow and VoiceOver. |
| [UI-013](tasks/UI-013-design-coverage-completion.md) | ready_for_implementation | Unassigned; design released | Implement the prepared final interface from live Sketch: curated touch presets, shared action/profile states and new copy. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Broader hardware, trackpad/Magic Mouse, localization/accessibility, signing/TCC, macOS 26/Intel, performance and distribution gates remain in PLAN.
