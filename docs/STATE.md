# Rebind: current state

Updated **2026-10-28**, checkout `main`. The six-language app/website copy audit is implemented, locally verified and tester-accepted in build 16 ([COPY-001](tasks/COPY-001-app-and-website-language.md)); English Sketch synchronization is saved/reviewed; publication remains separate. Background-check optimizations are packaged/installed in build 17; a preliminary background CPU comparison is lower, with controlled/hardware verification still open. Standard actions and unconditional Fill with Left Margin are in build 20 and await targeted runtime verification; Build 25 retains G915 lighting and adds experimental compatible Logitech RGB keyboards/mice. Connected protocol checks pass; physical wake/reconnect acceptance and the native timer menu remain open. Build 26 frees held-output servicing during long Apple Shortcuts runs and adopts Swift Subprocess; installed acceptance remains open. Build 27 applies the October 26–27 commit review fixes (UI-only saves no longer clear unrelated errors, native Core Audio default-device lookup). Build 28 adds the G915 native idle-off timer and dormant trackpad capture without trackpad rules. Build 24 retains the saved Light/Dark dismissible red error banner and fixes blue-guidance dismissal clearing unrelated errors; installed keyboard/hover/VoiceOver/recovery verification remains open. Inspect Git status on resume. Startup: [WORKFLOW](WORKFLOW.md) and [PLAN](PLAN.md).

## Product and current artifact

Native macOS **26+**, Swift 6 / SwiftUI/AppKit, scheme/module `rebind`, bundle `blinks44.rebind`. Recorded environment: Apple silicon macOS 27.0.1, Xcode 27.1 / Swift 6.4 / SDK 27. macOS 26/Intel execution remains unverified.

Rules/profiles/actions, per-app restrictions/exclusions, held outputs, mouse settings/batteries, atomic storage and six languages are implemented. Schema **47** (migrations 1–46). Both trackpad categories have **12 presets**; Magic Mouse has **six Experimental presets**, basic delivery tester-confirmed. Rules remain category-wide; profiles manual. [SPEC](SPEC.md), [CAPABILITIES](CAPABILITIES.md) and [DESIGN](DESIGN.md) own contracts, evidence and live Sketch locator.

