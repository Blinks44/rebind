# Rebind: roadmap

Updated 2026-10-20. [STATE](STATE.md) indexes current work; [SPEC](SPEC.md) owns behavior and [CAPABILITIES](CAPABILITIES.md) owns evidence. Builds and general confirmations do not establish every hardware/platform case.

## Current release scope

The planned app functionality and English soft-design source are implemented: keyboard/mouse remapping, shared actions, profiles, per-app rules, settings, device/scrolling support and six languages. Both trackpad categories have 12 presets; Magic Mouse has six Experimental tap/click/vertical-scroll presets. The user confirms a successful overall final manual pass with no bugs found. Do not repeat accepted basic gesture tests as wholly unverified.

[REL-004](tasks/REL-004-release-copy-and-documentation-audit.md) completes pre-release copy/docs/site cleanup and prepared the earlier copy candidate 1.0.0 (2); [REL-001](tasks/REL-001-signing-workflow.md) now supplies the shared-development-signed 1.0.0 (3), installed and running. The gap review finds no critical missing input feature requiring another recognition mechanism. Starter presets and window-position undo are possible post-release research topics, not approved additions. Keep the current pool and verified engine stable; fix reproduced defects.

Outside current scope: Caps Lock, Fn/Globe and left/right modifier distinction; modifier-only triggers; ordinary primary/secondary mouse buttons as triggers (except attributed Magic Mouse three-finger click); physical-device rules, automatic profiles and touch swipes/pinch/rotation. Pointer speed/acceleration remain macOS settings; supported Logitech sensor DPI is a separate hardware feature. [INPUT-015](tasks/INPUT-015-touch-release-scope.md) owns the settled finite touch decision.

## Next

1. **Review the copy candidate:** retain the user's earlier pass, verify affected wording/layout and a short smoke pass only. English Sketch and all six app/site languages are audited; fluent-reader review and full VoiceOver/preferences evidence remain separately qualified. Copy evidence belongs to REL-004; current signing/package and installation evidence belong to REL-001.
2. **Rehearse a distinct same-signer update:** first verify build 3 Accessibility/input, then export configuration and replace it with a subsequent Apple Development build; verify rules/profiles and actual access. The old Rebind Release → Apple Development transition may require regrant and does not establish update preservation.
3. **Resolve support claims:** test macOS 26 on an available Mac; keep Intel unverified unless actually tested. Retain task-specific hardware/safety limits and report real-grant normal-profile CPU/latency only when measured. The old isolated paused/no-grant CPU result (~1.5%) is not active-rule performance.
4. **Publish deliberately:** review/commit source, match tag/version, rebuild/final-check the signed DMG, upload DMG + checksums in a GitHub draft, then publish a stable release and verify download/update discovery. The repository is public; no published release existed at last check. `site.githubRepo`/`site.url` are configured; website deployment follows the DMG. [RELEASING](RELEASING.md) gives the procedure; no publication is automatic.

## Release gates

- [ ] SPEC §15 walkthroughs on an identified artifact/environment; outstanding task matrices closed or explicitly limited. Preserve the reported successful general pass.
- [ ] Safety: release/suppression ownership, Secure Input, permission loss, sleep/lock recovery, emergency pause; measured callback/action latency. Detailed open cases stay in owning tasks.
- [ ] Accessibility: normal-build keyboard/focus, VoiceOver, Increase Contrast, Reduce Motion/Transparency; all six languages at minimum width. Automated layouts/editor routes pass; speech/preferences/fluent proofreading remain separate.
- [ ] Search active/inactive appearance and Dock/Menu Bar/tint acceptance of the current artwork, including battery-menu keyboard/VoiceOver ([UI-024](tasks/UI-024-keyboard-navigation.md), [BRAND-001](tasks/BRAND-001-icon-runtime.md)).
- [ ] Platforms: macOS 26 execution; Intel only if claimed.
- [ ] Distribution: distinct stable-signer update preserves rules/access; encrypted signing backup off-device; final source/tag/version/artifact aligned; signed, non-notarized DMG and SHA-256 published and downloaded successfully; first actual newer-release check; six-locale website visual/download review and deployment. Keep license/notices and private security-report route usable.

Evidence: [release queue](verification/release-candidate.md), [tasks](tasks/README.md), [research](research/README.md) and [history](history/README.md). No new feature is required merely because another remapper offers it.

Current signing handoff (2026-10-20): [REL-001](tasks/REL-001-signing-workflow.md) prepares and installs build 1.0.0 (3) with the same existing Apple Development certificate as Monny. It supersedes the self-signed build-2 candidate; packaging passes, but native Accessibility/input and a subsequent same-signer update remain open. Current-key backup is separate from the old verified self-signed exports. No customer-distribution/notarization acceptance follows from this local result.
