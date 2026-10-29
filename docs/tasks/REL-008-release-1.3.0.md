# REL-008: Release Rebind 1.3.0

- Updated: 2026-10-29
- Stage: implementing (publication in progress)
- Owner: release chat
- Requirements: [RELEASING](../RELEASING.md)
- Code baseline: `main` after `854e8eb`; release commit and tag `v1.3.0`

## Scope

Publishes [PLAT-001](PLAT-001-macos-15-support.md) (macOS 15), [INPUT-016](INPUT-016-magic-mouse-side-taps.md) (Magic Mouse side taps), Sparkle update notes ([REL-005](REL-005-onboarding-and-updates.md)) and the setup Ready banner fix ([UI-001](UI-001-permissions-onboarding.md)). README, USAGE and the website (six locales, structured data) now say macOS 15+ and list the Magic Mouse gestures. Website deployment is done by the user.

## Verification

- Build 35 code: full suite on macOS 27.2, 998 Swift Testing passed, 2 skipped. Build 36 changes only the version (1.3.0) and build number.
- Tester, build 35 in a macOS 15.6.1 VM: no crash, UI as on 27, rules work.
- `release.sh`: `apps/rebind/build/release/Rebind.dmg`, 1.3.0 (36), SHA-256 `241b3d03adf09e90ce299a9fc79abae29c7ad55e3b15cc1706b06b95e2ae97b1`; app/DMG signatures, image and checksum verified. Appcast: build 36, minimum macOS 15.0, Markdown notes from CHANGELOG.
- Website: `pnpm check` (16 tests) and `pnpm build` pass.

## Open checks

Public asset check after publication; first Sparkle update with notes from 1.2.0 → 1.3.0 on an installed copy; hardware gates stay in PLAT-001 and INPUT-016.
