# Rebind: current state

Updated **2026-11-05**, checkout `main`. Published **[1.3.2 (42)](https://github.com/Blinks44/rebind/releases/tag/v1.3.2)**, schema **49**: battery-menu alignment, explicit one-finger side-tap labels and the initial-selection fix (build 42 replaced build 41 under maintainer authorization). Tester accepted both changes; installed opening-state and keyboard/VoiceOver checks remain in UI-026. Release evidence for 1.1.0–1.3.2 is in [history](history/README.md). Inspect Git status on resume. Startup: [WORKFLOW](WORKFLOW.md) and [PLAN](PLAN.md).

Tooling: default products are outside Desktop; test/packaging intermediates are temporary and cleaned automatically; `dev.sh clean` clears build/run products ([DEV-001](tasks/DEV-001-build-cache-lifecycle.md); the full-suite navigation timing check remains open: 997 pass/one fail/two skipped, the focused run passes). Since 2026-11-05 `dev.sh format`/`lint` run the Xcode-bundled swift-format; the formatting-only build 43 is local and unpublished ([history](history/2026-11.md#2026-11-05-swift-formatting-agent-permissions-and-docs-cleanup)).

## Product and current artifact

Native macOS **15+**, Swift 6 / SwiftUI/AppKit, scheme/module `rebind`, bundle `blinks44.rebind`. Recorded environment: Apple silicon macOS 27, Xcode 27.1 / Swift 6.4 / SDK 27; macOS 15 checked in a VM (UI and rules), macOS 26/Intel and real-Mac macOS 15 touch input unverified.

Rules/profiles/actions, per-app restrictions/exclusions, held outputs, mouse settings/batteries, Devices in the main-window sidebar, experimental Logitech RGB lighting, atomic storage, first run, Sparkle daily updates with CHANGELOG notes and six languages are implemented. Both trackpad categories have **12 presets**; Magic Mouse has **eight Experimental presets** including left/right one-finger taps. Rules remain category-wide; profiles manual. [SPEC](SPEC.md), [CAPABILITIES](CAPABILITIES.md) and [DESIGN](DESIGN.md) own contracts, evidence and the live Sketch locator.

Lighting: RGB support covers HID++ 0x8071 input devices; other brands/0x8070 need another backend. G915 automatic off and key-press wake are tester-confirmed; power-cycle/reconnect, G HUB/battery recovery and accessibility stay in LIGHT-001.

## Acceptance and remaining release work

The [architecture/library audit](tasks/REVIEW-003-libraries-and-simplification.md) is complete; F2 configuration transactions and device/catalog extraction are deliberately deferred. [Cursor-stutter triage](history/2026-10.md#2026-10-27-receiver-cursor-stutter-log-triage) found no receiver entries; next is a receiver placement comparison with an exact recurrence time.

Preserve tester acceptance: October 20 wheel/window/keyboard/recovery/update ([FIX-001](tasks/FIX-001-wheel-and-window-regressions.md)), October 21 first run and window actions ([FIX-002](tasks/FIX-002-window-action-compatibility.md)), October 22 build-11 copy/VoiceOver/contrast/widths, build-16 copy, build-17 smoke, October 29 installed 1.2.0 and the 1.2.0 → 1.3.0 Sparkle update with rules and Accessibility kept. The [release queue](verification/release-candidate.md) owns the narrower outstanding cases; do not request another whole-app pass without affected changes.

[SIGNING](SIGNING.md) owns non-notarized signing and recovery. Another-Mac, macOS 26, granted-profile CPU/latency, safety and accessibility gates are in [PLAN](PLAN.md#release-gates).

Website: `apps/website/` is live at rebind.moduix.dev ([WEB-002](tasks/WEB-002-website-refresh.md), closed), last deployed 2026-10-29 from `main`. Shared shell with Monny: [SPEC §17](SPEC.md#17-public-website). Publication/deployment need authorization ([RELEASING](RELEASING.md)).

## Open task index

| Task | Concrete next step |
| --- | --- |
| [UI-026](tasks/UI-026-menu-battery-alignment.md) | Build 42 fixes automatic keyboard-row selection on opening; verify installed opening state, keyboard and VoiceOver. |
| [FIX-005](tasks/FIX-005-builtin-trackpad-after-sleep.md) | Installed 1.3.1+: built-in gestures after a two-hour lid-closed sleep without relaunch. |
| [PLAT-001](tasks/PLAT-001-macos-15-support.md) | Touch input on a real Mac with macOS 15. |
| [INPUT-016](tasks/INPUT-016-magic-mouse-side-taps.md) | Real Magic Mouse: side orientation, resting finger, Smart Zoom. |
| [COPY-001](tasks/COPY-001-app-and-website-language.md) | Confirm the deployed site, sync changed build-29 English strings to Sketch. |
| [FIX-004](tasks/FIX-004-shortcuts-held-release.md) | Check installed long-Shortcut held release/order and pause/quit (build 26 fix). |
| [FIX-003](tasks/FIX-003-menu-error-presentation.md) | Installed keyboard/VoiceOver/menu hover/unsupported-window recovery (build 24 fix). |
| [PERF-001](tasks/PERF-001-background-wakeups.md) | Controlled CPU/scrolling/typing and companion/audio/protected-context checks. |
| [ACTION-001](tasks/ACTION-001-standard-actions.md) | Other new actions and switching/Dock/display cases; Fill with Left Margin confirmed. |
| [LIGHT-001](tasks/LIGHT-001-keyboard-lighting.md) | awaiting_verification: automatic off and key-press wake tester-confirmed after the build-30 handoff; next Device default/relaunch/reconnect/G HUB. Other physical gates remain. |
| [REL-005](tasks/REL-005-onboarding-and-updates.md) | Sparkle update into 1.3.2 (42) with rules and Accessibility kept; first-run accessibility/locales. |
| [REL-001](tasks/REL-001-signing-workflow.md) | Preserve the signer; key restore/off-device copy user-reported done; another-Mac/current-signature installation. |
| [INPUT-015](tasks/INPUT-015-touch-release-scope.md) | Preserve six-gesture delivery; remaining settings/safety matrix. Source reconciled. |
| [UI-024](tasks/UI-024-keyboard-navigation.md) | Targeted normal-build focus/preferences and file transactions; preserve build-11 accessibility acceptance. |
| [REVIEW-002](tasks/REVIEW-002-idle-energy.md) | Idle-first-touch, SIGTERM release, granted Release CPU. |
| [DEVICE-005](tasks/DEVICE-005-companion-dpi-reconnect.md) | G HUB/DPI passed; Options+ detection and tap-timeout recovery remain. |
| [DEVICE-004](tasks/DEVICE-004-menu-pointer-speed.md) | Drag/reopen/Devices passed; Light/Dark, VoiceOver, widths, keyboard route. |
| [INPUT-014](tasks/INPUT-014-magic-mouse-integration.md) | Runtime pass confirmed; core designs saved; next native reconciliation/accessibility. |
| [INPUT-013](tasks/INPUT-013-trackpad-review-fixes.md) | Current-bundle regression, external doubles/reconnect, false clicks, popup. |
| [REVIEW-001](tasks/REVIEW-001-production-review.md) | Remaining held-state/quit/glide safety; battery-menu keyboard/VoiceOver/macOS 26. |
| [DEVICE-003](tasks/DEVICE-003-multi-vendor-battery.md) | Named USB models, Bluetooth/BAS, reconnect, Logitech regression. |
| [DEVICE-002](tasks/DEVICE-002-device-names-discovery.md) | Rename/save/cancel/reset, G915/menu/reconnect, keyboard/VoiceOver. |
| [INPUT-011](tasks/INPUT-011-apps-mice-gesture-button.md) | Hold/background exclusion passed; directions, multi-mouse, reconnect/quit. |
| [INPUT-010](tasks/INPUT-010-smooth-scrolling.md) | Preserve user-confirmed feel/exclusions; Sketch review of smooth scrolling on Devices 36 remains. |
| [DEVICE-001](tasks/DEVICE-001-mouse-devices.md) | MX Master 2S subset passed; Options+, Bluetooth/Bolt, MX Master 3/3S. |
| [UI-023](tasks/UI-023-main-window-soft-adoption.md) | Keyboard focus, VoiceOver, all localized widths. |
| [INPUT-009](tasks/INPUT-009-held-output-exclusions-catalog.md) | Insert Text in three apps; interruption cleanup; remaining catalog/modifiers. |
| [UI-022](tasks/UI-022-soft-design-system.md) | Touch copy/status adopted; verify physical status, native accessibility and parity. |
| [UI-014](tasks/UI-014-trackpad-presets.md) | Physical coexistence/capture, keyboard/VoiceOver/preferences. |
| [INPUT-008](tasks/INPUT-008-magic-trackpad.md) | General external behavior user-confirmed; remaining named reconnect/timing/safety checks. |
| [INPUT-007](tasks/INPUT-007-trackpad-action-catalog.md) | Non-shortcut trackpad actions and brightness on hardware. |
| [INPUT-006](tasks/INPUT-006-trackpad-clicks.md) | Three-finger replacement passed; other counts, false clicks/settings. |
| [INPUT-005](tasks/INPUT-005-corner-taps.md) | Corners, Tap to click off/on, accidental palm contact. |
| [INPUT-004](tasks/INPUT-004-two-finger-double-tap.md) | Built-in subset passed; current-build/lone/external pairs, native conflicts. |
| [INPUT-003](tasks/INPUT-003-double-tap-engine.md) | Built-in three-finger double passed; four/external pairs, timing/safety. |
| [INPUT-002](tasks/INPUT-002-three-finger-tap.md) | Built-in delivery passed; current-build timing/accuracy and Look Up. |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | Physical timing; preserve confirmed focus/delivery/lifecycle subsets. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | Retest direct settings without duplicate alert; first-use listing/grant return, revocation and accessibility. |
| [UI-003](tasks/UI-003-general-settings.md) | Login/relaunch, VoiceOver/preferences on a named build. |
| [UI-004](tasks/UI-004-input-settings.md) | Physical hold timing/cancellation, editor VoiceOver/focus/preferences (Input tab retired in 1.2.0). |
| [UI-005](tasks/UI-005-language-settings.md) | Production reopen, Cocoa projection repair and accessibility. |
| [UI-007](tasks/UI-007-advanced-settings.md) | Preserve confirmed Advanced subset; remaining §15.12/platform/preferences. |
| [UI-010](tasks/UI-010-about.md) | VoiceOver/licenses, full keyboard and preferences. |
| [UI-009](tasks/UI-009-mouse-design.md) | Capture/timing/native accessibility of integrated styling. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | Fresh-bundle Dock/Menu Bar; tint and macOS 26 separately. |

Finished outcomes remain in [tasks](tasks/README.md) and [history](history/README.md). [DOC-003](tasks/DOC-003-context-maintenance.md) records the documentation/hygiene review; Claude Code loads AGENTS.md natively.
