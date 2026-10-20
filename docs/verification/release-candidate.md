# Release candidate: remaining acceptance

Updated 2026-10-20. This is the final-pass queue, not evidence that a release has passed. [PLAN](../PLAN.md) owns release gates; [CAPABILITIES](../CAPABILITIES.md) and the owning tasks retain detailed evidence and support limits.

## Tester report — 2026-10-20

After the final tester handoff and Release installation guidance, the user reports completing the checks successfully with no bugs found. Record this as a successful overall manual pass; do not request the same general walkthrough again without a reproduced defect or an affected code change. The report does not individually identify scenarios, artifact hash, OS/device/settings, CPU/latency values, VoiceOver or minimum-OS coverage. The report followed the supplied 1.0/1 candidate, not the later 1.0.0/2 copy audit; its installed hash was not independently confirmed. Detailed checkboxes below retain their evidence requirements; this report does not establish every platform/device combination.

Later October 20 testing found reversed button-wheel directions, a disappearing scrolled-list gap, an unwanted separate Settings window, lost window size and Stage Manager opening failure. [FIX-001](../tasks/FIX-001-wheel-and-window-regressions.md) owns the uncommitted fixes and scoped retest; the earlier general pass does not accept these changed paths.

Next: verify those five scenarios on an updated installed candidate, then prepare the release handoff, retaining separate checks for an update between two distinct stable-signer builds, macOS 26 and measured performance/accessibility evidence where not explicitly reported. First published-release update detection and website publication remain distribution work. No new app code or test run accompanies this report.

## Scoped follow-up — 2026-10-20

Tester confirms the wheel/card/settings/size fixes, working update preservation, keyboard navigation and sleep/pause/permission-loss recovery. After the build-7 Monny comparison, tester accepts improved repeated window opening and closes the regression for now; research/native evidence and exact report limits are in [FIX-001](../tasks/FIX-001-wheel-and-window-regressions.md). Exact installed build/hash unspecified. VoiceOver is untested. Keep current Apple Development signing for further tests; publication and website deployment are deferred until checks finish.

## Preserve existing acceptance

The user confirms general external-trackpad behavior, all six Magic Mouse gestures, and the earlier named ordinary-input/idle/edit/record/pause/reconnect smoke pass. G HUB/DPI, ordinary hold/repeat and background-scroll subsets are also reported. Do not repeat their entire feature inventory solely because UI focus changed. The compact-options fix and basic production-hierarchy editor/Settings/Command-N/F routes are verified in an engine-free live window (UI-024); profile creation/switching and deletion-cancel focus return also pass in disposable storage. The later REL-003 walkthrough also verifies Add/Edit invoking-control restoration and import/export panel cancellation/focus return. Full normal-build VoiceOver/preferences, actual file transactions and destructive operations remain separate. Affected layout suites now cover six languages in Light/Dark; fluent proofreading remains open.

## Identify the final artifact

