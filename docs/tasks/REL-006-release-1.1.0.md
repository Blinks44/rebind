# REL-006: Publish Rebind 1.1.0

- Updated: 2026-10-28
- Stage: implementing
- Owner: Codex release session; owns version/build, release notes, publication assets and release record sections
- Baseline: `main` at `b2d605e` plus the reviewed LIGHT-001 idle-off fix and its tests/evidence
- Authorized scope: commit and push the completed changes, increment version/build, publish the next stable GitHub release. Website deployment is separate.

## Deliverable

**1.1.0 (31), schema 48** includes the changes since published 1.0.0 (15), the build-29 copy pass and build-30 G915 idle-off fix. Notes: [1.1.0](../releases/1.1.0.md). Preserve the existing signer, bundle ID and EdDSA update key.

## Checks and next step

- Review source/privacy and diff; run final software checks after the version/build increment.
- Commit source, build/sign/verify the universal app and DMG, verify appcast version/build/download URL and EdDSA signature.
- Push reviewed main/tag, create and review a draft with DMG/checksums/appcast, publish as latest, then download public assets and match the DMG checksum/feed.
- Record the resulting tag/commit/hash and public URLs. Actual Sparkle installation/relaunch and remaining feature/platform gates stay in their owning tasks; do not execute user bindings or replace the installed app.

Next: complete final checks and signed packaging, then publish and verify the downloads.

## Candidate verification

Final 1.1.0 (31) run: **966 Swift Testing methods / 148 suites pass**, with Xcode parallel testing disabled (`Test-rebind-2026.10.28_22-44-39-+0300.xcresult`). The initial run had one 100 ms window-route timing assertion failure in WindowRegressionTests; that suite passed in isolation, then the complete suite passed without code changes. The unchanged native UI retains the build-30 29-XCTest/two-skipped pass; HIDPP retains its 32 XCTest/eight Swift Testing pass. G915 automatic idle-off and key-press wake are tester-confirmed in LIGHT-001; this release changes only version/build metadata over that tested app code. Reviewed release notes, source/privacy and `git diff --check`.
