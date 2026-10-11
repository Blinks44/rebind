# Rebind — current state

Updated **2026-10-11**. HEAD `33b54a1` plus uncommitted workflow skill/docs changes. General/Permissions/Input/Language integrated; full-main Settings overflow repaired. AppKit inspection warnings isolated; Advanced backup foundation added. Broader safety/Dock acceptance remains open.

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
| UI/localization | Main/editor/profiles/diagnostics, native setup/recovery and General/Permissions/Input/Language Settings. Four-language copy, actual-state login and manual language with saved/active/reopen feedback implemented. Real login/language relaunch, full Sketch materials/main/About, Advanced and import/export/reset remain open. |
| Brand | Refined Sketch geometry delivered as sole icon input **rebind/AppIcon.icon**; obsolete app/reference PNG sets removed. Separate **RebindMenuBar** vector template integrated. Build/resources and Finder evidence recorded; Dock/live menu/macOS 26/tint acceptance remains. Do not recreate these assets as missing. |

## Design source and recent changes

- **2026-10-11:** [General/background](tasks/UI-003-general-settings.md) integrated; overflow repair, native Dark/compact navigation and software checks pass. [Repair/evidence](verification/general-main-window-repair.md); actual login/VoiceOver remain open; [AppKit sharing-indicator cause](verification/appkit-sharing-indicator.md) isolated.

- **2026-10-11:** [Input/hold](tasks/UI-004-input-settings.md) and [Language](tasks/UI-005-language-settings.md) integrated. **544 full-suite tests / zero failures**, 352 full Settings combinations; native Stepper/save retry and Dark Apply/compact review pass. [Artifacts/activation/limits](verification/input-language-native.md); real language relaunch/accessibility open.

- **2026-10-11:** [Materials/consistency](tasks/UI-006-material-design-review.md) finished: paired control geometry, glass profile, divider-free Activation. [Advanced design](tasks/UI-007-advanced-settings.md) saved/reviewed, Screens 48–69; behavior and EN/RU/DE/FR copy inside Sketch. Native adoption/accessibility remain separate. Workflow now requires direct Sketch inspection; redundant PNG exports removed.

Live source: **Rebind.sketch**, 69 screen/state frames, saved 2026-10-11. Resolve via [DESIGN](DESIGN.md), which owns the current revision/locator and remaining coverage. Sketch owns visual states/components/copy; concise native behavior/test results stay in Git. [Workflow skill 1.3.0](tasks/DOC-002-workflow-review-skill.md#standalone-skills-repository-and-guided-initialization--2026-10-11) adds guided setup; maintained in skills, with a Rebind snapshot. Verification images stay local (29 native captures moved); versioned images need a specific purpose. Earlier outcomes remain in [history](history/2026-10.md).

## Open work / next steps

Resume compatible work by role; [WORKFLOW](WORKFLOW.md#short-requests-and-role-aware-task-selection) defines task selection/access.

- **Design:** Advanced is ready in [UI-007](tasks/UI-007-advanced-settings.md). Next: Mouse rules and editor; roughly four packages remain in [DESIGN](DESIGN.md#remaining-design-coverage). Preserve integrated General/Input/Language behavior.
- **Code:** Input/Hold and Language integrated. User is verifying production language quit/relaunch; AppKit warning traced to OS sharing/inspection. [Advanced storage foundation](tasks/UI-008-advanced-storage.md) is ready (553 tests / zero failures); next native Advanced panels/confirmation/reset from the released UI-007 Sketch scope; actual login/VoiceOver/accessibility preferences remain open. Inspect Advanced directly in Sketch; native materials adoption must preserve full-main sizing. Trackpad/Magic Mouse gates remain separate.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | awaiting_verification | Unassigned; delivery retest recorded | Delivery/click-only recovery and lifecycle/mixed-input walkthrough user-confirmed; next quantified stress and remaining safety/platform checks. Do not repeat confirmed checks without a new concern. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | awaiting_verification | Unassigned; repair verified/released | Verify actual grants/revocation and accessibility; repaired window/native navigation/deferral and software checks pass. |
| [UI-003](tasks/UI-003-general-settings.md) | awaiting_verification | Unassigned; warning isolated | OS sharing indicator identified; user-led restart checks and VoiceOver remain open. |
| [UI-004](tasks/UI-004-input-settings.md) | awaiting_verification | Unassigned; native integration released | Overview/Hold/save retry checked; verify physical timing/cancellation, remaining editor/accessibility states. |
| [UI-005](tasks/UI-005-language-settings.md) | awaiting_verification | Unassigned; native integration released | Apply/storage/compact/AX checked; verify actual production relaunch, Cocoa projection repair and accessibility. |
| [UI-007](tasks/UI-007-advanced-settings.md) | ready_for_implementation | Unassigned; Sketch saved/reviewed | Implement Advanced from live Sketch and UI-008 backup foundation; native transaction/accessibility checks remain. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Additional open gates: Magic Mouse acquisition/recognition; remaining compact trackpad scope; physical keyboard/wheel/double-press/safety checks; full localization/accessibility; stable signing/TCC persistence, macOS 26/Intel, performance and distribution. See PLAN rather than implementing all of them from this summary.
