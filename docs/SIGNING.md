# Build, release and signing backup

Run from this repository's root with full Xcode, `create-dmg` (`brew install create-dmg`) and a logged-in GUI session:

```sh
apps/rebind/scripts/dev.sh build   # debugging
apps/rebind/scripts/dev.sh test    # tests
apps/rebind/scripts/release.sh     # signed DMG for installation/testing
```

After each completed set of app fixes or improvements and its required checks, the implementing agent runs **release.sh** and reports the verified DMG path for the user to install manually. This is part of the normal handoff; no separate packaging request is needed. Documentation-only, test-only, website-only and Sketch-only changes do not require repackaging. Use **release.sh** for installed copies. It builds Release, copies the app into `apps/rebind/build/release/`, signs Sparkle's nested code and the app under Hardened Runtime, creates the branded DMG, checks signatures/image integrity, prints SHA-256 and writes the signed Sparkle `appcast.xml` beside the DMG. Missing create-dmg is an error; no alternate ZIP workflow. It never installs, publishes, creates keys or changes permissions. A missing update signing key stops packaging. Ordinary Debug builds are separate from signed installation packages.

## Release version and build

Open `apps/rebind/rebind.xcodeproj` → target **rebind** → General → Identity:

- **Version** (`MARKETING_VERSION`): currently `1.0.0`; change for a user-visible release.
- **Build** (`CURRENT_PROJECT_VERSION`): currently `14` in source; inspect the installed copy separately. Sparkle compares this number, so a published update must have a larger build than every earlier published one.

The implementing agent increments Build once for every new set of app changes, before the final verification build/handoff, even if packaging was not requested. Update Debug and Release together; do not increment again for rebuilds/retries of the same changes. Documentation-only, test-only, website-only and Sketch-only work does not require a new app build number. Preserve Version unless the task requires a release-version change.

The script reads Info.plist and automatically names `apps/rebind/build/release/Rebind-1.0.0-14.dmg` for the current source. It never increments versions or publishes. See [RELEASING](RELEASING.md).

## Signing key

Monny and Rebind use the **same existing Apple Development certificate and private key** in the login keychain. Both release scripts pin its public SHA-1 fingerprint:

`69D383553450694A1E9D78650B3FC6E69446BD4F`

Actual Apple Team ID: `GJ35NZKDRS`. The inspected certificate expires **2027-10-18**. Exact selection prevents accidentally using another certificate. A missing key or failed signature stops packaging; there is no automatic key creation, renewal, fallback or trust exception. Keep bundle identifiers unchanged. Replacing an expiring certificate is an explicit reviewed transition, not a reason to generate a new one on each build.

Apple Development is our current **local testing** route without a paid Developer ID. These DMGs are signed but not notarized; other-Mac installation and permission preservation remain unverified. Packaging a DMG does not turn a development certificate into a distribution certificate. Apple's [certificate purposes](https://developer.apple.com/help/account/certificates/certificates-overview/) distinguish these routes; [Developer ID distribution](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/) is not implemented here.

## Backup and macOS reinstall

Back up the current Apple Development identity through Keychain Access → My Certificates as an encrypted PKCS#12 file, outside the repository. It must include the private key; a public certificate or app/DMG cannot restore it. Keep the export password separately in a password manager and retain an off-device copy. Current export, restore verification and off-device copy were tester-confirmed on 2026-10-21; historical self-signed identities are no longer used.

After reinstalling macOS, install Xcode/create-dmg, restore the repository and import the backup into the login keychain. Check the exact fingerprint/expiry and private-key presence, then run release.sh. If the identity is missing/expired, stop and plan an explicit transition; a same-named replacement is a different identity. Never put signing folders, keys or passwords in Git.

## Install and update

Export your configuration from Settings → Advanced before replacing the app. Quit Rebind, drag Rebind.app from the DMG into Applications to replace the existing copy, and open that installed copy. Configuration stays in Application Support; the release script never edits it.

Build 3 changes the signer from the previous **Rebind Release** self-signature to the shared Apple Development identity. This one-time transition may require regranting Accessibility in System Settings. Check the actual grant in Rebind; if macOS retains an unusable old Accessibility entry, remove only Rebind's entry and add the installed copy again. Do not reset TCC/BTM globally or disable Gatekeeper. Rebind has no privileged Monny-style helper to install.

Subsequent same-signer updates must preserve rules/profiles and be checked for actual Accessibility access. The old self-signed build 1/2 → development-signed build 3 transition cannot prove that preservation. Confirm the installed build and short input smoke check; packaging alone is not runtime acceptance.

## Advanced use

`REBIND_SIGN_IDENTITY` selects an exact certificate name/fingerprint; `REBIND_SIGN_KEYCHAIN` selects an existing unlocked keychain. Normal releases need neither. There is only one package directory, `build/release/`; no separate signer-specific output/configuration or cross-repository script dependency. Keep the same intended identity in both repositories when deliberately updating their pinned fingerprint.

## Update signing key

Sparkle verifies every downloaded update with an **EdDSA (ed25519) key**, separate from the code-signing certificate. The private key was created once on 2026-10-21 with Sparkle's `generate_keys` and is stored in the login keychain (item account `ed25519`); the public key is `SUPublicEDKey` in `apps/rebind/Info.plist`. `release.sh` uses it through `generate_appcast`; macOS may ask once to allow keychain access.

Losing this private key means installed copies can no longer accept updates; they would have to be replaced manually. The export was signature-verified against the build-10 appcast on 2026-10-21; the tester reported an off-device copy the same day. To export a recovery copy, set `REBIND_SIGNING_BACKUP_DIR` to an existing private directory outside the repository, then run:

```sh
apps/rebind/build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys -x "${REBIND_SIGNING_BACKUP_DIR:?Set a private backup directory}/sparkle_ed25519.key"
```

The exported file is the plain private key: keep it only in private storage outside the repository (or inside an encrypted archive) and never in Git. Restore with `generate_keys -f <file>`. Never generate a new key for an app that already shipped updates.
