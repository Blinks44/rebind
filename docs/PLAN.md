# Rebind — roadmap

Updated 2026-10-13. Read [STATE](STATE.md) first for current facts and the task table; [WORKFLOW](WORKFLOW.md) defines how to work; requirements are in [SPEC](SPEC.md); per-capability evidence is in [CAPABILITIES](CAPABILITIES.md). Nothing here is declared complete by a passing build alone.

## Where the product stands

All planned functionality except Magic Mouse is implemented in software: keyboard and mouse rules, profiles, the action catalog, the full trackpad preset pool on the built-in trackpad and an external Magic Trackpad, Settings, onboarding, four languages and the soft design system. Much of it still needs physical or running-app acceptance.

Out of scope by user decision: Caps Lock, Fn/Globe and left/right modifier distinction; primary and secondary mouse buttons as triggers; physical-device inventory and automatic profile activation; swipes, pinch and rotation.

## Next

1. **Hardware acceptance of 2026-10-13 work** — built-in trackpad after the adapter refactor, Magic Trackpad discovery and gestures, Back/Forward, scroll and brightness actions, non-shortcut actions from trackpad rules. Tasks INPUT-005 … INPUT-008.
2. **Magic Mouse** — run `tools/magic-mouse-probe.swift` on the real device, then decide the supported presets, implement them and draw the screens. No implementation or hardware claim yet (SPEC §3.5).
3. **Review pass** — code, design and copy once the hardware findings are in; German and French proofreading by a fluent reader.
4. **Release preparation** — see the gates below.

## Release gates

- [ ] SPEC §15 acceptance walkthroughs with named OS and devices; every `awaiting_verification` task in STATE closed or explicitly limited.
- [ ] Safety: release/suppression ownership, Secure Input, permission revocation, sleep/lock recovery, emergency pause; measured callback and action latency.
- [ ] Accessibility: full keyboard navigation, VoiceOver, Increase Contrast, Reduce Motion/Transparency; EN/RU/DE/FR at minimum window width.
- [ ] Known defect: residual search-field focus outline.
- [ ] Brand: live Dock tile and Menu Bar icon, tinted/clear appearances ([BRAND-001](tasks/BRAND-001-icon-runtime.md)).
- [ ] Platforms: macOS 26 execution; Intel only if claimed.
- [ ] Distribution: Developer ID signing, notarization and a stable identity for TCC grants; license file; website.

## Evidence routing

- [CAPABILITIES](CAPABILITIES.md): implemented, experimental and user-verified subsets with remaining checks.
- [research](research/README.md) and the [dependency register](research/DEPENDENCIES.md): mechanism decisions, sources and licenses.
- [tasks](tasks/README.md): open records with owners and next actions.
- [verification](verification/): behavior contracts, commands and walkthrough results that are still current.
- [history](history/README.md): dated outcomes and reasons; may describe superseded work.