Source/local package **1.0.0 (28), schema 48** adds the [G915 idle timer](tasks/LIGHT-001-keyboard-lighting.md#native-idle-timer--2026-10-28), REVIEW-003 F3 and the [commit-review fixes](history/2026-10.md#2026-10-28-review-of-october-2627-commits) and keeps the build-25 experimental compatible Logitech RGB keyboards/mice ([LIGHT-001](tasks/LIGHT-001-keyboard-lighting.md)) and fixes long Shortcuts runs delaying held releases ([FIX-004](tasks/FIX-004-shortcuts-held-release.md)). The existing single asynchronous handoff keeps ordinary actions ordered; Swift Subprocess 1.0.2 replaces custom process transport. All **955 Swift Testing methods / 148 suites** pass. The unchanged native layout/navigation retains build-25 evidence (29 XCTest methods, two skipped across two runs); it was not rerun for this internal patch. Universal Release, app/DMG signing and image verification pass. Current DMG: `apps/rebind/build/release/Rebind.dmg`, SHA-256 `d1f3cd2474368c3a724d4386f9697741363365c24a94302fb718bcaed66c4978`. Checkpoint `7a6b224` commits the preceding RGB/error/review work. No installation/publication.

Build-24 error fixes remain in build 25: independent guidance/error dismissal, shared red banner, bounded menu errors and 30-second action-failure expiry ([FIX-003](tasks/FIX-003-menu-error-presentation.md)). Installed keyboard/hover/VoiceOver/recovery checks remain open. RGB support covers HID++ 0x8071 input devices; other brands/0x8070 need another backend. G915 protocol levels/on-off/injected battery recovery pass, while physical Shift wake, power-cycle/reconnect, actual G HUB/battery recovery and accessibility acceptance remain open. Native idle timing is preserved; its menu stays withheld because zero is not Never and preset/activity semantics need verification.

The 16 standard-action entries and unconditional **Fill with Left Margin** remain implemented ([ACTION-001](tasks/ACTION-001-standard-actions.md)); the action always reserves 220 logical points, independent of Stage Manager. Ordinary Fill is unchanged. Build-19 stable placement and build-20 unconditional behavior are tester-confirmed; detailed switching/display cases and the other new actions retain their task-owned gates.

Installed build **17** retains fewer companion scans, per-glide TCC authorization and notification-driven audio refresh ([PERF-001](tasks/PERF-001-background-wakeups.md)); general smoke tester-confirmed. Uncontrolled minute averages: 2.247% CPU (16) → 1.070% (17); controlled/hardware checks remain open. Build-16 copy is tester-accepted. Published **v1.0.0 remains build 15** (2026-10-24, tag `b3251fa`), with downloaded appcast/DMG/checksum verified. Its [long-scrolling crash fix](history/2026-10.md#2026-10-24-input-tap-crash-after-long-scrolling) is retained; a long installed scrolling session remains open. Build 14 Settings icon user-confirmed 2026-10-24.

## Acceptance and remaining release work

The [app architecture/library audit](tasks/REVIEW-003-libraries-and-simplification.md) is complete. Its P1 held-release scheduling finding is implemented/software-verified in build 26 ([FIX-004](tasks/FIX-004-shortcuts-held-release.md)); installed long-Shortcut/release/pause/quit verification remains. Its native Core Audio lookup (build 27) and dormant trackpad capture (F3, build 28) are implemented; F2 configuration transactions and device/catalog extraction are deliberately deferred (no measured problem, regression risk); no broad framework rewrite is planned.

Read-only [cursor-stutter triage](history/2026-10.md#2026-10-27-receiver-cursor-stutter-log-triage) on installed build 24 found no receiver/parent-hub entries in the two-hour query; wireless loss and the cause remain unverified. Next: receiver placement/adapter comparison and an exact recurrence time; no runtime settings were changed.

Preserve tester acceptance: October 20 wheel/window/keyboard/recovery/update subsets ([FIX-001](tasks/FIX-001-wheel-and-window-regressions.md), done); October 21 build-10 first run and Finder/Chrome/ChatGPT actions ([FIX-002](tasks/FIX-002-window-action-compatibility.md), done), key backups; October 22 build-11 copy, VoiceOver, contrast/motion and minimum-width languages. [Release queue](verification/release-candidate.md) retains dates, unknown conditions and narrower outstanding cases. Do not request another accepted whole-app pass without affected changes.

[REL-005](tasks/REL-005-onboarding-and-updates.md) implements first run and Sparkle 2.10.0 daily updates; first update between published builds remains open. [SIGNING](SIGNING.md) owns Apple Development/non-notarized testing and recovery. Another-Mac, macOS 26, granted-profile CPU/latency, safety and targeted accessibility gates remain in [PLAN](PLAN.md#release-gates) and tasks. Earlier paused/no-grant ~1.5% CPU is not active-rule evidence.

Website iteration two at `apps/website/` implements the Sketch landing/404, responsive navigation, keycap demo, five device panels, features, privacy, installation and FAQ. Six-language SSR/SEO, moduix/CSS Modules and responsive WebP are ready. [COPY-001](tasks/COPY-001-app-and-website-language.md) corrects all six locales and Chinese device labels; final build, 15 tests and seven local Worker smoke tests pass. [WEB-001](tasks/WEB-001-landing-page.md) retains device/interaction/accessibility/download gates and earlier dry-run evidence. Indexing is on; Download uses the permanent `releases/latest/download/Rebind.dmg` link (currently v1.0.0 build 15). Copy changes, the Monny footer link and the permanent link await manual deployment. The 2026-10-25 public sitemap audit passed XML/alternates and seven HTTPS/SEO smoke tests; actual indexing is unverified. [USAGE](USAGE.md), [RELEASING](RELEASING.md) and [release notes](releases/1.0.0.md) own the public handoff; publication/deployment need authorization.

## Open task index

Finish current-menu/release checks; no new recognizers. Tasks own detailed acceptance/ownership; REL-003/004 preparation routes through the release queue.

| Task | Concrete next step |
| --- | --- |
| [FIX-004](tasks/FIX-004-shortcuts-held-release.md) | awaiting_verification: build 26 uses one async Shortcuts slot and Swift Subprocess; 955 software methods/signing/DMG verification pass. Check actual long-Shortcut held release/order and pause/quit. |
| [FIX-003](tasks/FIX-003-menu-error-presentation.md) | Build 24 independent-guidance dismissal fix tested and packaged/verified. Saved Sketch 70 Light/Dark and native localized layout pass. Installed keyboard/VoiceOver/menu hover/unsupported-window recovery remains. |
| [PERF-001](tasks/PERF-001-background-wakeups.md) | Build 17 general installed smoke pass tester-confirmed; remaining evidence: controlled CPU/scrolling/typing and named companion/audio/protected-context checks. |
| [ACTION-001](tasks/ACTION-001-standard-actions.md) | awaiting_verification: build-20 Fill with Left Margin tester-confirmed; check other new actions and remaining switching/Dock/display cases. |
| [LIGHT-001](tasks/LIGHT-001-keyboard-lighting.md) | awaiting_verification: build 28 adds the G915 idle timer (no Never); check idle-off timing, key-press wake, Device default restore, then power-cycle/reconnect/G HUB/battery. |
| [WEB-001](tasks/WEB-001-landing-page.md) | awaiting_verification: hero icons and centered four-example mobile moduix Carousel with loop, four-second autoplay and pause implemented after live Sketch inspection (2026-10-26; check/build/15 tests/seven smoke cases pass; bounded 390 px Russian review). Finish narrow-width/physical-swipe acceptance and Sketch synchronization. Preserve remaining phone/accessibility/motion/translation gates; deployment remains manual. |
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

Rows route open evidence; preserve accepted paths. Finished outcomes remain in [tasks](tasks/README.md) and optional [history](history/README.md).

Claude Code uses native AGENTS.md loading (2.1.277+) and `.claude/skills`; no root CLAUDE.md adapter. Historical commit references can predate the October 22 attribution-only rewrite. [DOC-003](tasks/DOC-003-context-maintenance.md) records the latest documentation/hygiene review.
