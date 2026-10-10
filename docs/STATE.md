# Rebind — current state

Updated **2026-10-10**. Baseline: `6c1a5be` (`feat: new icon`) plus uncommitted input timing/diagnostic repairs, documentation and brand cleanup. Compare current Git status/HEAD and artifacts before editing. Software builds/tests and icon resources were checked; new tap/Dock hardware acceptance remains open.

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
| Trackpad | Experimental built-in four-finger single tap → shortcut. Very low recognition, possible click output and post-click failure remain reported. Receipt/poll clocks and known-neutral recovery repaired; opt-in one-minute aggregate diagnostics added. Hardware frequency/exclusivity pending; no native suppression. Broader gestures remain unwired. |
| UI/localization | Functional baseline main window/editor/profiles/permission guidance/diagnostics; current catalog has EN/RU/DE/FR. Full Sketch UI, Settings/About, native first-launch onboarding, Launch at Login, import/export/reset and manual locale selection are unfinished. |
| Brand | Refined Sketch geometry delivered as sole icon input **rebind/AppIcon.icon**; obsolete app/reference PNG sets removed. Separate **RebindMenuBar** vector template integrated. Build/resources and Finder evidence recorded; Dock/live menu/macOS 26/tint acceptance remains. Do not recreate these assets as missing. |

## Design source and recent changes

- **2026-10-10:** final workflow review covers public README/document roles, fresh and already-open chats, neutral scoped confirmations, and commit boundaries. Shared docs/skills use English; raw snapshots are local-only and ignored. The MIT [agent-workflow-setup skill](../.agents/skills/agent-workflow-setup/README.md), version 1.0.2, is instruction-only; prior 11 skills retained. [DOC-002](tasks/DOC-002-workflow-review-skill.md).

- **2026-10-10:** [root README](../README.md) now serves repository visitors with product overview, stack, build/run and first launch. Detailed setup moved to [DEVELOPMENT](DEVELOPMENT.md); [docs index](README.md) routes contributor/agent references. No capability/implementation change.
- **2026-10-10:** agent workflow uses short entry points, task handoffs, capability/research records and technical history. Modern macOS 26+ Liquid Glass, elevation and purposeful gradients explicitly established in [DESIGN](DESIGN.md). Documentation checks only; no new capability acceptance.
- **2026-10-10:** Menu Bar template integrated; six first-launch/permissions Sketch frames saved/reviewed, including Light/Dark, event-sending mismatch, ready/revoked and German expansion. Native onboarding and its 28-key four-language copy handoff are not integrated. [Evidence](verification/menu-bar-onboarding.md).
- **2026-10-10:** three reproduced tap timing/recovery regressions repaired without threshold changes. **488 tests / 64 suites / 0 failures**, Debug test build/Release/signatures pass. [Renewed library audit](research/trackpad-tap-reliability.md): no suitable replacement SDK established; no dependency added. Next: [hardware diagnostic run](verification/phase-5-four-finger-tap.md#timing-races-recovery-and-opt-in-diagnostics--2026-10-10).
- **2026-10-10:** obsolete icon PNGs removed; fresh Xcode/repository resources match and Finder shows the new artwork. Scoped bundle registration refresh and one Dock restart completed after a stale-icon report; app relaunch result remains open. [Evidence](verification/app-icon-composer.md), [brand sources](../assets/brand/README.md).

Live source: **Rebind.sketch**, resolved through Sketch MCP; last document ID `5E7440F8-E8FE-4C5B-9691-D1A211777C77` on 2026-10-10. IDs can change: resolve again before work. [DESIGN](DESIGN.md) indexes frames/styles and distinguishes saved design from implemented UI. Mock rows include unsupported examples; do not enable those capabilities from artwork.

## Open work / next steps

No running chat is assigned ownership by this migration. Existing concurrent chat activity must be checked before claiming files; these rows are durable pending work, not live locks.

For “continue Rebind”, first select INPUT-001's core acceptance if hardware/user assistance is available; otherwise UI-001 is the next independent slice with current Sketch access. Explain the choice and proceed within the user's scope. WORKFLOW describes blocked-access and interrupted-session handling.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | awaiting_verification | Unassigned; `/root` repair saved | One rebuilt copy with `--diagnose-trackpad`: natural taps, click-only negatives and recovery; collect the 60-second aggregate report. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | planned | Unassigned; saved initial design retained | Continue main-window missing-permission and Settings → Permissions states in Sketch, then implement a bounded onboarding slice. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Additional open gates: Magic Mouse acquisition/recognition; remaining compact trackpad scope; physical keyboard/wheel/double-press/safety checks; full localization/accessibility; stable signing/TCC persistence, macOS 26/Intel, performance and distribution. See PLAN rather than implementing all of them from this summary.

Keep this file short. Update affected facts/task rows after meaningful work; move old detail to [history](history/README.md). Before a final response, save the task/evidence and next step so a new chat can continue.
