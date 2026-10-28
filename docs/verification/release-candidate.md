# Release candidate: remaining acceptance

Updated 2026-10-26. [STATE](../STATE.md) identifies the latest source/package; [PLAN](../PLAN.md#release-gates) owns release gates. This queue preserves reported passes and routes unverified details, rather than requesting another full walkthrough.

## Tester report — 2026-10-20

Tester reports completing the overall manual pass with no bugs found. Exact installed hash, environment, measurements and individual scenario matrix were not supplied; do not infer minimum-OS/device/accessibility certification. This followed the earlier 1.0/1 candidate. Later wheel/window regressions were repaired and separately accepted in [FIX-001](../tasks/FIX-001-wheel-and-window-regressions.md); that bounded task is done.

## Scoped follow-up — 2026-10-20

Tester confirms wheel/card/settings/size, update preservation, keyboard navigation, sleep/pause/permission-loss recovery and improved repeated opening after build 7. Exact installed build/hash and cycle matrix unspecified. Preserve this acceptance; broader platform/per-control cases stay qualified.

## Subsequent acceptance — 2026-10-21–22

- Installed build 10: first-run walkthrough and actual Button 5 + down window actions in Finder/Chrome/ChatGPT accepted; [FIX-002](../tasks/FIX-002-window-action-compatibility.md) is done. Signing-key restore/off-device and EdDSA backup tester-confirmed.
- Installed build 11 (October 22): changed copy, VoiceOver, Increase Contrast, Reduce Motion and languages at minimum width accepted. Exact environment and individual controls/preferences were not supplied. Do not label VoiceOver wholly untested or request the same overall pass again; targeted remaining cases retain their own limits.
- Build 14 changes Settings menu imagery after build 13 failed in the installed app. On 2026-10-24 the user confirmed the Settings icon in the installed build-14 menu; environment unspecified. Command-comma and menu VoiceOver were not separately reported. [Native controller/packaging evidence](../history/2026-10.md#2026-10-23-align-settings-symbol-with-monny).
- Current build 15 fixes the input-tap crash after long wheel use (smooth scrolling on) and the matching HID++ notification path; build 14 menu acceptance carries over. Needs a long scrolling session on the installed build. [Evidence](../history/2026-10.md#2026-10-24-input-tap-crash-after-long-scrolling).

## Copy follow-up — 2026-10-26

The user confirms the requested targeted app/website copy review for build 16 ([COPY-001](../tasks/COPY-001-app-and-website-language.md), done). Exact environment and individual locale/width/VoiceOver cases were not supplied. Preserve this acceptance without reopening the overall copy pass; deployment and other release gates remain separate.

## Performance follow-up — 2026-10-26

[PERF-001](../tasks/PERF-001-background-wakeups.md) build 17 passes full tests and signed packaging. Its installed executable matches the package, with Accessibility/event-posting grants and rules enabled. Preliminary uncontrolled background averages: build 16 2.247% CPU, build 17 1.070%. The user subsequently reports successful checking and normal operation so far; preserve this general build-17 smoke pass. Duration and individual scenarios were not specified. Controlled one-minute idle/physical-scroll/typing, companion/helper detection, audio output switching and protected-context/held-release checks remain open; no latency or wakeup reduction is certified by these samples.

## Preserve existing feature acceptance

General external-trackpad behavior, all six Magic Mouse gestures, ordinary-input/idle/edit/record/pause/reconnect smoke, G HUB/DPI, ordinary hold/repeat and pointer-window scroll exclusions have tester-confirmed subsets. The [October 18 record](manual-test-2026-10-18.md) and owning tasks retain exact limits. Do not repeat their full inventories because unrelated UI code changed.

Disposable no-engine production-hierarchy fixtures cover compact menus, editor/Settings/Command-N/F routes, profile creation/switching, deletion cancellation, Add/Edit focus return and import/export panel cancellation. These prove sampled UI paths, not permission/remapping behavior, actual file transactions or all normal-build accessibility. Six-language Light/Dark layouts pass; fluent proofreading remains separate.

## Identify the artifact before new verification

Use the latest package and checksum linked from STATE, never an old copy candidate described as current. Record version/build, Git revision plus uncommitted status, artifact hash, macOS build, input-device models and relevant native gesture/Natural Scrolling settings. Unknown conditions remain unknown. Preserve configuration exports outside the repository; never attach actual rules or typed input to public issues.

Apple Development signing superseded the old self-signed build-1/2 candidate in build 3. A signer transition may need regrant and cannot establish same-signer update preservation. Tester reports subsequent update preservation; the exact old/new artifact pair remains unspecified. [SIGNING](../SIGNING.md) owns the current identity/recovery procedure.

## Remaining targeted checks

| Area | Open evidence / owner |
| --- | --- |
| Current menu | Installed build-14 Settings icon user-confirmed 2026-10-24; Command-comma, keyboard/VoiceOver in the actual mixed battery/slider menu. Keep earlier build-11 general accessibility acceptance. [UI-024](../tasks/UI-024-keyboard-navigation.md), [menu change](../history/2026-10.md#2026-10-23-align-settings-symbol-with-monny). |
| Accessibility details | Unreported per-control focus return, import/export/actual transactions, Reduce Transparency, first-run and battery-menu routes, fluent six-language proofreading. Existing broad build-11 pass remains valid within its reported scope. [UI-024](../tasks/UI-024-keyboard-navigation.md), [REL-005](../tasks/REL-005-onboarding-and-updates.md) and affected UI tasks. |
| Original actions and Phase 2 inputs | Happy paths user-confirmed 2026-10-09; detailed cases not restated: fault/cancellation/latency for opening, Shortcuts prompts, sleep wake-on-release, lock/Dock private paths, Spaces shortcut dependency, media recipient, mouse output, window layout/cycle/switching, wheel/double/hold/pointer timing and lifecycle/disconnect. Retired reports in Git (`19c7b1d`); see [implementation history](../history/implementation-through-2026-10-10.md). |
| Text actions | Russian/emoji insertion in TextEdit, Terminal and browser; clipboard and foreground-app restrictions. Do not execute inserted Terminal content. [INPUT-009](../tasks/INPUT-009-held-output-exclusions-catalog.md). |
| Interruption safety | Detailed active-held-output pause/quit/sleep/lock/disconnect/grant-loss combinations, unmatched passthrough, scroll-tail ownership, emergency pause and clean recovery. Preserve accepted general sleep/pause/permission-loss subsets. [REVIEW-001](../tasks/REVIEW-001-production-review.md), [REVIEW-002](../tasks/REVIEW-002-idle-energy.md), INPUT-009/014/015. |
| Touch edges | First single/double after idle; remaining double/click/native-setting combinations; both Natural Scrolling settings, ambiguous-start passthrough, click/momentum interruption, reconnect and mixed devices. Preserve confirmed basic delivery; no preset expansion. [INPUT-015](../tasks/INPUT-015-touch-release-scope.md) and related input tasks. |
| Permissions/distribution | Another-Mac/current-signature installation; exact distinct same-signer update pair, restart/login; direct Accessibility settings without duplicate alert, first-use listing and revocation. Existing tester update preservation is retained. [REL-001](../tasks/REL-001-signing-workflow.md), [UI-001](../tasks/UI-001-permissions-onboarding.md). |
| Platforms/performance | Execute macOS 26; Intel only if claimed. Real-grant normal-profile Release CPU and callback/action latency, current Dock/Menu Bar/tint appearance and named battery models. Paused/no-grant ~1.5% CPU is not active-rule evidence. [REL-003](../tasks/REL-003-final-app-readiness.md), REVIEW-001/002, device tasks and [BRAND-001](../tasks/BRAND-001-icon-runtime.md). |
| Public release/update/site | v1.1.0 (31) source/tag/package/public latest DMG/checksum/appcast and EdDSA verification pass ([REL-006](../tasks/REL-006-release-1.1.0.md)). Remaining: first Sparkle offer/verification/install/relaunch between the two published builds with rules/access kept. Finish six-locale website design/download review. [REL-005](../tasks/REL-005-onboarding-and-updates.md), [WEB-001](../tasks/WEB-001-landing-page.md), [RELEASING](../RELEASING.md). Publication/deployment require explicit authorization. |

For a new defect, repair and repeat the affected checks while preserving unrelated passes. Mark a gate passed only for the identified artifact/scenarios, or explicitly limit the corresponding support claim. Future testing needs only the applicable rows, not another mandatory whole-app pass.
