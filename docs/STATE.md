# Rebind: current state

Updated **2026-10-19**. Baseline `main` `497b0d1` includes [Magic Mouse integration and shared-adapter corrections](tasks/INPUT-014-magic-mouse-integration.md). [October 18 manual results](verification/manual-test-2026-10-18.md) are recorded with artifact limits; remaining runtime/accessibility/safety/Dock acceptance stays open.

## Product and baseline

Native macOS **26+**, SwiftUI/AppKit, local-only category-wide rules, one manually selected profile; physical attribution only for mouse settings. Scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Xcode 27.1 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS/Intel unverified.

Contracts/evidence: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [CAPABILITIES](CAPABILITIES.md).

## What already exists

Keyboard/mouse capture, manual profiles/atomic storage (schema **42**, migrations 1–41), the shared action catalog and twelve built-in/external trackpad presets are implemented. Magic Mouse has an experimental one/two-finger single-tap app testing pool (basic delivery user-confirmed; native-double conflict and broader acceptance open). Held outputs, per-app rules/exclusions, per-mouse smooth scrolling and Devices settings are present. Whole-app soft styling and EN/RU/DE/FR/ES/Simplified Chinese are integrated. Named happy-path subsets are confirmed; full runtime, safety, timing, external-hardware, accessibility and minimum-OS gates remain open. [CAPABILITIES](CAPABILITIES.md) owns the detailed matrix; it is not repeated here.

The website is prepared for Cloudflare at `rebind.moduix.dev`, not published; download awaits `site.githubRepo` and advertised Magic-device support. Since 2026-10-16 it also presents smooth scrolling, Devices/Logitech/battery, dual-role keys, Button + Wheel, per-app rules, held repeat, backups and the wider catalog. Brand Dock/Menu Bar/tint acceptance must use the current artwork.

## Design source and recent changes

**Rebind.sketch**, English Light/Dark, is located in [DESIGN](DESIGN.md); it supersedes Liquid Glass. Earlier dated results: [October history](history/2026-10.md) and owning tasks.

- **October 19 permissions fix:** [UI-001](tasks/UI-001-permissions-onboarding.md) removes the redundant system AX alert alongside the direct settings opening; `UI/AppModel.swift` is uncommitted. Debug build and **15 permission/setup tests** pass. First-use/denial, app listing and actual grant/return/revocation checks remain open.
- **October 19 manual-results update:** [October 18 checklist](verification/manual-test-2026-10-18.md) confirms G HUB/DPI/menu slider, qualitative low idle energy, dual-role/repeat/gesture holds, background scroll exclusions and built-in tap/click/ordinary-gesture subsets. Exact tested artifact/settings are unknown. Blank checks remain open; no build/test rerun.
- **Touch follow-up:** [INPUT-014](tasks/INPUT-014-magic-mouse-integration.md) fixes discovery restarting capture before arming; **879 logic + 19 native tests**, isolated Debug/signature pass. External 3/4-finger singles and basic Magic Mouse taps user-confirmed. Fast mouse singles retained; overlapping native gestures must be disabled manually. Timing/safety/reconnect and dedicated Sketch states remain open. [INPUT-013](tasks/INPUT-013-trackpad-review-fixes.md) owns native tap-click replacement and selector anchoring; supplied built-in passes are not tied to the corrected adapter artifact.
- **Other integrated fixes:** [idle/SIGTERM](tasks/REVIEW-002-idle-energy.md), [G HUB/DPI/tap recovery](tasks/DEVICE-005-companion-dpi-reconnect.md), [menu DPI slider](tasks/DEVICE-004-menu-pointer-speed.md). Passed happy paths and remaining acceptance are separated in those records. [Production review](tasks/REVIEW-001-production-review.md) owns the battery menu and 52 Sketch pairs; [multi-vendor battery](tasks/DEVICE-003-multi-vendor-battery.md) and [audio](verification/phase-4-audio.md) retain their evidence/limits.

## Open work / next steps

- **Next engineering slice:** verify Insert Text with Russian/emoji in TextEdit, Terminal and a browser, then keyboard traversal/focus in the main window, editor and Settings; fix reproduced defects. Hardware: first trackpad single/double after idle, external category separation/doubles/reconnect, current-bundle built-in regression and Magic Mouse ordinary-input safety/pause/reconnect with native overlaps disabled. Dedicated Magic Mouse Sketch states remain open.
- **Open from review:** running-app checks of keyboard focus, VoiceOver and all six languages at minimum width (including arrow keys/VoiceOver on the Menu Bar battery rows); Dock/tint acceptance of the new icon.

