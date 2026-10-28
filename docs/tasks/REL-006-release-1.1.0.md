# REL-006: Publish Rebind 1.1.0

- Updated: 2026-10-28
- Stage: done
- Owner: Codex publication complete; ownership released
- Baseline: `main` at `b2d605e` plus the reviewed LIGHT-001 idle-off fix and its tests/evidence
- Authorized scope: commit and push the completed changes, increment version/build, publish the next stable GitHub release. Website deployment is separate.

## Deliverable

**1.1.0 (31), schema 48** includes the changes since published 1.0.0 (15), the build-29 copy pass and build-30 G915 idle-off fix. Notes: [1.1.0](../releases/1.1.0.md). Preserve the existing signer, bundle ID and EdDSA update key.

## Checks and next step

- Review source/privacy and diff; run final software checks after the version/build increment.
- Commit source, build/sign/verify the universal app and DMG, verify appcast version/build/download URL and EdDSA signature.
- Push reviewed main/tag, create and review a draft with DMG/checksums/appcast, publish as latest, then download public assets and match the DMG checksum/feed.
- Record the resulting tag/commit/hash and public URLs. Actual Sparkle installation/relaunch and remaining feature/platform gates stay in their owning tasks; do not execute user bindings or replace the installed app.

Next: verify the offered Sparkle update and installation/relaunch with rules and Accessibility preserved; REL-005 owns this remaining runtime check.

## Candidate verification

Final 1.1.0 (31) run: **966 Swift Testing methods / 148 suites pass**, with Xcode parallel testing disabled (`Test-rebind-2026.10.28_22-44-39-+0300.xcresult`). The initial run had one 100 ms window-route timing assertion failure in WindowRegressionTests; that suite passed in isolation, then the complete suite passed without code changes. The unchanged native UI retains the build-30 29-XCTest/two-skipped pass; HIDPP retains its 32 XCTest/eight Swift Testing pass. G915 automatic idle-off and key-press wake are tester-confirmed in LIGHT-001; this release changes only version/build metadata over that tested app code. Reviewed release notes, source/privacy and `git diff --check`.


## Published artifact and verification

Published **2026-10-28 19:47:44 UTC** as latest stable: [Rebind 1.1.0](https://github.com/Blinks44/rebind/releases/tag/v1.1.0), build **31**, tag `v1.1.0` → source commit `29d8fdb1fe1f00540470670939801384f6a01bb8`. Source was committed/pushed before packaging/tagging; no application source changed after final checks. Release notes and the three uploaded draft assets were reviewed before publication.

`release.sh` completed the universal Release build, pinned app/DMG signing, strict/deep app verification, strict DMG signature and image verification. Packaged version/build/bundle ID, single-item appcast URL/length and EdDSA signature were verified. DMG: `apps/rebind/build/release/Rebind.dmg`; SHA-256 **`45dc7f5dc7e6286d91ee70c4cdc0013ccf9a58692290a4f271a227dc8407acb2`**.

All three files downloaded through public `releases/latest/download/` URLs match the local artifacts byte-for-byte: `Rebind.dmg`, `SHA256SUMS.txt`, `appcast.xml`. The downloaded checksum and EdDSA signature pass; appcast advertises 1.1.0 (31) with the versioned v1.1.0 DMG URL. GitHub reports latest=true, draft=false, prerelease=false; remote tag resolves to the reviewed source commit. The permanent website download link therefore serves 1.1.0 without deployment.

No agent installation, real remapping, permission change or website deployment. Automatic Sparkle offer/download/install/relaunch, another-Mac installation, macOS 26/Intel and feature-specific remaining checks retain their existing qualifications. Build-30 automatic G915 off/wake tester acceptance is preserved; build 31 changes version/build metadata only. Public release notes disclose the signed/non-notarized route and tested platform limits.
