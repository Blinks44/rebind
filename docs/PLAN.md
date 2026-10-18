# Rebind: roadmap

Updated 2026-10-19. Read [STATE](STATE.md) first for current facts and the task table; [WORKFLOW](WORKFLOW.md) defines how to work; requirements are in [SPEC](SPEC.md); per-capability evidence is in [CAPABILITIES](CAPABILITIES.md). Nothing here is declared complete by a passing build alone.

## Where the product stands

The main planned functionality is implemented in software, with Magic Mouse limited to an experimental one/two-finger tap testing pool: keyboard and mouse rules, profiles, the action catalog, the full trackpad preset pool on the built-in trackpad and an external Magic Trackpad, Settings, onboarding, six languages, the website and the soft design system. Much of it still needs physical or running-app acceptance.

Out of scope by user decision: Caps Lock, Fn/Globe and left/right modifier distinction; primary and secondary mouse buttons as triggers; automatic profile activation (rules may be limited to one app since 2026-10-15; per-mouse attribution exists only for Devices settings); swipes, pinch and rotation. Pointer speed and acceleration are left to macOS because changing them would alter a system-wide setting.

## Next

1. **Finish the remaining acceptance and fix reproduced defects**: the [October 18 checklist](verification/manual-test-2026-10-18.md), received October 19, confirms G HUB/DPI/menu-slider behavior, idle/hold/repeat/background-scroll happy paths and built-in two/three-finger taps/three-finger click. Do not repeat these as wholly unverified. Next bounded engineering slice: Insert Text with Russian/emoji in TextEdit, Terminal and a browser, then keyboard traversal/focus through the main window, editor and Settings. Hardware follow-up: first trackpad single/double after idle; Magic Trackpad category separation, doubles/click safety and reconnect; built-in regression after the shared-adapter correction. Later external singles are separately confirmed. Preserve remaining held-output interruption, action/preset, device/battery and safety gates in their owning tasks.
2. **Magic Mouse**: [INPUT-014](tasks/INPUT-014-magic-mouse-integration.md) integrates the [hardware-observed](tasks/INPUT-012-magic-mouse-probe.md) one/two-finger stationary-tap candidates with rules, the shared catalog and a component-reused editor. The pre-test ownership finding is corrected with a failing-before/passing-after controller regression and rebuilt isolated bundle. Basic tap delivery is user-confirmed on 2026-10-19; native two-finger double tap also fires the single before Mission Control. User decision: keep fast singles and manually disable overlapping native gestures. Next verify timing, ordinary input/false positives, native-gesture settings, pause and reconnect on named hardware. Shared controls were reviewed against live Sketch; dedicated Magic Mouse editor/populated/recovery specimens remain undrawn. Swipes, holds, three/four-finger and native-double replacement remain research-gated. No broad app hardware-support claim yet (SPEC §3.5).
3. **Review follow-through**: [software/design review](tasks/REVIEW-001-production-review.md) completed with regression fixes and 52 paired Sketch screens. Complete the remaining lifecycle/held-state safety checks; G HUB and ordinary hold/repeat/background-scroll subsets now have user evidence. The native battery-menu row is implemented, with keyboard/VoiceOver/macOS 26 checks open. Revisit findings from runtime acceptance; German, French, Spanish and Simplified Chinese proofreading by fluent readers remains open.
4. **GitHub repository and update check**: the user publishes the repository (planned, 2026-10-13); then set the releases address, add a "Check for Updates" command that compares the running version with the latest release and opens its page, and fill `site.githubRepo` for the website download button. Releases are signed with one stable self-signed certificate, to retain signature identity; actual Accessibility-grant survival remains a release gate.
5. **Release preparation**: rehearse signed DMG install and an update over the previous build, verifying preserved rules and Accessibility access (manual item 5.3 remains blank); measure Release idle CPU. See all gates below.

## Release gates

- [ ] SPEC §15 acceptance walkthroughs with named OS and devices; every `awaiting_verification` task in STATE closed or explicitly limited.
- [ ] Safety: release/suppression ownership, Secure Input, permission revocation, sleep/lock recovery, emergency pause; measured callback and action latency.
- [ ] Accessibility: full keyboard navigation, VoiceOver, Increase Contrast, Reduce Motion/Transparency; all six languages at minimum window width.
- [ ] Known defect: residual search-field focus outline.
- [ ] Brand: live Dock tile and Menu Bar icon, tinted/clear appearances ([BRAND-001](tasks/BRAND-001-icon-runtime.md)).
- [ ] Platforms: macOS 26 execution; Intel only if claimed.
- [ ] Distribution: public GitHub repository; a DMG from `apps/rebind/scripts/release.sh` signed with the one stable self-signed certificate (not notarized, user decision) and published with its SHA-256; the Accessibility grant surviving an update installed over the previous build; `site.githubRepo`/`site.url` set and the website deployed. The license file is in place.

## Evidence routing

- [CAPABILITIES](CAPABILITIES.md): implemented, experimental and user-verified subsets with remaining checks.
- [research](research/README.md) and the [dependency register](research/DEPENDENCIES.md): mechanism decisions, sources and licenses.
- [tasks](tasks/README.md): open records with owners and next actions.
- [verification](verification/): behavior contracts, commands and walkthrough results that are still current.
- [history](history/README.md): dated outcomes and reasons; may describe superseded work.
