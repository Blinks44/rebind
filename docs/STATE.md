# Rebind — current state

Updated **2026-10-11**. HEAD `ed0b5d9` plus uncommitted protected-save work and independent Sketch records. General/Permissions/Input/Language/Advanced/About/Mouse integrated; full-main Settings overflow repaired. Broader runtime/accessibility/safety/Dock acceptance remains open.

## Product and baseline

Native macOS **26+**, SwiftUI/AppKit, one process/Menu Bar, local-only rules, one manually selected profile across categories. No physical-device attribution/inventory or automatic profile activation. Stable scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Last recorded environment: Xcode 27.0 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS and Intel execution are **not verified**.

Read [WORKFLOW](WORKFLOW.md) for startup/handoff, [PLAN](PLAN.md) for remaining phases, [SPEC](SPEC.md) for required behavior, [CAPABILITIES](CAPABILITIES.md) for detailed evidence.

## What already exists

| Area | Current implementation / limit |
| --- | --- |
| Keyboard/mouse | Public active Quartz tap, exact primary modifiers, numeric middle/extra buttons, one-shot shortcuts, discrete wheel, double/long press and four cardinal button-held pointer gestures. Configured G603 subsets user-confirmed; physical keyboard/full safety matrix still open. |
| Runtime | Bounded synchronous capture/matcher/mailbox, separate action execution, synthetic tags, protected-session/pause/cancellation safeguards and opt-in memory-only mouse diagnostics. Measured callback/action performance and full fault/recovery acceptance remain open. |
| Profiles/storage | Manual CRUD/copy/selection, atomic JSON and protected originals after launch. Schema **24**, migrations 1–23 and restoration software-tested. [Button 4 switching and restart selection/rules/pause user-confirmed](verification/profiles.md#user-switching-follow-up--2026-10-11); restoration happy path user-confirmed; login and broader cancellation/routes remain open. |
| Actions | Shared searchable catalog: shortcuts, audio/media/mouse outputs, AX window/app operations/layouts/cycling, Previous Application, app/web/file opening, Apple Shortcuts, Spaces, sleep, experimental Dock actions/lock. Specific happy paths confirmed; broader guards and platform checks remain. |
| Trackpad | Experimental built-in four-finger single tap → shortcut. Latest rebuilt retest: 25 qualified/queued/posted outputs, no output cancellation; user estimates 10/10 delivery. Public AppKit target check retained. Clicks alone send no shortcut and subsequent taps work, per user. Pause/resume, sleep/wake and mixed input are additionally user-confirmed (unquantified); measured latency and broader safety/platform acceptance remain open; no native suppression. Broader gestures remain unwired. |
| UI/localization | Conditional Mouse list/editor/search, main/profiles/diagnostics, native setup/recovery, all five Settings sections and About with local searchable licenses. Four-language copy, actual-state login, saved/active/reopen language, staged import/export and paused atomic reset/replacement implemented. Real login/language relaunch, detailed import acceptance, full accessibility and remaining Sketch main/materials remain open. |
| Brand | Refined Sketch geometry delivered as sole icon input **rebind/AppIcon.icon**; obsolete app/reference PNG sets removed. Separate **RebindMenuBar** vector template integrated. Build/resources and Finder evidence recorded; Dock/live menu/macOS 26/tint acceptance remains. Do not recreate these assets as missing. |

## Design source and recent changes

- **2026-10-11:** [Trackpad buffer safety](verification/trackpad-buffer-safety.md) repaired loss/readiness races; 591 tests, Debug build and 200 injected recovery cycles pass. Physical timing/stress/safety remain open.
- **2026-10-11:** [Protected saves/restoration](verification/protected-saves-and-restoration.md): protected originals survive; restoration/cancellation/retry pass. 596 tests / 1,544 executions, Debug/signature pass. Switching/restart/restoration happy paths user-confirmed; detailed runtime/login and broader cancellation/routes remain open.

Live source: **Rebind.sketch**, 89 frames, saved/reviewed 2026-10-11; [glass controls](tasks/UI-011-control-unification.md) and [semantic feedback](tasks/UI-012-semantic-feedback.md), Foundations 14–15, are released. Native adoption is open. [DESIGN](DESIGN.md) locates the source. Sketch owns visuals/copy; native results stay in Git and verification images stay local. Earlier outcomes: [history](history/2026-10.md).

## Open work / next steps

Resume compatible work by role; [WORKFLOW](WORKFLOW.md#short-requests-and-role-aware-task-selection) defines task selection/access.

- **Design:** [UI-013](tasks/UI-013-design-coverage-completion.md) is active: final planned Trackpad/Magic Mouse, action and profile states. UI-011/UI-012 shared rules are released; native capability verification stays separate.
- **Code:** Advanced/About integrated. Mouse integration is released; adopt the shared glass controls and semantic feedback from live Sketch and complete its remaining native acceptance. Advanced SPEC §15.12 restored-binding behavior and About/Settings accessibility remain open in their evidence checklists. Production language/restart, actual login/grants and input hardware gates remain separate.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
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
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Broader hardware, trackpad/Magic Mouse, localization/accessibility, signing/TCC, macOS 26/Intel, performance and distribution gates remain in PLAN.
