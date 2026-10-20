# Build, release and signing backup

Run from this repository's root with full Xcode, `create-dmg` (`brew install create-dmg`) and a logged-in GUI session:

```sh
apps/rebind/scripts/dev.sh build   # debugging
apps/rebind/scripts/dev.sh test    # tests
apps/rebind/scripts/release.sh     # signed DMG for installation/testing
```

Use **release.sh** for installed copies. It builds Release, copies the app into `apps/rebind/build/release/`, signs it under Hardened Runtime, creates the branded DMG, checks signatures/image integrity and prints SHA-256. Missing create-dmg is an error; no alternate ZIP workflow. It never installs, publishes, creates keys or changes permissions. Ordinary Debug builds are separate from signed installation packages.

## Release version and build

Open `apps/rebind/rebind.xcodeproj` → target **rebind** → General → Identity:

- **Version** (`MARKETING_VERSION`): currently `1.0.0`; change for a user-visible release.
- **Build** (`CURRENT_PROJECT_VERSION`): currently `7` in source; the previously installed candidate is build `3`.

The implementing agent increments Build once for every new set of app changes, before the final verification build/handoff, even if packaging was not requested. Update Debug and Release together; do not increment again for rebuilds/retries of the same changes. Documentation-only, test-only, website-only and Sketch-only work does not require a new app build number. Preserve Version unless the task requires a release-version change.

The script reads Info.plist and automatically names `apps/rebind/build/release/Rebind-1.0.0-7.dmg` for the current source. It never increments versions or publishes. The update checker compares marketing versions; see [RELEASING](RELEASING.md).

## Signing key

Monny and Rebind use the **same existing Apple Development certificate and private key** in the login keychain. Both release scripts pin its public SHA-1 fingerprint:

`69D383553450694A1E9D78650B3FC6E69446BD4F`

Actual Apple Team ID: `GJ35NZKDRS`. The inspected certificate expires **2027-10-18**. Exact selection prevents accidentally using another certificate. A missing key or failed signature stops packaging; there is no automatic key creation, renewal, fallback or trust exception. Keep bundle identifiers unchanged. Replacing an expiring certificate is an explicit reviewed transition, not a reason to generate a new one on each build.

Apple Development is our current **local testing** route without a paid Developer ID. These DMGs are signed but not notarized; other-Mac installation and permission preservation remain unverified. Packaging a DMG does not turn a development certificate into a distribution certificate. Apple's [certificate purposes](https://developer.apple.com/help/account/certificates/certificates-overview/) distinguish these routes; [Developer ID distribution](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/) is not implemented here.

## Backup and macOS reinstall

The old encrypted `Monny.p12` and `Rebind.p12` backups in `~/Documents/DeveloperSigning/` contain the **previous self-signed identities**, not this Apple Development private key. Keep them for old builds; do not delete or overwrite them.

The current Apple Development identity has been exported through Keychain Access → My Certificates to encrypted `AppleDevelopment.p12` in that folder (2026-10-20), for both apps. The file is nonempty, rejects an empty-password MAC check and is owner-readable only. Full restore/private-key signing verification remains open. Store its export password in your password manager, separately from the file, and keep an off-device copy. A public .cer or app/DMG cannot recover the private key. No signing folders, keys or passwords belong in Git.

After reinstalling macOS, install Xcode/create-dmg, restore the repositories, import `AppleDevelopment.p12` into the login keychain using its export password, check its fingerprint/expiry and run the same release.sh. The certificate must include its private key in My Certificates. If missing/expired, stop and plan the identity transition; generating a same-named replacement does not restore it.

## Install and update

Export your configuration from Settings → Advanced before replacing the app. Quit Rebind, drag Rebind.app from the DMG into Applications to replace the existing copy, and open that installed copy. Configuration stays in Application Support; the release script never edits it.

Build 3 changes the signer from the previous **Rebind Release** self-signature to the shared Apple Development identity. This one-time transition may require regranting Accessibility in System Settings. Check the actual grant in Rebind; if macOS retains an unusable old Accessibility entry, remove only Rebind's entry and add the installed copy again. Do not reset TCC/BTM globally or disable Gatekeeper. Rebind has no privileged Monny-style helper to install.

Subsequent same-signer updates must preserve rules/profiles and be checked for actual Accessibility access. The old self-signed build 1/2 → development-signed build 3 transition cannot prove that preservation. Confirm the installed build and short input smoke check; packaging alone is not runtime acceptance.

## Advanced use

`REBIND_SIGN_IDENTITY` selects an exact certificate name/fingerprint; `REBIND_SIGN_KEYCHAIN` selects an existing unlocked keychain. Normal releases need neither. There is only one package directory, `build/release/`; no separate signer-specific output/configuration or cross-repository script dependency. Keep the same intended identity in both repositories when deliberately updating their pinned fingerprint.
