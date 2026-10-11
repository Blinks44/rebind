# Rebind — current state

Updated **2026-10-11**. Baseline: `acce2f4` plus uncommitted trackpad output-validation repair and independent permission/alignment/General/Input design records; inspect Git status/HEAD and actual artifacts before editing. First-run/permissions is integrated and the main-window clipping failure is repaired; General/background and Input/hold remain ready for implementation. Single-tap delivery and click-only recovery are user-confirmed; broader trackpad lifecycle and Dock acceptance remain open.

## Product and baseline

Native macOS **26+** input remapper, SwiftUI/AppKit, one app process/Menu Bar, local-only rules, one manually selected profile across categories. No physical-device attribution/inventory or automatic profile activation. Stable scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Last recorded environment: Xcode 27.0 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS and Intel execution are **not verified**.

Read [WORKFLOW](WORKFLOW.md) for startup/handoff, [PLAN](PLAN.md) for remaining phases, [SPEC](SPEC.md) for required behavior, [CAPABILITIES](CAPABILITIES.md) for detailed evidence. Requirements and design examples do not imply implementation.

## What already exists

| Area | Current implementation / limit |
| --- | --- |
| Keyboard/mouse | Public active Quartz tap, exact primary modifiers, numeric middle/extra buttons, one-shot shortcuts, discrete wheel, double/long press and four cardinal button-held pointer gestures. Configured G603 subsets user-confirmed; physical keyboard/full safety matrix still open. |
| Runtime | Bounded synchronous capture/matcher/mailbox, separate action execution, synthetic tags, protected-session/pause/cancellation safeguards and opt-in memory-only mouse diagnostics. Measured callback/action performance and full fault/recovery acceptance remain open. |
| Profiles/storage | Manual profile CRUD/copy/selection, atomic versioned JSON and corruption/future-file protection. Current source schema **23**, software-tested migrations from 1–22 and durable setup acknowledgement; native acceptance remains open. Selection output user-confirmed; complete relaunch/held-input switching still open. |
| Actions | Shared searchable catalog: shortcuts, audio/media/mouse outputs, AX window/app operations/layouts/cycling, Previous Application, app/web/file opening, Apple Shortcuts, Spaces, sleep, experimental Dock actions/lock. Specific happy paths confirmed; broader guards and platform checks remain. |
| Trackpad | Experimental built-in four-finger single tap → shortcut. Latest rebuilt retest: 25 qualified/queued/posted outputs, no output cancellation; user estimates 10/10 delivery. Public AppKit target check retained. Clicks alone send no shortcut and subsequent taps work, per user. Broader click timing, measured latency and lifecycle remain open; no native suppression. Broader gestures remain unwired. |
| UI/localization | Baseline main/editor/profiles/diagnostics plus native setup/recovery and Settings → Permissions; 53 permission keys integrated in EN/RU/DE/FR. Full Sketch main UI, other Settings/About, Launch at Login, import/export/reset and manual locale remain unfinished. |
| Brand | Refined Sketch geometry delivered as sole icon input **rebind/AppIcon.icon**; obsolete app/reference PNG sets removed. Separate **RebindMenuBar** vector template integrated. Build/resources and Finder evidence recorded; Dock/live menu/macOS 26/tint acceptance remains. Do not recreate these assets as missing. |

## Design source and recent changes

- **2026-10-11:** [Native first-run/permissions](tasks/UI-001-permissions-onboarding.md) integrated: schema 23 acknowledgement, actual-grant stages, one-time recovery and Settings/Menu Bar routes. **508 Swift Testing cases + one native layout test / 0 failures**; window repair, 72 size/locale/grant/rule combinations, native navigation/deferral, Release/signatures pass. [Evidence](verification/permissions-native.md); actual grants/accessibility remain open.

- **2026-10-11:** [Input/hold timing design](tasks/UI-004-input-settings.md) ready: seven frames, four sources, 18 four-language keys. Input EN/RU/DE/FR and Light/Dark screenshots, minimum/expanded sizing, 96-node restoration and saved-source preservation checked. [Delivery](verification/input-settings.md). Native/translated hold-editor acceptance remains open.
- **2026-10-11:** [General/background](tasks/UI-003-general-settings.md) ready with ten states and actual login/runtime distinctions; [alignment review](verification/alignment-review.md) done. Native acceptance remains open.

- **2026-10-11:** trackpad output-target repair software checks passed; user retest: ~10/10 configured delivery, 25 queued/posted outputs, no cancellation. [Evidence/limits](verification/phase-5-four-finger-tap.md#successful-single-tap-retest--2026-10-11). Click-only exclusion and subsequent tap also user-confirmed; broader lifecycle/timing remain open.

Live source: **Rebind.sketch**, 39 screen frames; last document ID `E50CA3D9-82B1-44C0-AC97-39F1A9663700` on 2026-10-11. IDs can change: resolve again. [DESIGN](DESIGN.md) indexes source/evidence and distinguishes saved design from implemented UI. Mock rows include unsupported examples; do not enable those capabilities from artwork. Earlier workflow/onboarding/icon outcomes remain in [history](history/2026-10.md).

## Open work / next steps

Owners are advisory. Refresh task records and current activity before claiming shared surfaces.

Resume compatible work by role; [WORKFLOW](WORKFLOW.md#short-requests-and-role-aware-task-selection) defines task selection/access.

- **Design:** preserve integrated first-run/permissions; General/background and Input/hold timing are ready for bounded implementation. Next slice: Settings → Language (System/EN/RU/DE/FR), then Advanced. Preserve sources and capability limits; native/runtime acceptance stays separate.
- **Code:** main-window clipping is repaired and verified ([evidence](verification/permissions-native.md#main-window-repair-and-verification--2026-10-11)). Next independent implementation can consume General/background (UI-003); user-controlled grant/accessibility checks remain open. Resume four-finger lifecycle/mixed-input acceptance and remaining compact trackpad integration when hardware checks are available; Magic Mouse remains separate research/implementation. Full main design integration remains open.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | awaiting_verification | Unassigned; delivery retest recorded | Delivery/click-only recovery confirmed; next pause/resume/sleep and mixed-input timing. Do not repeat confirmed checks without a new concern. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | awaiting_verification | Unassigned; repair verified/released | Verify actual grants/revocation and accessibility; repaired window/native navigation/deferral and software checks pass. |
| [UI-003](tasks/UI-003-general-settings.md) | ready_for_implementation | Unassigned; `/root` design saved/released | Implement General/background using actual login/runtime state and existing pause/persistence/Menu Bar lifecycle. |
| [UI-004](tasks/UI-004-input-settings.md) | ready_for_implementation | Unassigned; `/root` design saved/released | Implement Input overview and existing per-binding Hold timing; verify native/editor locales/accessibility and save failure. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Additional open gates: Magic Mouse acquisition/recognition; remaining compact trackpad scope; physical keyboard/wheel/double-press/safety checks; full localization/accessibility; stable signing/TCC persistence, macOS 26/Intel, performance and distribution. See PLAN rather than implementing all of them from this summary.

History and detailed checks live in the linked task/evidence records.
