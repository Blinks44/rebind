# REL-007: Publish Rebind 1.2.0

- Updated: 2026-10-28
- Stage: done
- Owner: Claude Code publication complete; ownership released
- Baseline: `main` at `6577b19` plus [UI-025](UI-025-devices-in-main-window.md)
- Authorized scope: commit and push the completed changes, increment version/build, publish the next stable GitHub release. Website deployment is separate.

## Deliverable

**1.2.0 (33)**: Devices moves from Settings to the main-window sidebar ([UI-025](UI-025-devices-in-main-window.md)). Notes: [1.2.0](../releases/1.2.0.md). The website source drops the old "Settings → Devices" path from its lighting note; it is not deployed. Preserve the existing signer, bundle ID and EdDSA update key.

## Verification and publication

Final 1.2.0 (33) run: **966 Swift Testing tests / 148 suites pass**; 29 XCTest methods, 2 physical-Tab skips, 0 failures. Website `pnpm check` passes. `git diff --check` clean.

Source commit `87769caaa1ee24c3d33a772a975a49e748f60265` pushed before packaging; tag `v1.2.0` resolves to it. `release.sh` signed and verified the app and DMG (pinned certificate) and wrote the appcast: 1.2.0 (33), URL `releases/download/v1.2.0/Rebind.dmg`. DMG SHA-256 **`0aea976a4ab2e52cc73652cffb48bb9dcc6aa149fb360cabdbaf8c6ff97a75da`**.

Published **2026-10-28 20:54:06 UTC** as latest stable: [Rebind 1.2.0](https://github.com/Blinks44/rebind/releases/tag/v1.2.0) (draft=false, prerelease=false). `Rebind.dmg`, `SHA256SUMS.txt` and `appcast.xml` downloaded through `releases/latest/download/` match the local artifacts byte for byte; the checksum passes.

No installation, remapping, permission change or website deployment. The website lighting-note change is committed but not deployed. Installed UI-025 checks and the Sparkle update from 1.1.0 stay with [UI-025](UI-025-devices-in-main-window.md) and [REL-005](REL-005-onboarding-and-updates.md).
