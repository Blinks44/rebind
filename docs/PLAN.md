# Rebind: roadmap

Updated 2026-10-16. Read [STATE](STATE.md) first for current facts and the task table; [WORKFLOW](WORKFLOW.md) defines how to work; requirements are in [SPEC](SPEC.md); per-capability evidence is in [CAPABILITIES](CAPABILITIES.md). Nothing here is declared complete by a passing build alone.

## Where the product stands

All planned functionality except Magic Mouse is implemented in software: keyboard and mouse rules, profiles, the action catalog, the full trackpad preset pool on the built-in trackpad and an external Magic Trackpad, Settings, onboarding, six languages, the website and the soft design system. Much of it still needs physical or running-app acceptance.

Out of scope by user decision: Caps Lock, Fn/Globe and left/right modifier distinction; primary and secondary mouse buttons as triggers; automatic profile activation (rules may be limited to one app since 2026-10-15; per-mouse attribution exists only for Devices settings); swipes, pinch and rotation. Pointer speed and acceleration are left to macOS because changing them would alter a system-wide setting.

## Next

1. **Hardware/runtime acceptance of integrated work**: built-in trackpad after the adapter refactor, Magic Trackpad discovery and gestures, Back/Forward, scroll and brightness actions, non-shortcut actions from trackpad rules. Held output, modifier holds, wheel, excluded apps and the new actions. Include newer per-app/per-mouse/gesture-button and Devices/battery checks: INPUT-005–011, DEVICE-001–003.
2. **Magic Mouse**: up to four raw contacts and one completed three-contact rest/release in the standalone probe are user-verified on 2026-10-16 ([INPUT-012](tasks/INPUT-012-magic-mouse-probe.md)). Named one/two-finger taps separate from scroll movement in this sample. Next validate recognition/false-positive safety/coexistence, decide supported presets, implement them and draw the screens. App gesture support remains unverified (SPEC §3.5).
3. **Review follow-through**: [software/design review](tasks/REVIEW-001-production-review.md) completed with regression fixes and 52 paired Sketch screens. Verify those fixes on hardware; the native battery-menu row is implemented, with keyboard/VoiceOver/macOS 26 checks open. Revisit findings from runtime acceptance; German, French, Spanish and Simplified Chinese proofreading by fluent readers remains open.
4. **GitHub repository and update check**: the user publishes the repository (planned, 2026-10-13); then set the releases address, add a "Check for Updates" command that compares the running version with the latest release and opens its page, and fill `site.githubRepo` for the website download button. Releases are signed with one stable self-signed certificate, to retain signature identity; actual Accessibility-grant survival remains a release gate.
5. **Release preparation**: see the gates below.

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
