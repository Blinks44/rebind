# Rebind — current state

Updated **2026-10-11**. HEAD `bf36465` plus final Advanced alert/diagnostic/test refinements and evidence. General/Permissions/Input/Language/Advanced integrated; full-main Settings overflow repaired. AppKit sharing-indicator warnings isolated. Broader runtime/accessibility/safety/Dock acceptance remains open.

## Product and baseline

Native macOS **26+**, SwiftUI/AppKit, one process/Menu Bar, local-only rules, one manually selected profile across categories. No physical-device attribution/inventory or automatic profile activation. Stable scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Last recorded environment: Xcode 27.0 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS and Intel execution are **not verified**.

Read [WORKFLOW](WORKFLOW.md) for startup/handoff, [PLAN](PLAN.md) for remaining phases, [SPEC](SPEC.md) for required behavior, [CAPABILITIES](CAPABILITIES.md) for detailed evidence. Requirements and design examples do not imply implementation.

## What already exists

| Area | Current implementation / limit |
| --- | --- |
| Keyboard/mouse | Public active Quartz tap, exact primary modifiers, numeric middle/extra buttons, one-shot shortcuts, discrete wheel, double/long press and four cardinal button-held pointer gestures. Configured G603 subsets user-confirmed; physical keyboard/full safety matrix still open. |
| Runtime | Bounded synchronous capture/matcher/mailbox, separate action execution, synthetic tags, protected-session/pause/cancellation safeguards and opt-in memory-only mouse diagnostics. Measured callback/action performance and full fault/recovery acceptance remain open. |
| Profiles/storage | Manual profile CRUD/copy/selection, atomic versioned JSON and corruption/future-file protection. Current schema **24**, migrations from 1–23, setup acknowledgement and language preference software-tested. Complete relaunch/held-input switching remains open. |
| Actions | Shared searchable catalog: shortcuts, audio/media/mouse outputs, AX window/app operations/layouts/cycling, Previous Application, app/web/file opening, Apple Shortcuts, Spaces, sleep, experimental Dock actions/lock. Specific happy paths confirmed; broader guards and platform checks remain. |
| Trackpad | Experimental built-in four-finger single tap → shortcut. Latest rebuilt retest: 25 qualified/queued/posted outputs, no output cancellation; user estimates 10/10 delivery. Public AppKit target check retained. Clicks alone send no shortcut and subsequent taps work, per user. Pause/resume, sleep/wake and mixed input are additionally user-confirmed (unquantified); measured latency and broader safety/platform acceptance remain open; no native suppression. Broader gestures remain unwired. |
| UI/localization | Main/editor/profiles/diagnostics, native setup/recovery and all five Settings sections. Four-language copy, actual-state login, saved/active/reopen language, staged import/export and paused atomic reset/replacement implemented. Real login/language relaunch, restored-binding import acceptance, full accessibility and remaining Sketch main/About/materials remain open. |
| Brand | Refined Sketch geometry delivered as sole icon input **rebind/AppIcon.icon**; obsolete app/reference PNG sets removed. Separate **RebindMenuBar** vector template integrated. Build/resources and Finder evidence recorded; Dock/live menu/macOS 26/tint acceptance remains. Do not recreate these assets as missing. |

## Design source and recent changes

- **2026-10-11:** [General/background](tasks/UI-003-general-settings.md) integrated; [overflow repair/native checks](verification/general-main-window-repair.md) pass. Login/VoiceOver remain open; [OS sharing-indicator cause](verification/appkit-sharing-indicator.md) isolated.

- **2026-10-11:** [Input/hold](tasks/UI-004-input-settings.md) and [Language](tasks/UI-005-language-settings.md) integrated; native Stepper/retry and Dark Apply/compact checks pass. [Evidence](verification/input-language-native.md); actual relaunch/accessibility open.

- **2026-10-11:** [Materials/consistency](tasks/UI-006-material-design-review.md) design finished; Advanced Screens 48–69 saved/reviewed with behavior/four-language copy in Sketch. Full-main materials/accessibility remain separate.

- **2026-10-11:** [Advanced native integration](tasks/UI-007-advanced-settings.md) implemented: validated import/export, paused atomic replacement/reset, protected originals and diagnostics. **570 tests / zero failures**, Debug/signature/layout pass; native Escape/Return cancellation fixed/checked. [Artifact, findings and open acceptance](verification/advanced-settings-native.md). Ownership released; restored-binding runtime and accessibility remain open.

Live source: **Rebind.sketch**, last released 69 screen/state frames, saved 2026-10-11; Mouse design is independently in progress. Resolve current source through [DESIGN](DESIGN.md). Sketch owns visuals/copy; native results stay in Git. [Workflow skill 1.3.0](tasks/DOC-002-workflow-review-skill.md) adds guided setup. Verification images stay local; versioning needs a specific purpose. Earlier outcomes remain in [history](history/2026-10.md).

## Open work / next steps

Resume compatible work by role; [WORKFLOW](WORKFLOW.md#short-requests-and-role-aware-task-selection) defines task selection/access.

- **Design:** Mouse rules/editor active in [UI-009](tasks/UI-009-mouse-design.md); consume only its released scope. Remaining coverage is in [DESIGN](DESIGN.md#remaining-design-coverage).
- **Code:** Advanced integrated. Next verify SPEC §15.12 with disposable authored profiles and complete accessibility checks from [Advanced evidence](verification/advanced-settings-native.md). Production language/restart checks remain user-led; About and ready Mouse design can supply independent future work. Actual login/grants, trackpad/Magic Mouse gates remain separate.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | awaiting_verification | Unassigned; delivery retest recorded | Delivery/click-only recovery and lifecycle/mixed-input walkthrough user-confirmed; next quantified stress and remaining safety/platform checks. Do not repeat confirmed checks without a new concern. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | awaiting_verification | Unassigned; repair verified/released | Verify actual grants/revocation and accessibility; repaired window/native navigation/deferral and software checks pass. |
| [UI-003](tasks/UI-003-general-settings.md) | awaiting_verification | Unassigned; warning isolated | OS sharing indicator identified; user-led restart checks and VoiceOver remain open. |
| [UI-004](tasks/UI-004-input-settings.md) | awaiting_verification | Unassigned; native integration released | Overview/Hold/save retry checked; verify physical timing/cancellation, remaining editor/accessibility states. |
| [UI-005](tasks/UI-005-language-settings.md) | awaiting_verification | Unassigned; native integration released | Apply/storage/compact/AX checked; verify actual production relaunch, Cocoa projection repair and accessibility. |
| [UI-007](tasks/UI-007-advanced-settings.md) | awaiting_verification | Unassigned; native integration released | Export/reset/import/explicit resume with restored binding behavior, then keyboard/VoiceOver/accessibility preferences. |
| [UI-009](tasks/UI-009-mouse-design.md) | in_design | `/root` design, independent chat | Finish/save Mouse rules/editor in live Sketch and release bounded implementation scope. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Additional open gates: Magic Mouse acquisition/recognition; remaining compact trackpad scope; physical keyboard/wheel/double-press/safety checks; full localization/accessibility; stable signing/TCC persistence, macOS 26/Intel, performance and distribution. See PLAN rather than implementing all of them from this summary.