All listed tasks are `awaiting_verification`, with no active owner, except UI-022 (`in_design`, ownership released). Detailed implementation handoffs remain in the task records.

| Task | Concrete next step |
| --- | --- |
| [REVIEW-002](tasks/REVIEW-002-idle-energy.md) | First trackpad pair/single after idle, SIGTERM held-state cleanup, Release CPU. |
| [DEVICE-005](tasks/DEVICE-005-companion-dpi-reconnect.md) | G HUB/DPI passed; Options+ detection and tap-timeout recovery remain. |
| [DEVICE-004](tasks/DEVICE-004-menu-pointer-speed.md) | Drag/reopen/Devices passed; Light/Dark, VoiceOver, widths, keyboard route. |
| [INPUT-014](tasks/INPUT-014-magic-mouse-integration.md) | Mouse timing/safety/pause/reconnect; external doubles; Sketch states. |
| [INPUT-013](tasks/INPUT-013-trackpad-review-fixes.md) | Current-bundle regression, external doubles/reconnect, false clicks, popup. |
| [REVIEW-001](tasks/REVIEW-001-production-review.md) | Remaining held-state/quit/glide safety; battery-menu keyboard/VoiceOver/macOS 26. |
| [DEVICE-003](tasks/DEVICE-003-multi-vendor-battery.md) | Named USB models, Bluetooth/BAS, reconnect, Logitech regression. |
| [DEVICE-002](tasks/DEVICE-002-device-names-discovery.md) | Rename/save/cancel/reset, G915/menu/reconnect, keyboard/VoiceOver. |
| [INPUT-011](tasks/INPUT-011-apps-mice-gesture-button.md) | Hold/background exclusion passed; directions, multi-mouse, reconnect/quit. |
| [INPUT-010](tasks/INPUT-010-smooth-scrolling.md) | Preserve user-confirmed feel/exclusions; Sketch 42/44/45 review remains. |
| [DEVICE-001](tasks/DEVICE-001-mouse-devices.md) | MX Master 2S subset passed; Options+, Bluetooth/Bolt, MX Master 3/3S. |
| [UI-023](tasks/UI-023-main-window-soft-adoption.md) | Keyboard focus, VoiceOver, all localized widths. |
| [INPUT-009](tasks/INPUT-009-held-output-exclusions-catalog.md) | Insert Text in three apps; interruption cleanup; remaining catalog/modifiers. |
| [UI-022](tasks/UI-022-soft-design-system.md) | Reconcile Magic Mouse editor with the implemented testing pool. |
| [UI-014](tasks/UI-014-trackpad-presets.md) | Physical coexistence/capture, keyboard/VoiceOver/preferences. |
| [INPUT-008](tasks/INPUT-008-magic-trackpad.md) | Category separation, doubles/reconnect and built-in regression. |
| [INPUT-007](tasks/INPUT-007-trackpad-action-catalog.md) | Non-shortcut trackpad actions and brightness on hardware. |
| [INPUT-006](tasks/INPUT-006-trackpad-clicks.md) | Three-finger replacement passed; other counts, false clicks/settings. |
| [INPUT-005](tasks/INPUT-005-corner-taps.md) | Corners, Tap to click off/on, accidental palm contact. |
| [INPUT-004](tasks/INPUT-004-two-finger-double-tap.md) | Built-in subset passed; current-build/lone/external pairs, native conflicts. |
| [INPUT-003](tasks/INPUT-003-double-tap-engine.md) | Built-in three-finger double passed; four/external pairs, timing/safety. |
| [INPUT-002](tasks/INPUT-002-three-finger-tap.md) | Built-in delivery passed; current-build timing/accuracy and Look Up. |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | Physical timing; preserve confirmed focus/delivery/lifecycle subsets. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | Retest direct settings without duplicate alert; first-use listing/grant return, revocation and accessibility. |
| [UI-003](tasks/UI-003-general-settings.md) | Login/relaunch, VoiceOver/preferences on a named build. |
| [UI-004](tasks/UI-004-input-settings.md) | Physical hold timing/cancellation, VoiceOver/focus/preferences. |
| [UI-005](tasks/UI-005-language-settings.md) | Production reopen, Cocoa projection repair and accessibility. |
| [UI-007](tasks/UI-007-advanced-settings.md) | Preserve confirmed Advanced subset; remaining §15.12/platform/preferences. |
| [UI-010](tasks/UI-010-about.md) | VoiceOver/licenses, full keyboard and preferences. |
| [UI-009](tasks/UI-009-mouse-design.md) | Capture/timing/native accessibility of integrated styling. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | Fresh-bundle Dock/Menu Bar; tint and macOS 26 separately. |

Release gates are listed in [PLAN](PLAN.md).
