# Rebind: current state

Updated **2026-10-26**, checkout `main`. The six-language app/website copy audit is implemented and locally verified in build 16 ([COPY-001](tasks/COPY-001-app-and-website-language.md)); English Sketch synchronization is saved/reviewed; publication remains separate. Next-release scope (PERF-001, ACTION-001, LIGHT-001) is unchanged. Inspect Git status on resume. Startup: [WORKFLOW](WORKFLOW.md) and [PLAN](PLAN.md).

## Product and current artifact

Native macOS **26+**, Swift 6 / SwiftUI/AppKit, scheme/module `rebind`, bundle `blinks44.rebind`. Recorded environment: Apple silicon macOS 27.0.1, Xcode 27.1 / Swift 6.4 / SDK 27. macOS 26/Intel execution remains unverified.

Rules/profiles/actions, per-app restrictions/exclusions, held outputs, mouse settings/batteries, atomic storage and six languages are implemented. Schema **44** (migrations 1–43). Both trackpad categories have **12 presets**; Magic Mouse has **six Experimental presets**, basic delivery tester-confirmed. Rules remain category-wide; profiles manual. [SPEC](SPEC.md), [CAPABILITIES](CAPABILITIES.md) and [DESIGN](DESIGN.md) own contracts, evidence and live Sketch locator.

Source/local package **1.0.0 (16)**: natural, technically accurate copy in all six languages; app builds, affected tests/layouts and signed packaging pass ([COPY-001](tasks/COPY-001-app-and-website-language.md)). DMG: `apps/rebind/build/release/Rebind-1.0.0-16.dmg`, with regenerated local appcast/checksums; not installed or published. Published **v1.0.0 remains build 15** (2026-10-24, tag `b3251fa`), whose downloaded appcast/DMG/checksum verified. Its [long-scrolling crash fix](history/2026-10.md#2026-10-24-input-tap-crash-after-long-scrolling) is retained; a long installed scrolling session remains open. Build 14 Settings icon user-confirmed 2026-10-24.

## Acceptance and remaining release work

Preserve tester acceptance: October 20 wheel/window/keyboard/recovery/update subsets ([FIX-001](tasks/FIX-001-wheel-and-window-regressions.md), done); October 21 build-10 first run and Finder/Chrome/ChatGPT actions ([FIX-002](tasks/FIX-002-window-action-compatibility.md), done), key backups; October 22 build-11 copy, VoiceOver, contrast/motion and minimum-width languages. [Release queue](verification/release-candidate.md) retains dates, unknown conditions and narrower outstanding cases. Do not request another accepted whole-app pass without affected changes.

[REL-005](tasks/REL-005-onboarding-and-updates.md) implements first run and Sparkle 2.10.0 daily updates; first update between published builds remains open. [SIGNING](SIGNING.md) owns Apple Development/non-notarized testing and recovery. Another-Mac, macOS 26, granted-profile CPU/latency, safety and targeted accessibility gates remain in [PLAN](PLAN.md#release-gates) and tasks. Earlier paused/no-grant ~1.5% CPU is not active-rule evidence.

Website iteration two at `apps/website/` implements the Sketch landing/404, responsive navigation, keycap demo, five device panels, features, privacy, installation and FAQ. Six-language SSR/SEO, moduix/CSS Modules and responsive WebP are ready. [COPY-001](tasks/COPY-001-app-and-website-language.md) corrects all six locales and Chinese device labels; final build, 15 tests and seven local Worker smoke tests pass. [WEB-001](tasks/WEB-001-landing-page.md) retains device/interaction/accessibility/download gates and earlier dry-run evidence. Indexing is on; Download uses the permanent `releases/latest/download/Rebind.dmg` link (currently v1.0.0 build 15). Copy changes, the Monny footer link and the permanent link await manual deployment. The 2026-10-25 public sitemap audit passed XML/alternates and seven HTTPS/SEO smoke tests; actual indexing is unverified. [USAGE](USAGE.md), [RELEASING](RELEASING.md) and [release notes](releases/1.0.0.md) own the public handoff; publication/deployment need authorization.

## Open task index

Finish current-menu/release checks; no new recognizers. Tasks own detailed acceptance/ownership; REL-003/004 preparation routes through the release queue.

| Task | Concrete next step |
| --- | --- |
| [COPY-001](tasks/COPY-001-app-and-website-language.md) | Build 16 copy and saved English Sketch ready; review changed installed app/website text at compact widths and with VoiceOver. Website deployment remains manual. |
| [PERF-001](tasks/PERF-001-background-wakeups.md) | Next release: measure, then cut the companion-app scan, per-frame glide checks and the 1 s audio wake. |
| [ACTION-001](tasks/ACTION-001-standard-actions.md) | Next release: fixed-shortcut entries, Apps, fast-forward/rewind, microphone mute. |
| [LIGHT-001](tasks/LIGHT-001-keyboard-lighting.md) | Next release: design ready (Sketch 66–68); first G915 write/persistence probe, then HID++ adapters and the Devices card. |
| [WEB-001](tasks/WEB-001-landing-page.md) | awaiting_verification: desktop/narrow Drawer/menu and 404 → home title checks passed; finish physical-phone/all-section, keyboard/VoiceOver, reduced motion and translations, future deployments remain manual; live HTTPS/SEO/crawler smoke passed 2026-10-25. |
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
