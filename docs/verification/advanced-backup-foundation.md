# Advanced configuration backup foundation — 2026-10-11

## Implemented scope

[UI-008](../tasks/UI-008-advanced-storage.md) adds an immutable validated ConfigurationBackup. It stages current/legacy local JSON, migrates in memory, supplies profile/rule counts and serializes a validated schema-24 backup. ConfigurationStore reuses the same codec and bounded file reader, retaining missing-file defaults and atomic writes.

The file reader rejects remote/non-regular sources and reads at most **2,000,001 bytes**, enforcing the existing **2,000,000-byte** limit before JSON decoding. Legacy bytes remain unchanged; future schema, duplicate IDs, invalid selection and enabled-rule conflicts are rejected. No new schema/dependency, real configuration change, rule activation or file-panel operation was introduced.

This is the storage foundation, not a completed Advanced screen: explicit confirmation/replacement/reset, native import/export panels, protected-original export and diagnostic UI integration still depend on the released UI-007 handoff. Existing AppModel storage locks remain in force. Native export → reset → import acceptance is open.

## Revision and checks

`main` / `b453d8d` plus preserved uncommitted General/Input/Language/design work and:

- `rebind/Persistence/ConfigurationBackup.swift`: SHA-256 `f2ae15d159add24e18f06bd27073c34a43505dc4d0856b8440793ce894aad112`.
- `rebind/Persistence/ConfigurationStore.swift`: SHA-256 `027171103c383d826030987b5c650080fbbe21af3c0d447b70d89bc6ce398784`.
- `rebindTests/Persistence/ConfigurationBackupTests.swift`: SHA-256 `f6be21e41d2e07fef359f34cca3e2674f2acf525965dd66d7e03feee9f6e6d8a`.

Apple Silicon MacBook Air, macOS **27.0.1 / 26A434**, Xcode **27.0**, Swift **6.4**, SDK **27.0**.

- `scripts/dev.sh test -resultBundlePath build/AdvancedBackupFoundation.xcresult`: **TEST SUCCEEDED**. **548 Swift Testing tests / 74 suites + 5 native XCTest tests = 553 tests, zero failures/skips**. xcresult summary reports **1,426 expanded executions**, zero runtime warnings. Nine new backup functions cover roundtrip, schemas 1–23, unsupported schemas, conflicts/identities, exact/over-size boundary, local regular-file restriction and corrupt-source preservation.
- The existing native fixtures cover full-main locale/appearance/size/grant/rule geometry, General/login state and Input/Language/editor layout. No Computer Use inspection during this run, and no AppKit negative-geometry diagnostics. Temporary warning-investigation hooks/tests were already removed.
- `scripts/dev.sh build`: **BUILD SUCCEEDED** for final Debug source. Existing AppIntents metadata/ad-hoc signing notes remain; no shipping-signing claim.
- Final Debug bundle passes `codesign --verify --deep --strict`; this verifies the local signature, not distribution signing/notarization.
- Scoped source/API/test review, new-record link checks and `git diff --check` pass. No agent commit or Sketch save.

The tests use temporary authored configurations and injected state, never user profiles or running input interception. Software checks do not establish production login/relaunch, new gesture behavior, native import/export/reset, accessibility, macOS 26 or Intel.

## Next

Refresh UI-007's saved/released design, then integrate native Advanced flows with explicit confirmation and atomic runtime/storage replacement. Preserve a corrupt/future original, current state on failure and held-input release ownership. Keep production restart/language checks user-led.
