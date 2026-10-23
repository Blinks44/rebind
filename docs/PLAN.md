# Rebind: roadmap

Updated 2026-10-23. [STATE](STATE.md) indexes current work; [SPEC](SPEC.md) owns behavior and [CAPABILITIES](CAPABILITIES.md) owns evidence. Builds and general confirmations do not establish every hardware/platform case.

## Current release scope

The planned app functionality and English soft-design source are implemented: keyboard/mouse remapping, shared actions, profiles, per-app rules, settings, device/scrolling support and six languages. Both trackpad categories have 12 presets; Magic Mouse has six Experimental tap/click/vertical-scroll presets. The earlier overall manual pass is preserved; later October 20 testing identified five wheel/window regressions ([FIX-001](tasks/FIX-001-wheel-and-window-regressions.md)), with all bounded fixes now accepted by the tester, including improved foreground opening after the build-7 Monny comparison. Do not repeat accepted basic gesture tests as wholly unverified.

The pre-release [copy audit](tasks/REL-004-release-copy-and-documentation-audit.md) found no critical missing input feature. Three-step first run and Sparkle updates are implemented ([REL-005](tasks/REL-005-onboarding-and-updates.md)); current source/package and dated tester acceptance are in [STATE](STATE.md). Starter presets and window-position undo remain post-release research topics, not approved additions. Keep the current pool and verified engine stable; fix reproduced defects.

Outside current scope: Caps Lock, Fn/Globe and left/right modifier distinction; modifier-only triggers; ordinary primary/secondary mouse buttons as triggers (except attributed Magic Mouse three-finger click); physical-device rules, automatic profiles and touch swipes/pinch/rotation. Pointer speed/acceleration remain macOS settings; supported Logitech sensor DPI is a separate hardware feature. [INPUT-015](tasks/INPUT-015-touch-release-scope.md) owns the settled finite touch decision.

## Next

1. **Finish accessibility review:** [FIX-002](tasks/FIX-002-window-action-compatibility.md) window actions in Finder/Chrome/ChatGPT and the build-10 first run are user-confirmed. FIX-001’s wheel/window/card regressions are tester-accepted and closed. Preserve accepted keyboard/sleep/pause/permission-loss and update behavior; VoiceOver and accessibility preferences remain separately qualified. Both bounded regressions are done; do not reopen them from stale build-7/8 handoffs. The installed build-11 accessibility/copy pass is preserved in the release queue; detailed unreported controls/preferences remain qualified.
2. **Preserve update acceptance:** user confirms the update works and configuration/access remain usable; exact installed hash/build is unspecified. Keep the same Apple Development identity for further testing; no Developer ID migration is planned now. Another-Mac/current-signature installation remains unverified.
3. **Resolve support claims:** test macOS 26 on an available Mac; keep Intel unverified unless actually tested. Retain task-specific hardware/safety limits and report real-grant normal-profile CPU/latency only when measured. The old isolated paused/no-grant CPU result (~1.5%) is not active-rule performance.
4. **Publish deliberately:** (EdDSA and signing-key backups are done) review/commit source, match tag/version, rebuild/final-check the signed DMG, upload DMG + checksums + `appcast.xml` in a GitHub draft, then publish a stable release and verify download/update discovery. At the last recorded public check the repository was public with no published release; recheck during authorized publication. [WEB-001](tasks/WEB-001-landing-page.md) owns the new website foundation (verified 2026-10-22); next transfer the live Sketch design and finish six-language/real-download review. Website deployment follows the DMG. [RELEASING](RELEASING.md) gives the procedure; no publication is automatic.

## Release gates

- [ ] SPEC §15 walkthroughs on an identified artifact/environment; outstanding task matrices closed or explicitly limited. Preserve the reported successful general pass.
- [ ] Safety: release/suppression ownership, Secure Input, permission loss, sleep/lock recovery, emergency pause; measured callback/action latency. Detailed open cases stay in owning tasks.
- [ ] Accessibility: normal-build keyboard/focus, VoiceOver, Increase Contrast, Reduce Motion/Transparency; all six languages at minimum width. Automated layouts/editor routes pass; speech/preferences/fluent proofreading remain separate.
- [ ] Search active/inactive appearance and Dock/Menu Bar/tint acceptance of the current artwork, including battery-menu keyboard/VoiceOver ([UI-024](tasks/UI-024-keyboard-navigation.md), [BRAND-001](tasks/BRAND-001-icon-runtime.md)).
- [ ] Platforms: macOS 26 execution; Intel only if claimed.
- [ ] Distribution: distinct stable-signer update preserves rules/access; final source/tag/version/artifact aligned; signed, non-notarized DMG and SHA-256 published and downloaded successfully; first Sparkle update between two published builds (offer, verify, install, relaunch, rules/access kept); six-locale website visual/download review and deployment. Keep license/notices and private security-report route usable.

Evidence: [release queue](verification/release-candidate.md), [tasks](tasks/README.md), [research](research/README.md) and [history](history/README.md). No new feature is required merely because another remapper offers it.

Current signing and recovery instructions: [SIGNING](SIGNING.md). Apple Development is the current local test route; no notarized/customer-distribution acceptance follows from local packaging.
