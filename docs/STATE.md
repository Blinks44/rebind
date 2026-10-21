# Rebind: current state

Updated **2026-10-21**. Baseline `main` `86c9e92` `7aa1a7d` (first run and Sparkle, [REL-005](tasks/REL-005-onboarding-and-updates.md)) plus the uncommitted build-10 review fixes. No publication. Startup: [WORKFLOW](WORKFLOW.md) and [PLAN](PLAN.md).

## Product and evidence

Native macOS **26+**, Swift 6 / SwiftUI/AppKit. Scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Current environment: Xcode 27.1 / Swift 6.4 / SDK 27, Apple silicon macOS 27.0.1. Minimum-OS and Intel execution remain unverified.

Rules/profiles/actions, per-app restrictions/exclusions, held outputs, mouse settings/batteries and atomic storage are implemented. Schema **44**, migrations 1–43. Trackpads retain **12 presets per category**; Magic Mouse has **six Experimental tap/click/vertical-scroll presets**, with basic delivery user-confirmed. Rules are category-wide; physical-device attribution is only for mouse settings. No automatic profile selection. Soft styling and six languages are integrated. [SPEC](SPEC.md) owns contracts; [CAPABILITIES](CAPABILITIES.md) owns tested subsets/limits.

The earlier October 20 overall manual pass is preserved; later testing found five wheel/window/layout regressions, now owned by [FIX-001](tasks/FIX-001-wheel-and-window-regressions.md). Preserve that acceptance and do not repeat the whole walkthrough without an affected change. Artifact/environment and individual scenario coverage remain unspecified: see [release queue](verification/release-candidate.md#tester-report--2026-10-20). Earlier named October 18 hardware results remain in [their record](verification/manual-test-2026-10-18.md).

## Current release work

Source is **1.0.0 (11)** (build 11: [final pre-release review](history/2026-10.md#2026-10-21-final-pre-release-review), six-language copy fixes; verified DMG `apps/rebind/build/release/Rebind-1.0.0-11.dmg`; build 10 reviewed the October 17–21 changes): [REL-005](tasks/REL-005-onboarding-and-updates.md) adds the three-step first run (Welcome, Access, Ready) designed in Sketch and replaces the manual GitHub checker with Sparkle 2.10.0 (daily checks by default, EdDSA-signed appcast written by release.sh, key in the login keychain). User confirmed on installed build 10 (2026-10-21): first-run walkthrough, FIX-002 window actions (Button 5 + down in Finder/Chrome/ChatGPT) and off-device signing/EdDSA key backups. The first end-to-end update between two published builds is open.

Build 8: [FIX-002](tasks/FIX-002-window-action-compatibility.md) replaces the failing Chrome/ChatGPT system-wide AX focused-app query with AppKit PID discovery plus direct AXFrontmost validation. Debug/Release packaging and 42 focused software functions pass. Verified local DMG: `apps/rebind/build/release/Rebind-1.0.0-8.dmg`; native execution and Button 5 + down remain open. Installed app is build 7. AGENTS/WORKFLOW and the local workflow skill now require this DMG handoff after app changes; the user installs manually.

[FIX-001](tasks/FIX-001-wheel-and-window-regressions.md) retains tester acceptance of wheel/card/settings/geometry, update preservation, keyboard navigation, sleep/pause/permission loss and improved build-7 foreground opening (Monny activation-before-show/window reuse; six native functions pass). Exact accepted artifact/cycle matrix unspecified; VoiceOver remains open. Current Apple Development testing continues; publication/site deferred.

[REL-004](tasks/REL-004-release-copy-and-documentation-audit.md) owns the pre-release wording/feature-gap/documentation audit and historical **1.0.0 (2)** copy candidate; [REL-001](tasks/REL-001-signing-workflow.md) introduced shared Apple Development signing in build 3. Six-language copy, claims and docs are reconciled; no critical new input feature was identified. [USAGE](USAGE.md), [RELEASING](RELEASING.md) and [release notes](releases/1.0.0.md) provide the user/maintainer handoff. Website: `Blinks44/rebind` / `rebind.moduix.dev`, **not deployed**. Download needs a stable DMG. Browser visual review remains separate from local SSR/build checks.

Earlier implementation evidence: [REL-003](tasks/REL-003-final-app-readiness.md) owns the 1.0/1 candidate, 903 logic passes and 25 native passes/two skips. Its rejected polling experiments did not improve isolated paused/no-grant CPU (~1.5%); granted normal-profile performance stays open. [UI-024](tasks/UI-024-keyboard-navigation.md) owns keyboard/menu/focus repair; [INPUT-015](tasks/INPUT-015-touch-release-scope.md) owns the finite touch pool and [DESIGN](DESIGN.md) locates saved Sketch. Prior dated details remain in these tasks and [history](history/2026-10.md).

[REL-001](tasks/REL-001-signing-workflow.md) aligns release.sh with Monny: one pinned existing **Apple Development** identity, DMG-only build/release output, readable bundle modes. Historical build-3 installation/smoke evidence stays in its record; the installed app is now build 7, with build-8 compatibility verification in FIX-002. The old self-signed key/backups are retained; the current shared P12 is now exported; restore/signing verification and off-device copy remain open: [SIGNING](SIGNING.md). [REL-002](tasks/REL-002-branded-dmg.md) owns the DMG artwork/Finder check. Update preservation needs two distinct stable-signed installed builds, separate from an Xcode/ad-hoc signer transition.

## Open task index

Priority: publish v1.0.0, then remaining accessibility/platform/distribution checks and [release gates](PLAN.md#release-gates). No new recognizers. Records below retain `awaiting_verification` unless stated otherwise; ownership is in REL-004. Preserve general tester acceptance and detailed limits.

| Task | Concrete next step |
| --- | --- |
| [REL-005](tasks/REL-005-onboarding-and-updates.md) | Publish v1.0.0 with appcast; verify the update path with the next build; first-run accessibility/locales. |
| [REL-001](tasks/REL-001-signing-workflow.md) | Preserve the signer; key restore/off-device copy user-reported done; another-Mac/current-signature installation. |
| [REL-004](tasks/REL-004-release-copy-and-documentation-audit.md) | Copy audit preserved; FIX-002 owns build-8 compatibility verification with the REL-001 signer. |
| [REL-003](tasks/REL-003-final-app-readiness.md) | Overall tester pass preserved; REL-004 owns the newer copy candidate. Same-signer/platform checks remain. |
| [INPUT-015](tasks/INPUT-015-touch-release-scope.md) | Preserve six-gesture delivery; remaining settings/safety matrix. Source reconciled. |
| [UI-024](tasks/UI-024-keyboard-navigation.md) | Normal-build VoiceOver/preferences, import/export and exact editor focus return; disposable profile/confirmation paths pass. |
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


Each row routes remaining evidence, not a request to rerun every accepted happy path. Concrete release procedure: [RELEASING](RELEASING.md). Broader platform/device claims require new evidence; retain explicit limits meanwhile.
