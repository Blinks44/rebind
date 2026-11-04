# DEV-001: Builds outside protected folders without accumulating test products

- Updated: 2026-11-04
- Stage: awaiting_verification
- Owner: current shared Monny/Rebind build-tooling session
- Ownership: dev.sh, release.sh, DEVELOPMENT and this task; released
- Baseline: main ae74586; initially clean

## Outcome and acceptance

Build tooling only; app code, version, signing identity and permissions stay unchanged. Default test and packaging runs use owned temporary directories under Library/Caches, remove their intermediate products on completion/failure/handled interruption, and preserve one small test summary plus requested final release artifacts. Explicit `REBIND_DERIVED_DATA` overrides are never automatically removed. Build/run/build-for-testing products remain available until `dev.sh clean`, which protects live cached app/build files. No broad cache sweep or scheduled cleanup service.

- [x] Real dev.sh test launches from the original Desktop checkout; both failed/full and successful/focused runs remove their default build directories. Full-suite failure is retained below.
- [x] Success/failure exit codes, cleanup and explicit-path preservation are checked with stub commands.
- [x] Real packaging succeeds and removes its owned ReleaseRuns directory.
- [x] Obsolete owned verification products are removed; existing source and packaged releases are preserved.
- [x] Documentation, state and dated evidence updated; diff/shell checks pass.

## Current checks and next action

Shell syntax passes; the embedded Rebind release Python parses. Black-box stub checks pass for successful/failed test cleanup, exit status, explicit-path preservation and refusal to clean an override. Both real release scripts succeeded and removed their ReleaseRuns directories. Success/failure/interrupt cleanup and a clean refusal while a fixture file is open pass. The live-file check was corrected to use lsof output, since absent sibling product paths can cause a nonzero exit status even with users of an existing file. Build-tool verification and cleanup are complete; no completed run directories remain. Ownership is released. User confirmation of future Desktop-dialog recurrence remains separate from build-tool checks.

## Verification

M1 Max/macOS 27.2: the full default suite completes with 997 passed, one failed and two skipped (1000 reported). The failure is `WindowRegressionTests/settingsRequestIsConsumedInTheMainWindowBeforeAndAfterAttachment()`: `requestedDestination` was still `.devices` after the test's 100 ms wait. An immediate isolated run of the four WindowRegressionTests passes all four. This suggests load-sensitive timing; no root cause or product fix is claimed. No application source changed. Full and focused runs remove their temporary products; only the latest small JSON summary remains. Temporary source copies are not needed.

A green full Rebind suite is not claimed. The remaining check is to repeat/review this navigation test under full-suite load, separately from the verified build-directory and cleanup behavior. Tests did not start capture, execute real remappings, change permissions or install an app.

Rebind 1.3.1/build 38 was repackaged for tooling verification, with unchanged application source/version and no installation/publication. SHA-256: `8fd618117aa9bbb8e01b48e2d843df54220a37cce9b0997c1bd15cd0b87c9ec6`. The generated app/DMG signatures, image integrity and appcast checks passed; ReleaseRuns is empty afterwards. The persistent default build cache is cleared.
