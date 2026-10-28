# Rebind: current state

Updated **2026-10-28**, checkout `main`. Release candidate **1.1.0 (31)**, schema **48**; published v1.0.0 is build 15. Inspect Git status on resume. Startup: [WORKFLOW](WORKFLOW.md) and [PLAN](PLAN.md).

## Product and current artifact

Native macOS **26+**, Swift 6 / SwiftUI/AppKit, scheme/module `rebind`, bundle `blinks44.rebind`. Recorded environment: Apple silicon macOS 27.0.1, Xcode 27.1 / Swift 6.4 / SDK 27; macOS 26/Intel execution unverified.

Rules/profiles/actions, per-app restrictions/exclusions, held outputs, mouse settings/batteries, experimental Logitech RGB lighting, atomic storage and six languages are implemented. Both trackpad categories have **12 presets**; Magic Mouse has **six Experimental presets**. Rules remain category-wide; profiles manual. [SPEC](SPEC.md), [CAPABILITIES](CAPABILITIES.md) and [DESIGN](DESIGN.md) own contracts, evidence and the live Sketch locator.

Build **30** fixes G915 idle-off using native inactivity/activity notifications and explicit power commands ([LIGHT-001](tasks/LIGHT-001-keyboard-lighting.md#installed-idle-off-failure-and-event-driven-fix--2026-10-28)); it retains the build-29 [copy pass](tasks/COPY-001-app-and-website-language.md#follow-up-pass--2026-10-28). Final **966 Swift Testing methods / 148 suites** pass; unchanged native UI: 29 XCTest methods, two skipped, zero failures. App/DMG signing and image verification pass. DMG `apps/rebind/build/release/Rebind.dmg`, SHA-256 `0ce06e4d32c5fff126843996deae0cbef1f05d0bcf83c9fdeb2848602815e4f6`. No agent installation or publication. After the build-30 handoff, the tester confirms automatic lighting-off and key-press wake now work.

Builds 16–28 added the copy audit, background-check optimization ([PERF-001](tasks/PERF-001-background-wakeups.md)), standard actions ([ACTION-001](tasks/ACTION-001-standard-actions.md)), the error banner ([FIX-003](tasks/FIX-003-menu-error-presentation.md)), G915/RGB lighting and idle timer ([LIGHT-001](tasks/LIGHT-001-keyboard-lighting.md)), the Shortcuts held-release fix ([FIX-004](tasks/FIX-004-shortcuts-held-release.md)) and [review fixes](history/2026-10.md#2026-10-28-review-of-october-2627-commits). Their installed/hardware acceptance stays in those tasks.

Build-24 error fixes remain in build 25: independent guidance/error dismissal, shared red banner, bounded menu errors and 30-second action-failure expiry ([FIX-003](tasks/FIX-003-menu-error-presentation.md)). Installed keyboard/hover/VoiceOver/recovery checks remain open. RGB support covers HID++ 0x8071 input devices; other brands/0x8070 need another backend. G915 protocol levels/on-off/injected battery recovery pass, while power-cycle/reconnect, actual G HUB/battery recovery and accessibility acceptance remain open. Build 30 explicitly controls lighting power from the G915's native idle/activity notifications; no host keyboard monitor or polling is used. Native PowerOff alone left white lighting on in build 28; the tester confirms explicit off extinguishes it. Device default restores the captured policy and owned power/event bits; Never remains hidden. Automatic off and key-press wake are tester-confirmed; default/reconnect acceptance stays in LIGHT-001.

## Acceptance and remaining release work

The [architecture/library audit](tasks/REVIEW-003-libraries-and-simplification.md) is complete; F2 configuration transactions and device/catalog extraction are deliberately deferred. [Cursor-stutter triage](history/2026-10.md#2026-10-27-receiver-cursor-stutter-log-triage) found no receiver entries; cause unverified, next is a receiver placement comparison with an exact recurrence time.

Preserve tester acceptance: October 20 wheel/window/keyboard/recovery/update ([FIX-001](tasks/FIX-001-wheel-and-window-regressions.md)), October 21 first run and window actions ([FIX-002](tasks/FIX-002-window-action-compatibility.md)), October 22 build-11 copy/VoiceOver/contrast/widths, build-16 copy, build-17 smoke. The [release queue](verification/release-candidate.md) owns the narrower outstanding cases; do not request another whole-app pass without affected changes.

[REL-005](tasks/REL-005-onboarding-and-updates.md) implements first run and Sparkle daily updates; the first update between published builds remains open. [SIGNING](SIGNING.md) owns non-notarized signing and recovery. Another-Mac, macOS 26, granted-profile CPU/latency, safety and accessibility gates are in [PLAN](PLAN.md#release-gates).

Website: `apps/website/` is live at rebind.moduix.dev ([WEB-002](tasks/WEB-002-website-refresh.md), closed); the build-29 copy changes are not deployed yet. Shared shell with Monny: [SPEC §17](SPEC.md#17-public-website). Publication/deployment need authorization ([RELEASING](RELEASING.md)).

Publication of 1.1.0 (31) is authorized and in progress: [REL-006](tasks/REL-006-release-1.1.0.md). Build-30 artifact evidence above remains historical until the new package is verified.

## Open task index

| Task | Concrete next step |
| --- | --- |
| [COPY-001](tasks/COPY-001-app-and-website-language.md) | Review build-29 strings and the local site, deploy the website, sync changed English strings to Sketch. |
| [FIX-004](tasks/FIX-004-shortcuts-held-release.md) | Check installed long-Shortcut held release/order and pause/quit (build 26 fix). |
| [FIX-003](tasks/FIX-003-menu-error-presentation.md) | Installed keyboard/VoiceOver/menu hover/unsupported-window recovery (build 24 fix). |
| [PERF-001](tasks/PERF-001-background-wakeups.md) | Controlled CPU/scrolling/typing and companion/audio/protected-context checks. |
| [ACTION-001](tasks/ACTION-001-standard-actions.md) | Other new actions and switching/Dock/display cases; Fill with Left Margin confirmed. |
| [LIGHT-001](tasks/LIGHT-001-keyboard-lighting.md) | awaiting_verification: automatic off and key-press wake tester-confirmed after the build-30 handoff; next Device default/relaunch/reconnect/G HUB. Other physical gates remain. |
| [REL-005](tasks/REL-005-onboarding-and-updates.md) | v1.0.0 published; verify the update path with the next build (1.0.1); first-run accessibility/locales. |
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
| [INPUT-010](tasks/INPUT-010-smooth-scrolling.md) | Preserve user-confirmed feel/exclusions; Sketch 42/44/45 review remains. |
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
| [UI-004](tasks/UI-004-input-settings.md) | Physical hold timing/cancellation, VoiceOver/focus/preferences. |
| [UI-005](tasks/UI-005-language-settings.md) | Production reopen, Cocoa projection repair and accessibility. |
| [UI-007](tasks/UI-007-advanced-settings.md) | Preserve confirmed Advanced subset; remaining §15.12/platform/preferences. |
| [UI-010](tasks/UI-010-about.md) | VoiceOver/licenses, full keyboard and preferences. |
| [UI-009](tasks/UI-009-mouse-design.md) | Capture/timing/native accessibility of integrated styling. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | Fresh-bundle Dock/Menu Bar; tint and macOS 26 separately. |

Finished outcomes remain in [tasks](tasks/README.md) and [history](history/README.md). [DOC-003](tasks/DOC-003-context-maintenance.md) records the documentation/hygiene review; Claude Code loads AGENTS.md natively.
