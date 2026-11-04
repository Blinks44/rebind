# REL-010: Release Rebind 1.3.2

- Updated: 2026-11-04
- Stage: done
- Owner: Codex release chat
- Source: `57018b8`, tag `v1.3.2`; pushed to `origin/main`.
- Scope: [battery-menu alignment](UI-026-menu-battery-alignment.md) and [explicit side-tap labels](INPUT-016-magic-mouse-side-taps.md).

## Verification

Build 40: battery-menu tests and six-language/two-theme Magic Mouse layout checks pass. The tester accepted the result on 2026-11-04; installed version and assistive-technology coverage were not specified. Version-only release candidate: 1.3.2 (41), same implementation.

Final `dev.sh build` passes. `release.sh` passes: app/DMG strict signatures, image integrity and checksum. The first attempt failed at create-dmg’s Finder AppleScript step (-10006); unchanged retry passed.

- Artifact: `apps/rebind/build/release/Rebind.dmg`, 1.3.2 (41).
- SHA-256: `0442263d20ce04dcd27374fbe60c5afc6fab985945bf9c1852157e74b8aa8faf`.
- Appcast: build 41, macOS 15+, CHANGELOG notes, v1.3.2 download URL.

Published through `gh` as the latest stable release on 2026-11-04. Public latest DMG, checksum and appcast match the local files byte for byte; checksum, appcast build/version and Sparkle EdDSA verification pass. Existing hardware/platform/VoiceOver gates remain task-owned.

Next: check the Sparkle update from 1.3.1 with rules and Accessibility access preserved. No installation or website deployment performed.
