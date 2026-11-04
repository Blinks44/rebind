# REL-010: Release Rebind 1.3.2

- Updated: 2026-11-04
- Stage: implementing
- Owner: Codex release chat
- Baseline: `main` / `7425ee5`, uncommitted UI-026 and INPUT-016 copy changes.
- Scope: [battery-menu alignment](UI-026-menu-battery-alignment.md) and [explicit side-tap labels](INPUT-016-magic-mouse-side-taps.md).

## Verification

Build 40: battery-menu tests and six-language/two-theme Magic Mouse layout checks pass. The tester accepted the result on 2026-11-04; installed version and assistive-technology coverage were not specified. Version-only release candidate: 1.3.2 (41), same implementation.

Final `dev.sh build` passes. `release.sh` passes: app/DMG strict signatures, image integrity and checksum. The first attempt failed at create-dmg’s Finder AppleScript step (-10006); unchanged retry passed.

- Artifact: `apps/rebind/build/release/Rebind.dmg`, 1.3.2 (41).
- SHA-256: `0442263d20ce04dcd27374fbe60c5afc6fab985945bf9c1852157e74b8aa8faf`.
- Appcast: build 41, macOS 15+, CHANGELOG notes, v1.3.2 download URL.

Pending: source commit/tag, gh publication and public asset verification. Existing hardware/platform/VoiceOver gates remain task-owned.

Next: package and publish v1.3.2 with Rebind.dmg, SHA256SUMS.txt and appcast.xml; verify latest downloads.
