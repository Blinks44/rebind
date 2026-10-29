# REL-005: Three-step first run and Sparkle updates

- Updated: 2026-10-29
- Stage: awaiting_verification
- Owner: Unassigned; implementation released
- Owned surfaces: `PermissionSetupView`, `UpdateSettingsRow`, `Updates/AppUpdater`, General settings, menu bar menu, `apps/rebind/Info.plist`, Sparkle package reference, `release.sh` appcast step; Sketch screens 64/01/65, 31, 51–53 and Foundations 11
- Requirements: SPEC §§6–8 (update line in §6, first-run guidance in §7); PLAN release gates (distribution)
- Code baseline: `main` `86c9e92` plus uncommitted changes listed below; version **1.0.0 (9)**

## Outcome and scope

User request 2026-10-21: design and build the missing onboarding and replace the manual update check with Sparkle "the usual way" (daily checks), without a Developer ID.

- **First run**: one sheet, three steps with "Step N of 3": Welcome (four facts and privacy), Access (the existing Accessibility/event-posting checks, retitled; skipped when access is already granted) and Ready (Open at login, Check for updates automatically, menu bar hint, Add First Binding / Done). Set Up Later on Access still closes the guidance without Ready. It is shown once until finished or deferred (`needsFirstRunSetup` no longer requires missing access, so a Mac that already granted access also sees Welcome and Ready once). Lost access later shows only the access content.
- **Updates**: Sparkle 2.10.0 (SPM, exact). Feed `releases/latest/download/appcast.xml` on GitHub, EdDSA public key in `Info.plist`, automatic checks on by default, daily interval, no system profile. Check for Updates… in the app menu and the menu bar menu; "Check for updates automatically" in Settings → General and the Ready step. Sparkle's standard windows handle found/up to date/error/download/install/relaunch; when Rebind runs without a Dock icon the update window activates the app. The old GitHub API checker, its tests and strings are removed.
- **Packaging**: `release.sh` signs Sparkle's nested code inside out with the app identity, then writes `build/release/appcast.xml` with `generate_appcast` (DMG URL `releases/download/v<version>/<dmg>`, full release notes link to the tag page). The private EdDSA key was created in the login keychain on 2026-10-21 ([SIGNING](../SIGNING.md#update-signing-key)).

Not in scope: notarization/Developer ID, delta updates, beta channels, embedded release notes, starter presets.

## Acceptance

- [x] Sketch: 64 Welcome, 01 Access, 65 Ready, General updates card, menu items and Foundations 11 contract in Light/Dark; saved and screenshot-reviewed.
- [x] Native first-run steps, update controls and menu items; six-language strings; Debug build without warnings.
- [x] First launch on a clean configuration with build 10: user reports the first-run walkthrough works (2026-10-21).
- [ ] First-run keyboard Return, VoiceOver and all six languages at minimum sheet size.
- [ ] Check for Updates… before the first release shows Sparkle's error (no appcast yet); after publishing, reports up to date.
- [ ] End-to-end update between two published Sparkle builds (offer, download, EdDSA check, install, relaunch) with rules and Accessibility preserved; also from the accessory (no Dock icon) mode.
- [x] Off-device backup of the EdDSA private key (local export verified 2026-10-21; user reports the off-device copy done the same day).

## Sketch source

Rebind.sketch saved 2026-10-21 ([DESIGN](../DESIGN.md)). Screens 64 → 01 → 65 are at the top of the Screens page; Foundations 11 owns step order, defaults, recovery and keyboard notes. Ready uses two separate cards so the native sheet reuses the exact Settings rows (`LoginItemSettingsRow`, `UpdateSettingsRow`).

## Implementation and verification

Changed: `rebind/UI/PermissionSetupView.swift`, `rebind/UI/UpdateSettingsRow.swift` (new), `rebind/Updates/AppUpdater.swift` (new; `ReleaseUpdate`, `ReleaseVersion`, `UpdateChecker` and `ReleaseUpdateTests` removed), `rebind/rebindApp.swift`, `rebind/ContentView.swift`, `rebind/UI/AppModel.swift`, `rebind/UI/GeneralSettingsView.swift`, `rebind/UI/MenuBarController.swift`, `rebind/Localizable.xcstrings` (+22 keys, −12 obsolete), `rebind/Resources/ThirdPartyNotices.txt` (Sparkle license), `apps/rebind/Info.plist` (new), project file (Sparkle package, `INFOPLIST_FILE`, build 9), `Package.resolved` (new, versioned), `scripts/release.sh`, tests in `AppModelPermissionSetupTests`. Website privacy sentence updated in six locales. Docs: SPEC, README, USAGE, DEVELOPMENT, RELEASING, SIGNING, CAPABILITIES, DEPENDENCIES, release notes, DESIGN.

Verification 2026-10-21 (Apple silicon, macOS 27.0.1, Xcode 27.1): Debug build without warnings; full `dev.sh test`: 935 tests passed (2469 cases with arguments), 2 skipped, 0 failed. `release.sh`: signed `apps/rebind/build/release/Rebind-1.0.0-9.dmg`, SHA-256 `1d39e666583e03553ba383e82927522f01bb02f1062ae0577cfd78b7b9604487`; Sparkle.framework and app signed with the pinned Apple Development identity (team GJ35NZKDRS, hardened runtime), `codesign --verify --strict --deep` passes; `appcast.xml` (build 9, minimum macOS 26.0) EdDSA signature verified with `sign_update --verify`. Not installed, no runtime walkthrough, nothing published.

Review 2026-10-21, **1.0.0 (10)**: appcast regenerated from scratch per release (the previous step appended earlier local builds), packaging follows `REBIND_DERIVED_DATA`, Set Up Later without Escape per Foundations 11, redundant `SUScheduledCheckInterval` removed. Full tests pass; signed `apps/rebind/build/release/Rebind-1.0.0-10.dmg`; appcast lists only build 10. See [history](../history/2026-10.md).

Update notes, 2026-10-29 (user request): `release.sh` writes the `## <version>` section of `CHANGELOG.md` as `Rebind.md` next to the DMG and passes `--embed-release-notes`, so Sparkle 2.10's `generate_appcast` embeds it as a Markdown `<description>` and the standard update window shows it. A version without a section gets no notes and a printed message. English only for now; the "Version history" link to the GitHub release stays. Packaging evidence: see STATE's build-34 entry. Tester, 2026-10-29: the 1.2.0 → 1.3.0 Sparkle update showed the notes and installed successfully; rules and Accessibility access were kept (first observed update between published builds).

## Open checks / dependency

Runtime checks above need the installed build 9 and a clean or reset configuration (Settings → Advanced → reset, after exporting a backup). The end-to-end update needs the first two GitHub releases; until then only the error/up-to-date paths can be observed.

## Next handoff

v1.0.0 (build 15) and v1.1.0 (build 31) are published. The latest-release appcast and public DMG/checksum downloads match 1.1.0 (31), including EdDSA verification ([REL-006](REL-006-release-1.1.0.md)). Next: verify the actual offered update, download, install and relaunch from an identified installed 1.0.0 artifact, with rules/profiles and actual Accessibility access preserved. Record the source build: a local build-30 → published build-31 update is distinct from published build-15 → build-31 acceptance. First-run accessibility/locale checks stay with the accessibility pass.