Historical copy candidate: **Rebind 1.0.0 (2)**, `apps/rebind/build/release/Rebind-1.0.0-2.dmg`; SHA-256 `600bb69984f6b644da17305c225d01bcfd213ffa2f60da343862ea53c18c5917`. [REL-004](../tasks/REL-004-release-copy-and-documentation-audit.md) owns the copy/layout/site audit and signed package. The previous **1.0 (1)** DMG remains intact (hash `ee033c3f76247c8a929a11057694a95065ddb65c07f4ff93b451bb52909adccb`); [REL-003](../tasks/REL-003-final-app-readiness.md) owns its earlier 903 logic/25 native passes/two skips. Input logic was unchanged by the copy audit. That candidate used the old self-signed identity. Current candidate is **1.0.0 (3)**, SHA-256 `7441eda84b2465b1d89e8543097bbdccf24e6ad5a97a2681f93c9bbd2d2a023a`, with the shared Apple Development signer; [REL-001](../tasks/REL-001-signing-workflow.md#unified-default-pipeline-verified--2026-10-20) owns packaging and installation evidence. It is installed/running but native window/Accessibility/input verification remains open.

Before hardware acceptance, record version/build, Git revision plus uncommitted status, signed artifact hash, macOS build, Mac/input-device models and relevant native gesture/Natural Scrolling settings. UI-only Debug fixtures have mocked permission state, temporary configuration and no running input engine: they cannot prove permission or remapping acceptance. Preserve a configuration export outside the repository before installation/update tests.

## Remaining walkthrough

- [ ] **Window and editor:** on the normal final build, Tab/Shift-Tab traverse the sidebar, search, profiles, row switches/options, editor/action/application selectors and Settings. Verify arrows, Space, Enter/Escape, Record/Cancel, scrolling and focus return. Switch categories and confirm Command-N opens the current category; verify local Command-F. Run VoiceOver, Increase Contrast and Reduce Motion/Transparency. UI-024 owns scope/evidence.
- [ ] **Text actions:** insert Russian text and emoji in TextEdit, Terminal and a browser. Check foreground-app restrictions and unchanged clipboard semantics. INPUT-009 owns unresolved catalog checks.
- [ ] **Interruption safety:** release an active held shortcut/modifier through pause, quit, sleep/lock, device disconnect and permission loss; no stuck keys/buttons or stranded scroll tail. Unmatched ordinary input must keep working. Verify emergency pause and clean recovery; REVIEW-001/002 and INPUT-009/014/015 own detailed cases.
- [ ] **Touch edges:** first single/double after idle; remaining unverified double/click/settings combinations; both Natural Scrolling settings for the new mouse directions, ambiguous-start native passthrough, pause during click/momentum, reconnect and mixed mouse/trackpad input. Preserve confirmed basic delivery; do not expand the preset pool.
- [ ] **Distribution:** install the signed DMG, then replace an older signed build. Rules/profiles and actual Accessibility access survive; restart/login follows settings. Check direct permission-settings opening without a duplicate alert and revocation recovery. REL-001/002 and UI-001 own evidence.
- [ ] **Platform and performance:** execute on macOS 26; claim Intel only after testing. Measure Release idle CPU and callback/action latency. Review current Dock/Menu Bar/tinted icon and the battery menu keyboard/VoiceOver route. Unsupported hardware claims must remain limited.
- [ ] **Release preparation:** six-choice mouse menu/behavior source reconciliation is saved and reviewed (INPUT-015, October 20); review all six languages at minimum widths and obtain fluent proofreading where still open. Freeze/fix/verify, then prepare the final signed package. Public GitHub is verified and the manual update command is implemented (REL-003); first actual newer-release delivery, website links and publication remain open. Publication is a separate user-directed action.

Mark an item passed only with an identified artifact and the exercised scenarios. When a check fails, repair the reproduced defect and repeat the affected checks; preserve earlier unrelated passes. Outstanding device/battery model coverage stays in its owning task or is explicitly excluded from release claims.


## Ordered tester pass on the supplied candidate

This is the retained scenario reference for unreported details, not a request to repeat the successful whole-app pass. For the copy candidate, prioritize the distinct same-signer update and affected wording/layout smoke check.

1. Export the current configuration in Advanced and keep it outside the repository. Quit the installed app, install the supplied DMG into Applications and launch that copy. Confirm rules/profiles survived. The current build 3 changes from Rebind Release to shared Apple Development and may need regrant; it cannot prove same-signer permission preservation. Test that with two subsequent Apple Development builds. Do not disable Gatekeeper or change system-wide security settings.
2. Use only the keyboard through categories, Settings, profile manager, Add/Edit/action/application selectors and Record/Cancel. Tab/arrows/Space/Enter/Escape should work, and closing editors should return focus. Check for grey options bezels or persistent search outlines. In Rebind → Check for Updates, no published release currently produces the explicit no-release message.
3. Insert a short Russian/emoji sample into TextEdit, Terminal and a browser field through a test rule. Confirm the clipboard is preserved and app restrictions hold. Do not execute the inserted Terminal text as a command.
4. After a quiet minute, test the first trackpad single/double and external reconnection/category separation. For the new mouse scroll directions, test both Natural Scrolling settings, one action per stroke, pause during motion/momentum and ordinary one-finger passthrough. Preserve already confirmed basic gesture delivery.
5. Exercise an active held output through pause/quit, sleep/lock, device disconnect and permission revocation; no stuck modifier/button or scroll tail. Confirm emergency pause and recovery. In Activity Monitor, observe the installed Release with real grants/normal rules after idle; the isolated paused benchmark is not that gate.
6. Run VoiceOver (Command-F5), check named controls, states and logical reading/focus; test Increase Contrast and Reduce Motion/Transparency, then restore preferred settings. Check Dock/Menu Bar artwork. Test macOS 26 on an available machine before claiming that platform; Intel only if claimed.

Report candidate hash, OS/device models and native settings, followed by passed/failed/not-tested per item. For failures include steps and the observed/expected result; do not attach actual configuration or input content to a public issue.
