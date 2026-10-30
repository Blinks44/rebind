# REL-009: Release Rebind 1.3.1

- Updated: 2026-10-30
- Stage: done
- Owner: Claude Code release
- Requirements: [RELEASING](../RELEASING.md)
- Code baseline: release commit `1f2df53`, tag `v1.3.1`

## Scope

Patch release of [FIX-005](FIX-005-builtin-trackpad-after-sleep.md): built-in trackpad gestures recover after the system replaces the multitouch driver during a long sleep. No other app change.

## Verification

- Code as in FIX-005: 971 Swift Testing tests / 149 suites pass. Build 38 changes only the version (1.3.1) and build number over the tested build 37.
- Build 38 instead of 37 because the tester already runs the local 1.3.0 (37); Sparkle compares the build number, so 1.3.1 must be newer to be offered.
- Tester, 2026-10-30: local 1.3.0 (37) installed, gestures work so far; the long-sleep recurrence check stays open in FIX-005.
- `release.sh`: `apps/rebind/build/release/Rebind.dmg`, 1.3.1 (38), SHA-256 `060f9975c3c8702729ef32420beb37c130213b42f1f017335a2c708109129c0d`; app/DMG signatures, image and checksum verified. Appcast: build 38, minimum macOS 15.0, Markdown notes from CHANGELOG. The first build-38 attempt stopped at create-dmg's Finder AppleScript step (-10006); the unchanged rerun passed.

Published 2026-10-30 as the latest stable release. Public `releases/latest/download` appcast is byte-identical to the local one (build 38, minimum 15.0) and the public DMG matches the local SHA-256.

## Open checks

- [ ] Sparkle offers 1.3.1 from the installed 1.3.0 (37), shows the notes, updates and keeps rules and Accessibility access.
- Long-sleep acceptance stays in FIX-005.
