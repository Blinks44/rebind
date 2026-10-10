# Rebind — current state

Updated **2026-10-10**. Baseline: `365db64` (`feat: ai workflow`) plus uncommitted screen-icon review; inspect Git status/HEAD and actual artifacts before editing. Latest design reviews saved and checked Sketch onboarding layouts and UI icon scaling; it ran no app/hardware checks. Prior software/icon evidence retains its original scope. Tap/Dock hardware acceptance remains open.

## Product and baseline

Native macOS **26+** input remapper, SwiftUI/AppKit, one app process/Menu Bar, local-only rules, one manually selected profile across categories. No physical-device attribution/inventory or automatic profile activation. Stable scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Last recorded environment: Xcode 27.0 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS and Intel execution are **not verified**.

Read [WORKFLOW](WORKFLOW.md) for startup/handoff, [PLAN](PLAN.md) for remaining phases, [SPEC](SPEC.md) for required behavior, [CAPABILITIES](CAPABILITIES.md) for detailed evidence. Requirements and design examples do not imply implementation.

## What already exists

| Area | Current implementation / limit |
| --- | --- |
| Keyboard/mouse | Public active Quartz tap, exact primary modifiers, numeric middle/extra buttons, one-shot shortcuts, discrete wheel, double/long press and four cardinal button-held pointer gestures. Configured G603 subsets user-confirmed; physical keyboard/full safety matrix still open. |
| Runtime | Bounded synchronous capture/matcher/mailbox, separate action execution, synthetic tags, protected-session/pause/cancellation safeguards and opt-in memory-only mouse diagnostics. Measured callback/action performance and full fault/recovery acceptance remain open. |
| Profiles/storage | Manual profile CRUD/copy/selection, atomic versioned JSON and corruption/future-file protection. Current source schema **22**, migrations from 1–21. Selection output user-confirmed; complete relaunch/held-input switching still open. |
| Actions | Shared searchable catalog: shortcuts, audio/media/mouse outputs, AX window/app operations/layouts/cycling, Previous Application, app/web/file opening, Apple Shortcuts, Spaces, sleep, experimental Dock actions/lock. Specific happy paths confirmed; broader guards and platform checks remain. |
| Trackpad | Experimental built-in four-finger single tap → shortcut. Latest user comparison: 8/10 initially, then failure after clicks; BTT 10/10 and continued operation (exact artifacts/conditions unknown). Buffered pre-mouse-up releases now rearm without output; prior timing repairs and one-minute diagnostics retained. Hardware frequency/exclusivity pending; no native suppression. Broader gestures remain unwired. |
| UI/localization | Functional baseline main window/editor/profiles/permission guidance/diagnostics; current catalog has EN/RU/DE/FR. Full Sketch UI, Settings/About, native first-launch onboarding, Launch at Login, import/export/reset and manual locale selection are unfinished. |
| Brand | Refined Sketch geometry delivered as sole icon input **rebind/AppIcon.icon**; obsolete app/reference PNG sets removed. Separate **RebindMenuBar** vector template integrated. Build/resources and Finder evidence recorded; Dock/live menu/macOS 26/tint acceptance remains. Do not recreate these assets as missing. |

## Design source and recent changes

- **2026-10-10:** [agent-workflow-setup](../.agents/skills/agent-workflow-setup/README.md) 1.2.1 incorporates web adoption feedback: candidate research for upcoming work, reviewed package-resource routing and installed-gate reconciliation. Independent setup/audit and read-only role recovery tested; full feature/design cycles remain open. Short requests, Git hygiene and prior 11 skills retained. [DOC-002](tasks/DOC-002-workflow-review-skill.md).

- **2026-10-10:** Repaired clipping and resizing in six first-launch/permission Sketch frames: text origins, square icon, component anchors, action Stacks and bottom footer. All states checked at 520 × 560, 560 × 580 and 720 × 680; resize roundtrips pass. UI icon borders now scale at 32/48/80 pt; Brand sources preserved. [Icon review](verification/menu-bar-onboarding.md#screen-icon-consistency-repair--2026-10-10). Menu Bar template remains integrated; native onboarding and its four-language copy are not integrated. [Evidence](verification/menu-bar-onboarding.md#onboarding-layout-repair--2026-10-10).
- **2026-10-10:** a buffered pre-mouse-up release regression failed in both cases, then passed after neutral recovery repair. **490 tests / 64 suites / 0 failures**, Debug test build/Release/signatures pass; thresholds unchanged. [Evidence](verification/phase-5-four-finger-tap.md#buffered-release-after-mouse-up--2026-10-10). Prior [library audit](research/trackpad-tap-reliability.md) retained; no dependency added. Sustained hardware failure still needs aggregate diagnostics.
- **2026-10-10:** obsolete icon PNGs removed; fresh Xcode/repository resources match and Finder shows the new artwork. Scoped bundle registration refresh and one Dock restart completed after a stale-icon report; app relaunch result remains open. [Evidence](verification/app-icon-composer.md), [brand sources](../assets/brand/README.md).

Live source: **Rebind.sketch**, resolved through Sketch MCP; last document ID `F370A2F1-FBA6-4BF9-A056-A1500D5C8688` on 2026-10-10. IDs can change: resolve again before work. [DESIGN](DESIGN.md) indexes frames/styles and distinguishes saved design from implemented UI. Mock rows include unsupported examples; do not enable those capabilities from artwork.

## Open work / next steps

No running chat is assigned ownership by this migration. Existing concurrent chat activity must be checked before claiming files; these rows are durable pending work, not live locks.

Resolve short requests by role and outcome; IDs below are agent navigation. Resume a compatible current task before choosing a new one. [WORKFLOW](WORKFLOW.md#short-requests-and-role-aware-task-selection) defines selection/access rules.

- **Design:** next actionable slice is **first-run and permission recovery**: compose missing-permission main-window and Settings → Permissions states in current Sketch. Preserve delivered icons; runtime icon checks belong to implementation/verification.
- **Code:** prioritize **reliable four-finger tap** acceptance when hardware/user evidence is available. Otherwise select actionable independent engineering from PLAN/CAPABILITIES or a genuinely ready bounded design handoff. Full first-run/permissions design is still incomplete; record that dependency and keep the same role. Never assume its saved initial frames prove whole-flow readiness.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | awaiting_verification | Unassigned; `/root` buffered-release fix saved | Retest one fresh diagnostic copy after clicks; if it stops, continue taps inside the 60-second window and collect the aggregate report. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | in_design | Unassigned; layout/icon reviews completed/released | Six initial frames repaired and resize-checked; next compose main-window missing-permission and Settings → Permissions, then implement a bounded onboarding slice. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Additional open gates: Magic Mouse acquisition/recognition; remaining compact trackpad scope; physical keyboard/wheel/double-press/safety checks; full localization/accessibility; stable signing/TCC persistence, macOS 26/Intel, performance and distribution. See PLAN rather than implementing all of them from this summary.

Keep this file short. Update affected facts/task rows after meaningful work; move old detail to [history](history/README.md). Before a final response, save the task/evidence and next step so a new chat can continue.
